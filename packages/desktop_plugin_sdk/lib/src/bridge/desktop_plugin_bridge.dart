import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import '../manifest/plugin_permissions.dart';
import 'json_rpc_message.dart';

/// Method handler callback signature for JSON-RPC calls from plugins.
typedef PluginMethodHandler = Future<dynamic> Function(
    String pluginId, dynamic params);

/// Event broadcast when a plugin invokes a terminal execution method.
class PluginCommandEvent {
  /// The ID of the plugin initiating the command execution.
  final String pluginId;

  /// The JSON-RPC method invoked (e.g. `terminal.runCommand`, `terminal.execute`).
  final String method;

  /// The parameters associated with the command invocation.
  final dynamic params;

  /// Timestamp when the execution event was emitted.
  final DateTime timestamp;

  PluginCommandEvent({
    required this.pluginId,
    required this.method,
    this.params,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convenient helper to extract the command string if present in params.
  String? get command {
    if (params is Map) {
      return (params as Map)['command'] as String?;
    }
    if (params is String) {
      return params as String;
    }
    return null;
  }

  @override
  String toString() =>
      'PluginCommandEvent(pluginId: $pluginId, method: $method, params: $params, timestamp: $timestamp)';
}

/// Desktop implementation of [IPluginBridge] managing two-way JSON-RPC 2.0 communication
/// and permission enforcement between Shellit and JS plugin sandboxes.
class DesktopPluginBridge implements IPluginBridge {
  /// Default whitelist of permitted JSON-RPC methods callable by plugins.
  static const Set<String> defaultAllowedMethods = {
    // Terminal operations
    'terminal.runCommand',
    'terminal.execute',
    'terminal.write',
    'terminal.getBuffer',
    'terminal.onData',
    // Storage operations
    'storage.get',
    'storage.set',
    'storage.delete',
    'storage.clear',
    // Server & Vault operations
    'server.list',
    'vault.readHosts',
    // Notifications & Clipboard
    'notifications.show',
    'clipboard.read',
    'clipboard.write',
    // MCP & Host operations
    'mcp.getStatus',
    'mcp.toggleServer',
    'mcp.getAuditLogs',
    'mcp.clearLogs',
    'mcp.openDetachedLogs',
    'i18n.getTranslations',
    'app.getVersion',
    'plugin.onStateUpdate',
  };

  final Set<String> _allowedMethods;
  final Map<String, PluginManifest> _registeredManifests = {};
  final Map<String, _RegisteredMethod> _methodHandlers = {};
  final Map<String, StreamController<Map<String, dynamic>>>
      _incomingControllers = {};
  final Map<String, StreamController<Map<String, dynamic>>>
      _outgoingControllers = {};
  final Map<dynamic, Completer<dynamic>> _pendingRequests = {};
  final StreamController<PluginCommandEvent> _commandExecutionController =
      StreamController<PluginCommandEvent>.broadcast();

  /// Isolated in-memory storage namespaces strictly separated per [pluginId].
  final Map<String, Map<String, dynamic>> _pluginStorage = {};

  int _nextRequestId = 1;

  /// Stream of terminal command executions initiated by plugins.
  Stream<PluginCommandEvent> get onCommandExecution =>
      _commandExecutionController.stream;

  /// Broadcasts a command execution event to [onCommandExecution] listeners.
  void notifyCommandExecution(PluginCommandEvent event) {
    if (!_commandExecutionController.isClosed) {
      _commandExecutionController.add(event);
    }
  }

  /// Returns an unmodifiable set of allowed method names.
  Set<String> get allowedMethods => Set.unmodifiable(_allowedMethods);

  /// Whitelists an additional method name for plugin invocations.
  void allowMethod(String method) {
    if (method.trim().isNotEmpty) {
      _allowedMethods.add(method.trim());
    }
  }

  /// Removes a method from the whitelist.
  void disallowMethod(String method) {
    _allowedMethods.remove(method.trim());
  }

  /// Checks if [method] is permitted by the allowed whitelist.
  bool isMethodAllowed(String method) =>
      _allowedMethods.contains(method.trim());

  /// Validates that a storage key is a non-empty String without path traversal (`..`),
  /// null bytes, or absolute path indicators.
  static bool isValidStorageKey(dynamic key) {
    if (key is! String) return false;
    final trimmed = key.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.contains('..')) return false;
    if (trimmed.contains('\x00')) return false;
    if (trimmed.startsWith('/') || trimmed.startsWith(r'\')) return false;
    if (RegExp(r'^[a-zA-Z]:').hasMatch(trimmed)) return false;
    return true;
  }

  /// Retrieves a read-only copy of the isolated local storage for [pluginId].
  Map<String, dynamic> getPluginStorage(String pluginId) =>
      Map<String, dynamic>.unmodifiable(_pluginStorage[pluginId] ?? {});

  /// Clears isolated local storage for [pluginId].
  void clearPluginStorage(String pluginId) {
    _pluginStorage.remove(pluginId);
  }

  DesktopPluginBridge({Set<String>? allowedMethods})
      : _allowedMethods = allowedMethods != null
            ? Set<String>.from(allowedMethods)
            : Set<String>.from(defaultAllowedMethods) {
    _registerDefaultMethodPermissions();
    _registerDefaultStorageHandlers();
    _registerDefaultTerminalHandlers();
    _registerDefaultServerHandlers();
  }

  void _registerDefaultMethodPermissions() {
    // Built-in method default permissions mapping
    _defaultRequiredPermissions['terminal.runCommand'] =
        PluginPermissions.terminalExecute;
    _defaultRequiredPermissions['terminal.execute'] =
        PluginPermissions.terminalExecute;
    _defaultRequiredPermissions['terminal.write'] =
        PluginPermissions.terminalExecute;
    _defaultRequiredPermissions['terminal.getBuffer'] =
        PluginPermissions.terminalExecute;
    _defaultRequiredPermissions['server.list'] =
        PluginPermissions.vaultReadHosts;
    _defaultRequiredPermissions['vault.readHosts'] =
        PluginPermissions.vaultReadHosts;
    _defaultRequiredPermissions['notifications.show'] =
        PluginPermissions.notificationsShow;
    _defaultRequiredPermissions['storage.get'] = PluginPermissions.storageLocal;
    _defaultRequiredPermissions['storage.set'] = PluginPermissions.storageLocal;
    _defaultRequiredPermissions['storage.delete'] =
        PluginPermissions.storageLocal;
    _defaultRequiredPermissions['storage.clear'] =
        PluginPermissions.storageLocal;
    _defaultRequiredPermissions['clipboard.read'] =
        PluginPermissions.clipboardRead;
    _defaultRequiredPermissions['clipboard.write'] =
        PluginPermissions.clipboardWrite;
  }

  void _registerDefaultStorageHandlers() {
    registerHandler(
      'storage.get',
      (pluginId, params) async {
        final pluginMap = _pluginStorage[pluginId] ?? {};
        if (params is Map) {
          if (params.containsKey('key')) {
            final rawKey = params['key'];
            if (rawKey is! String) {
              throw ArgumentError("Parameter 'key' must be a String");
            }
            if (!isValidStorageKey(rawKey)) {
              throw ArgumentError(
                  "Invalid storage key: path traversal sequence '..' is not allowed");
            }
            final key = rawKey.trim();
            return {'key': key, 'value': pluginMap[key]};
          }
        } else if (params != null) {
          throw ArgumentError(
              "Parameters for 'storage.get' must be a map or omitted");
        }
        return {'values': Map<String, dynamic>.from(pluginMap)};
      },
      requiredPermission: PluginPermissions.storageLocal,
    );

    registerHandler(
      'storage.set',
      (pluginId, params) async {
        if (params is! Map) {
          throw ArgumentError(
              'Parameters must be a map containing "key" and "value"');
        }
        if (!params.containsKey('key')) {
          throw ArgumentError('Parameter "key" is required');
        }
        final rawKey = params['key'];
        if (rawKey is! String) {
          throw ArgumentError('Parameter "key" must be a String');
        }
        if (!isValidStorageKey(rawKey)) {
          throw ArgumentError(
              "Invalid storage key: path traversal sequence '..' is not allowed");
        }
        if (!params.containsKey('value')) {
          throw ArgumentError('Parameter "value" is required');
        }
        final key = rawKey.trim();
        final value = params['value'];
        final pluginMap = _pluginStorage.putIfAbsent(pluginId, () => {});
        pluginMap[key] = value;
        return {'success': true, 'key': key, 'value': value};
      },
      requiredPermission: PluginPermissions.storageLocal,
    );

    registerHandler(
      'storage.delete',
      (pluginId, params) async {
        if (params is! Map) {
          throw ArgumentError('Parameters must be a map containing "key"');
        }
        if (!params.containsKey('key')) {
          throw ArgumentError('Parameter "key" is required');
        }
        final rawKey = params['key'];
        if (rawKey is! String) {
          throw ArgumentError('Parameter "key" must be a String');
        }
        if (!isValidStorageKey(rawKey)) {
          throw ArgumentError(
              "Invalid storage key: path traversal sequence '..' is not allowed");
        }
        final key = rawKey.trim();
        final pluginMap = _pluginStorage[pluginId];
        final removed = pluginMap?.remove(key);
        return {'success': true, 'key': key, 'deleted': removed != null};
      },
      requiredPermission: PluginPermissions.storageLocal,
    );

    registerHandler(
      'storage.clear',
      (pluginId, params) async {
        _pluginStorage[pluginId]?.clear();
        return {'success': true};
      },
      requiredPermission: PluginPermissions.storageLocal,
    );
  }

  void _registerDefaultTerminalHandlers() {
    registerHandler(
      'terminal.write',
      (pluginId, params) async {
        if (params is! Map) {
          throw ArgumentError(
              "Parameters for 'terminal.write' must be a map containing 'text'");
        }
        if (!params.containsKey('text')) {
          throw ArgumentError("Parameter 'text' is required");
        }
        final text = params['text'];
        if (text is! String) {
          throw ArgumentError("Parameter 'text' must be a String");
        }
        if (text.contains('\x00')) {
          throw ArgumentError(
              "Parameter 'text' cannot contain null bytes (\\0)");
        }
        return {'success': true, 'bytesWritten': text.length};
      },
      requiredPermission: PluginPermissions.terminalExecute,
    );

    registerHandler(
      'terminal.getBuffer',
      (pluginId, params) async {
        if (params != null && params is! Map) {
          throw ArgumentError(
              "Parameters for 'terminal.getBuffer' must be a map or omitted");
        }
        if (params is Map && params.containsKey('linesCount')) {
          final lines = params['linesCount'];
          if (lines is! int || lines <= 0) {
            throw ArgumentError(
                "Parameter 'linesCount' must be a positive integer");
          }
        }
        return {'lines': <String>[]};
      },
      requiredPermission: PluginPermissions.terminalExecute,
    );

    registerHandler(
      'terminal.runCommand',
      (pluginId, params) async {
        if (params is! Map) {
          throw ArgumentError('Parameters must be a map containing "command"');
        }
        if (!params.containsKey('command')) {
          throw ArgumentError('Parameter "command" is required');
        }
        final cmd = params['command'];
        if (cmd is! String) {
          throw ArgumentError('Parameter "command" must be a String');
        }
        if (cmd.contains('\x00')) {
          throw ArgumentError(
              'Parameter "command" cannot contain null bytes (\\0)');
        }
        return {'success': true, 'command': cmd};
      },
      requiredPermission: PluginPermissions.terminalExecute,
    );

    registerHandler(
      'terminal.execute',
      (pluginId, params) async {
        if (params is! Map) {
          throw ArgumentError('Parameters must be a map containing "command"');
        }
        if (!params.containsKey('command')) {
          throw ArgumentError('Parameter "command" is required');
        }
        final cmd = params['command'];
        if (cmd is! String) {
          throw ArgumentError('Parameter "command" must be a String');
        }
        if (cmd.contains('\x00')) {
          throw ArgumentError(
              'Parameter "command" cannot contain null bytes (\\0)');
        }
        return {'success': true, 'command': cmd};
      },
      requiredPermission: PluginPermissions.terminalExecute,
    );
  }

  void _registerDefaultServerHandlers() {
    registerHandler(
      'server.list',
      (pluginId, params) async {
        if (params != null && params is! Map) {
          throw ArgumentError(
              "Parameters for 'server.list' must be a map or omitted");
        }
        return {'servers': <Map<String, dynamic>>[]};
      },
      requiredPermission: PluginPermissions.vaultReadHosts,
    );

    registerHandler(
      'vault.readHosts',
      (pluginId, params) async {
        if (params != null && params is! Map) {
          throw ArgumentError(
              "Parameters for 'vault.readHosts' must be a map or omitted");
        }
        return {'hosts': <Map<String, dynamic>>[]};
      },
      requiredPermission: PluginPermissions.vaultReadHosts,
    );
  }

  final Map<String, String> _defaultRequiredPermissions = {};

  static const Map<String, List<String>> _permissionAliases = {
    PluginPermissions.terminalExecute: [
      PluginPermissions.terminalWrite,
      PluginPermissions.terminalRead,
    ],
    PluginPermissions.terminalWrite: [
      PluginPermissions.terminalExecute,
    ],
    PluginPermissions.terminalRead: [
      PluginPermissions.terminalExecute,
    ],
    PluginPermissions.vaultReadHosts: [
      PluginPermissions.hostsRead,
    ],
    PluginPermissions.hostsRead: [
      PluginPermissions.vaultReadHosts,
    ],
  };

  /// Registers a plugin's manifest so its permissions can be verified during RPC calls.
  void registerPlugin(PluginManifest manifest) {
    _registeredManifests[manifest.id] = manifest;
  }

  /// Unregisters a plugin and frees its resources.
  void unregisterPlugin(String pluginId) {
    _registeredManifests.remove(pluginId);
    _incomingControllers[pluginId]?.close();
    _incomingControllers.remove(pluginId);
    _outgoingControllers[pluginId]?.close();
    _outgoingControllers.remove(pluginId);
  }

  /// Registers a handler for a specific JSON-RPC [method].
  ///
  /// If [requiredPermission] is not specified, it checks if a standard permission
  /// is defined for [method]. If none is defined, the method is accessible without permissions.
  ///
  /// If [addToWhitelist] is true, [method] is also added to [allowedMethods] if not already present.
  void registerHandler(
    String method,
    PluginMethodHandler handler, {
    String? requiredPermission,
    bool addToWhitelist = true,
  }) {
    if (addToWhitelist) {
      _allowedMethods.add(method);
    }
    final perm = requiredPermission ?? _defaultRequiredPermissions[method];
    _methodHandlers[method] =
        _RegisteredMethod(handler: handler, requiredPermission: perm);
  }

  /// Checks if [pluginId] possesses the necessary permissions to invoke [method].
  bool hasPermission(String pluginId, String method) {
    final handler = _methodHandlers[method];
    final requiredPerm =
        handler?.requiredPermission ?? _defaultRequiredPermissions[method];
    if (requiredPerm == null) {
      return true; // No permission required
    }

    final manifest = _registeredManifests[pluginId];
    if (manifest == null) {
      return false;
    }

    if (manifest.permissions.contains(requiredPerm)) {
      return true;
    }

    final aliases = _permissionAliases[requiredPerm];
    if (aliases != null) {
      for (final alias in aliases) {
        if (manifest.permissions.contains(alias)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  void postMessageToPlugin(String pluginId, Map<String, dynamic> message) {
    final controller = _outgoingControllers.putIfAbsent(
      pluginId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    if (!controller.isClosed) {
      controller.add(message);
    }
  }

  @override
  Stream<Map<String, dynamic>> onMessageFromPlugin(String pluginId) {
    final controller = _incomingControllers.putIfAbsent(
      pluginId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    return controller.stream;
  }

  /// Stream of messages sent from Shellit to the plugin's sandbox (consumed by WebView).
  Stream<Map<String, dynamic>> outgoingMessagesStream(String pluginId) {
    final controller = _outgoingControllers.putIfAbsent(
      pluginId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    return controller.stream;
  }

  /// Entry point called by the WebView IPC layer when a message is received from JavaScript.
  Future<void> handleIncomingMessage(
      String pluginId, Map<String, dynamic> rawMessage) async {
    // Notify local incoming stream
    final inController = _incomingControllers.putIfAbsent(
      pluginId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );
    if (!inController.isClosed) {
      inController.add(rawMessage);
    }

    // Check JSON-RPC 2.0 protocol
    if (rawMessage['jsonrpc'] != '2.0') {
      if (rawMessage.containsKey('id') && rawMessage['id'] != null) {
        final rawId = rawMessage['id'];
        final validId = (rawId is String || rawId is num) ? rawId : null;
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(
            validId,
            JsonRpcError.invalidRequest("Protocol must be '2.0'"),
          ).toJson(),
        );
      }
      return;
    }

    // 1. Is this a Response to a request initiated by Shellit?
    if (rawMessage.containsKey('result') ||
        (rawMessage.containsKey('error') &&
            !rawMessage.containsKey('method'))) {
      final id = rawMessage['id'];
      final completer = _pendingRequests.remove(id);
      if (completer != null && !completer.isCompleted) {
        if (rawMessage.containsKey('error') && rawMessage['error'] != null) {
          final err = JsonRpcError.fromJson(
              rawMessage['error'] as Map<String, dynamic>);
          completer.completeError(err);
        } else {
          completer.complete(rawMessage['result']);
        }
      }
      return;
    }

    // 2. This is an incoming Request or Notification from the plugin
    JsonRpcRequest request;
    try {
      request = JsonRpcRequest.fromJson(rawMessage);
    } catch (e) {
      if (rawMessage.containsKey('id')) {
        final rawId = rawMessage['id'];
        final validId = (rawId is String || rawId is num) ? rawId : null;
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(
            validId,
            JsonRpcError.invalidRequest(e.toString()),
          ).toJson(),
        );
      }
      return;
    }

    final method = request.method;

    // 3. Method Whitelist Validation Check
    if (!_allowedMethods.contains(method)) {
      if (!request.isNotification) {
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(request.id, JsonRpcError.methodNotFound(method))
              .toJson(),
        );
      }
      return;
    }

    final registered = _methodHandlers[method];

    // Method not found in registered handlers
    if (registered == null) {
      if (!request.isNotification) {
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(request.id, JsonRpcError.methodNotFound(method))
              .toJson(),
        );
      }
      return;
    }

    // 4. Permission Validation Check
    final requiredPermission = registered.requiredPermission;
    if (requiredPermission != null) {
      if (!hasPermission(pluginId, method)) {
        if (!request.isNotification) {
          postMessageToPlugin(
            pluginId,
            JsonRpcResponse.error(
              request.id,
              JsonRpcError.permissionDenied(requiredPermission, pluginId),
            ).toJson(),
          );
        }
        return;
      }
    }

    // 5. Principle of least privilege: Command & Argument validation
    if (method == 'terminal.runCommand' || method == 'terminal.execute') {
      if (request.params is Map) {
        final p = request.params as Map;
        final cmd = p['command'];
        if (cmd != null) {
          if (cmd is! String) {
            if (!request.isNotification) {
              postMessageToPlugin(
                pluginId,
                JsonRpcResponse.error(
                  request.id,
                  JsonRpcError.invalidParams(
                      "Parameter 'command' must be a String"),
                ).toJson(),
              );
            }
            return;
          }
          if (cmd.contains('\x00')) {
            if (!request.isNotification) {
              postMessageToPlugin(
                pluginId,
                JsonRpcResponse.error(
                  request.id,
                  JsonRpcError.invalidParams(
                      "Parameter 'command' cannot contain null bytes (\\0)"),
                ).toJson(),
              );
            }
            return;
          }
        }
      }
    } else if (method == 'terminal.write') {
      if (request.params is! Map) {
        if (!request.isNotification) {
          postMessageToPlugin(
            pluginId,
            JsonRpcResponse.error(
              request.id,
              JsonRpcError.invalidParams(
                  "Parameters for 'terminal.write' must be a map containing 'text'"),
            ).toJson(),
          );
        }
        return;
      }
      final p = request.params as Map;
      final txt = p['text'];
      if (txt is! String) {
        if (!request.isNotification) {
          postMessageToPlugin(
            pluginId,
            JsonRpcResponse.error(
              request.id,
              JsonRpcError.invalidParams("Parameter 'text' must be a String"),
            ).toJson(),
          );
        }
        return;
      }
      if (txt.contains('\x00')) {
        if (!request.isNotification) {
          postMessageToPlugin(
            pluginId,
            JsonRpcResponse.error(
              request.id,
              JsonRpcError.invalidParams(
                  "Parameter 'text' cannot contain null bytes (\\0)"),
            ).toJson(),
          );
        }
        return;
      }
    }

    // Broadcast terminal command execution event if applicable
    if (requiredPermission == PluginPermissions.terminalExecute ||
        requiredPermission == PluginPermissions.terminalWrite ||
        method == 'terminal.runCommand' ||
        method == 'terminal.execute' ||
        method == 'terminal.write') {
      notifyCommandExecution(
        PluginCommandEvent(
          pluginId: pluginId,
          method: method,
          params: request.params,
        ),
      );
    }

    // 6. Execution
    try {
      final result = await registered.handler(pluginId, request.params);
      if (!request.isNotification) {
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.success(request.id, result).toJson(),
        );
      }
    } catch (e) {
      if (!request.isNotification) {
        final rpcError = (e is ArgumentError || e is FormatException)
            ? JsonRpcError.invalidParams(e.toString())
            : JsonRpcError.internal(e.toString());
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(request.id, rpcError).toJson(),
        );
      }
    }
  }

  /// Sends a request from Shellit to the plugin and awaits a response.
  Future<dynamic> sendRequest(
    String pluginId,
    String method, [
    dynamic params,
    Duration timeout = const Duration(seconds: 15),
  ]) {
    final id = 'host-req-${_nextRequestId++}';
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final request = JsonRpcRequest(
      id: id,
      method: method,
      params: params,
    );

    postMessageToPlugin(pluginId, request.toJson());

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException(
            "Request '$method' timed out for plugin '$pluginId'");
      },
    );
  }

  /// Sends a one-way notification from Shellit to the plugin.
  void sendNotification(String pluginId, String method, [dynamic params]) {
    final notification = JsonRpcRequest(
      method: method,
      params: params,
    );
    postMessageToPlugin(pluginId, notification.toJson());
  }

  /// Closes all controllers and clears state.
  void dispose() {
    _commandExecutionController.close();
    for (final c in _incomingControllers.values) {
      c.close();
    }
    for (final c in _outgoingControllers.values) {
      c.close();
    }
    _incomingControllers.clear();
    _outgoingControllers.clear();
    _pendingRequests.clear();
    _registeredManifests.clear();
    _methodHandlers.clear();
    _pluginStorage.clear();
  }
}

class _RegisteredMethod {
  final PluginMethodHandler handler;
  final String? requiredPermission;

  _RegisteredMethod({required this.handler, this.requiredPermission});
}
