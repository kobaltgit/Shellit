import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:core_foundation/core_foundation.dart';

import 'mcp_tool_definitions.dart';

/// Handler callback for MCP tool execution requests from AI clients.
typedef McpToolHandler = Future<Map<String, dynamic>> Function(
  String toolName,
  Map<String, dynamic> arguments,
);

/// Lightweight, native Dart implementation of the Model Context Protocol (MCP) server
/// utilizing Server-Sent Events (SSE) transport (specification 2024-11-05).
class McpServerService {
  static const int defaultPort = 4422;
  static const String protocolVersion = '2024-11-05';

  HttpServer? _httpServer;
  int _port = defaultPort;
  McpToolHandler? _toolHandler;

  final Map<String, McpToolDefinition> _registeredTools = {};
  final Map<String, HttpResponse> _connectedSseClients = {};
  final List<McpAuditLogEntry> _auditLogs = [];
  final StreamController<McpAuditLogEntry> _auditLogController =
      StreamController<McpAuditLogEntry>.broadcast();

  bool get isRunning => _httpServer != null;
  int get port => _port;
  int get activeClientsCount => _connectedSseClients.length;
  List<McpAuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);
  Stream<McpAuditLogEntry> get onAuditLog => _auditLogController.stream;

  McpServerService({int port = defaultPort}) : _port = port {
    // Register standard default tools
    for (final tool in McpStandardTools.defaultTools) {
      registerTool(tool);
    }
  }

  /// Sets the tool execution handler callback.
  void setToolHandler(McpToolHandler handler) {
    _toolHandler = handler;
  }

  /// Registers or overrides a tool definition.
  void registerTool(McpToolDefinition tool) {
    _registeredTools[tool.name] = tool;
  }

  /// Starts the MCP HTTP/SSE server on the specified port.
  Future<int> start({int? port}) async {
    await stop();
    _port = port ?? _port;

    try {
      _httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      _port = _httpServer!.port;
      AppLogger.i('McpServerService listening on http://127.0.0.1:$_port/sse',
          tag: 'McpServer');

      _httpServer!.listen(_handleRequest, onError: (Object err) {
        AppLogger.e('McpServerService HTTP error', tag: 'McpServer', error: err);
      });

      return _port;
    } catch (e, st) {
      AppLogger.e('Failed to start McpServerService on port $_port',
          tag: 'McpServer', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Stops the MCP server and closes all active client connections.
  Future<void> stop() async {
    final clients = List<HttpResponse>.from(_connectedSseClients.values);
    _connectedSseClients.clear();
    for (final response in clients) {
      try {
        await response.close();
      } catch (_) {}
    }

    if (_httpServer != null) {
      await _httpServer!.close(force: true);
      _httpServer = null;
      AppLogger.i('McpServerService stopped', tag: 'McpServer');
    }
  }


  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;

    // Apply CORS headers for local AI clients (Cursor, Web clients, etc.)
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set(
        'Access-Control-Allow-Headers', 'Content-Type, Accept, Authorization');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    final path = request.uri.path;

    if (request.method == 'GET' && (path == '/sse' || path == '/')) {
      await _handleSseConnection(request);
    } else if (request.method == 'POST' &&
        (path == '/message' || path == '/rpc')) {
      await _handlePostMessage(request);
    } else if (request.method == 'GET' && path == '/health') {
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(json.encode({
        'status': 'ok',
        'server': 'shellit-mcp',
        'version': '1.0.0',
        'activeClients': _connectedSseClients.length,
      }));
      await response.close();
    } else if (request.method == 'GET' &&
        (path == '/logs' || path == '/api/logs')) {
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(json.encode({
        'logs': _auditLogs.map((e) => e.toJson()).toList(),
      }));
      await response.close();
    } else if (request.method == 'POST' && path == '/api/logs/clear') {
      clearAuditLogs();
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(json.encode({'status': 'cleared'}));
      await response.close();
    } else {
      response.statusCode = HttpStatus.notFound;
      response.write('Not found: $path');
      await response.close();
    }
  }

  /// Handles incoming SSE stream requests from AI clients (GET /sse).
  Future<void> _handleSseConnection(HttpRequest request) async {
    final response = request.response;
    final sessionId =
        'session_${DateTime.now().millisecondsSinceEpoch}_${request.hashCode}';

    response.statusCode = HttpStatus.ok;
    response.bufferOutput = false;
    response.headers.set(
        HttpHeaders.contentTypeHeader, 'text/event-stream; charset=utf-8');
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    response.headers.set(HttpHeaders.connectionHeader, 'keep-alive');

    _connectedSseClients[sessionId] = response;

    // Send initial endpoint event informing client where to send POST messages
    final endpointData = '/message?sessionId=$sessionId';
    response.write('event: endpoint\ndata: $endpointData\n\n');
    await response.flush();

    AppLogger.i('Mcp client connected: $sessionId', tag: 'McpServer');

    // Clean up when client disconnects
    request.response.done.then((_) {
      _connectedSseClients.remove(sessionId);
      AppLogger.i('Mcp client disconnected: $sessionId', tag: 'McpServer');
    }).catchError((_) {
      _connectedSseClients.remove(sessionId);
    });
  }

  /// Handles incoming JSON-RPC 2.0 messages from AI clients (POST /message).
  Future<void> _handlePostMessage(HttpRequest request) async {
    final sessionId = request.uri.queryParameters['sessionId'];
    final sseResponse =
        sessionId != null ? _connectedSseClients[sessionId] : null;

    String body;
    try {
      body = await utf8.decoder.bind(request).join();
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Malformed UTF-8 body');
      await request.response.close();
      return;
    }

    dynamic rawJson;
    try {
      rawJson = json.decode(body);
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Invalid JSON');
      await request.response.close();
      return;
    }

    if (rawJson is! Map<String, dynamic>) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('JSON must be an object');
      await request.response.close();
      return;
    }

    final rpcRequest = rawJson;
    final id = rpcRequest['id'];
    final method = rpcRequest['method'] as String?;
    final params = rpcRequest['params'] as Map<String, dynamic>? ?? {};

    Map<String, dynamic>? rpcResponse;

    switch (method) {
      case 'initialize':
        rpcResponse = {
          'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'result': <String, dynamic>{
            'protocolVersion': protocolVersion,
            'capabilities': {
              'tools': <String, dynamic>{},
            },
            'serverInfo': {
              'name': 'shellit-mcp',
              'version': '1.0.0',
            },
          },
        };
        _recordAuditLog(
          clientName: (params['clientInfo'] is Map)
              ? (params['clientInfo']['name']?.toString() ?? 'Unknown AI')
              : 'Unknown AI',
          toolName: 'initialize',
          arguments: params,
          isSuccess: true,
          resultSnippet: 'Handshake completed',
        );
        break;

      case 'notifications/initialized':
        // Client confirmed initialization. No RPC response required.
        rpcResponse = null;
        break;

      case 'ping':
        rpcResponse = {
          'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'result': <String, dynamic>{},
        };
        break;

      case 'tools/list':
        final toolsList = _registeredTools.values.map((t) => t.toJson()).toList();
        rpcResponse = {
          'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'result': {
            'tools': toolsList,
          },
        };
        break;

      case 'tools/call':
        final toolName = params['name'] as String?;
        final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

        if (toolName == null || !_registeredTools.containsKey(toolName)) {
          rpcResponse = {
            'jsonrpc': '2.0',
            if (id != null) 'id': id,
            'error': {
              'code': -32601,
              'message': 'Tool not found: $toolName',
            },
          };
          _recordAuditLog(
            clientName: 'AI Client',
            toolName: toolName ?? 'unknown',
            arguments: arguments,
            isSuccess: false,
            errorMessage: 'Tool not found',
          );
        } else if (_toolHandler != null) {
          try {
            final toolResult = await _toolHandler!(toolName, arguments);
            final contentText = toolResult['text'] ?? json.encode(toolResult);

            rpcResponse = {
              'jsonrpc': '2.0',
              if (id != null) 'id': id,
              'result': {
                'content': [
                  {
                    'type': 'text',
                    'text': contentText.toString(),
                  }
                ],
                'isError': toolResult['isError'] == true,
              },
            };

            _recordAuditLog(
              clientName: 'AI Client',
              toolName: toolName,
              arguments: arguments,
              isSuccess: toolResult['isError'] != true,
              resultSnippet: contentText.toString().length > 100
                  ? '${contentText.toString().substring(0, 100)}...'
                  : contentText.toString(),
              errorMessage: toolResult['isError'] == true
                  ? (toolResult['error']?.toString() ?? 'Tool error')
                  : null,
            );
          } catch (e) {
            rpcResponse = {
              'jsonrpc': '2.0',
              if (id != null) 'id': id,
              'result': {
                'content': [
                  {
                    'type': 'text',
                    'text': 'Execution failed: $e',
                  }
                ],
                'isError': true,
              },
            };
            _recordAuditLog(
              clientName: 'AI Client',
              toolName: toolName,
              arguments: arguments,
              isSuccess: false,
              errorMessage: e.toString(),
            );
          }
        } else {
          rpcResponse = {
            'jsonrpc': '2.0',
            if (id != null) 'id': id,
            'result': {
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Shellit tool execution handler is not initialized yet.',
                }
              ],
              'isError': true,
            },
          };
        }
        break;

      default:
        rpcResponse = {
          'jsonrpc': '2.0',
          if (id != null) 'id': id,
          'error': {
            'code': -32601,
            'message': 'Method not found: $method',
          },
        };
    }

    // 1. Deliver response via open SSE stream if connected
    if (rpcResponse != null && sseResponse != null) {
      try {
        final eventPayload = json.encode(rpcResponse);
        sseResponse.write('event: message\ndata: $eventPayload\n\n');
        await sseResponse.flush();
      } catch (err) {
        AppLogger.w('Failed to write to SSE stream: $err', tag: 'McpServer');
      }
    }

    // 2. Also return in the HTTP response for maximum client compatibility
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    if (rpcResponse != null) {
      request.response.write(json.encode(rpcResponse));
    } else {
      request.response.write(json.encode({'status': 'accepted'}));
    }
    await request.response.close();
  }

  void _recordAuditLog({
    required String clientName,
    required String toolName,
    required Map<String, dynamic> arguments,
    required bool isSuccess,
    String? resultSnippet,
    String? errorMessage,
  }) {
    final entry = McpAuditLogEntry(
      timestamp: DateTime.now(),
      clientName: clientName,
      toolName: toolName,
      arguments: arguments,
      isSuccess: isSuccess,
      resultSnippet: resultSnippet,
      errorMessage: errorMessage,
    );

    _auditLogs.insert(0, entry);
    if (_auditLogs.length > 200) {
      _auditLogs.removeLast();
    }
    _auditLogController.add(entry);
  }

  /// Clears the audit logs.
  void clearAuditLogs() {
    _auditLogs.clear();
  }
}
