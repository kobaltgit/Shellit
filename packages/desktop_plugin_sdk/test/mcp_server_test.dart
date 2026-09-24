import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('McpServerService', () {
    late McpServerService server;
    late int testPort;

    setUp(() async {
      server =
          McpServerService(port: 0); // Port 0 binds to an available random port
      testPort = await server.start();
    });

    tearDown(() async {
      await server.stop();
    });

    test('starts and reports isRunning on bound port', () {
      expect(server.isRunning, isTrue);
      expect(server.port, equals(testPort));
      expect(server.port, isPositive);
    });

    test('handles /health endpoint', () async {
      final client = HttpClient();
      final req =
          await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/health'));
      final res = await req.close();
      expect(res.statusCode, equals(200));

      final body = await utf8.decoder.bind(res).join();
      final jsonMap = json.decode(body) as Map<String, dynamic>;
      expect(jsonMap['status'], equals('ok'));
      expect(jsonMap['server'], equals('shellit-mcp'));
      client.close();
    });

    test('SSE connection establishes session handshake', () async {
      final client = HttpClient();
      final req =
          await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/sse'));
      final res = await req.close();
      expect(res.statusCode, equals(200));
      expect(res.headers.value('content-type'), contains('text/event-stream'));

      final completer = Completer<String>();
      final sub = res.transform(utf8.decoder).listen((data) {
        if (data.contains('event: endpoint') && !completer.isCompleted) {
          completer.complete(data);
        }
      });

      final firstEvent =
          await completer.future.timeout(const Duration(seconds: 3));
      expect(firstEvent, contains('/message?sessionId=session_'));
      expect(server.activeClientsCount, equals(1));

      await sub.cancel();
      client.close(force: true);
    });

    test('handles initialize and tools/list via JSON-RPC POST', () async {
      final client = HttpClient();

      // 1. Send initialize
      final initReq =
          await client.postUrl(Uri.parse('http://127.0.0.1:$testPort/message'));
      initReq.headers.contentType = ContentType.json;
      initReq.write(json.encode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'clientInfo': {'name': 'test-ai-client', 'version': '1.0'},
        },
      }));
      final initRes = await initReq.close();
      expect(initRes.statusCode, equals(200));
      final initBody = await utf8.decoder.bind(initRes).join();
      final initJson = json.decode(initBody) as Map<String, dynamic>;
      expect(initJson['result']['protocolVersion'], equals('2024-11-05'));
      expect(initJson['result']['serverInfo']['name'], equals('shellit-mcp'));

      // 2. Send tools/list
      final listReq =
          await client.postUrl(Uri.parse('http://127.0.0.1:$testPort/message'));
      listReq.headers.contentType = ContentType.json;
      listReq.write(json.encode({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list',
      }));
      final listRes = await listReq.close();
      final listBody = await utf8.decoder.bind(listRes).join();
      final listJson = json.decode(listBody) as Map<String, dynamic>;
      final tools = listJson['result']['tools'] as List<dynamic>;

      expect(tools.any((t) => t['name'] == 'shellit_list_servers'), isTrue);
      expect(tools.any((t) => t['name'] == 'shellit_exec_command'), isTrue);

      client.close();
    });

    test('executes tool handler via tools/call and records audit log',
        () async {
      server.setToolHandler((toolName, args) async {
        if (toolName == 'shellit_list_servers') {
          return {
            'text': json.encode([
              {
                'id': 'host-1',
                'label': 'Production Web 01',
                'hostname': 'prod01.example.com',
              }
            ]),
          };
        }
        return {'text': 'OK'};
      });

      final client = HttpClient();
      final callReq =
          await client.postUrl(Uri.parse('http://127.0.0.1:$testPort/message'));
      callReq.headers.contentType = ContentType.json;
      callReq.write(json.encode({
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'tools/call',
        'params': {
          'name': 'shellit_list_servers',
          'arguments': <String, dynamic>{},
        },
      }));
      final callRes = await callReq.close();
      final callBody = await utf8.decoder.bind(callRes).join();
      final callJson = json.decode(callBody) as Map<String, dynamic>;

      expect(callJson['result']['isError'], isFalse);
      final content = callJson['result']['content'] as List<dynamic>;
      expect(content.first['text'], contains('Production Web 01'));

      // Verify audit log entry
      expect(server.auditLogs.isNotEmpty, isTrue);
      final log = server.auditLogs.first;
      expect(log.toolName, equals('shellit_list_servers'));
      expect(log.isSuccess, isTrue);

      client.close();
    });

    test('serves audit logs at /logs and clears them at /api/logs/clear',
        () async {
      final client = HttpClient();

      // 1. Fetch /logs
      final getReq =
          await client.getUrl(Uri.parse('http://127.0.0.1:$testPort/logs'));
      final getRes = await getReq.close();
      expect(getRes.statusCode, equals(HttpStatus.ok));
      final getBody = await utf8.decoder.bind(getRes).join();
      final getJson = json.decode(getBody) as Map<String, dynamic>;
      expect(getJson.containsKey('logs'), isTrue);

      // 2. Clear via /api/logs/clear
      final postReq = await client
          .postUrl(Uri.parse('http://127.0.0.1:$testPort/api/logs/clear'));
      final postRes = await postReq.close();
      expect(postRes.statusCode, equals(HttpStatus.ok));

      // 3. Verify cleared
      expect(server.auditLogs.isEmpty, isTrue);

      client.close();
    });
  });
}
