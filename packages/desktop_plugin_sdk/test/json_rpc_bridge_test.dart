import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('DesktopPluginBridge - JSON-RPC & Permission Enforcement', () {
    late DesktopPluginBridge bridge;

    const authorizedPluginId = 'com.shellit.docker-monitor';
    const unauthorizedPluginId = 'com.shellit.unauthorized-plugin';

    setUp(() {
      bridge = DesktopPluginBridge();

      // Register authorized plugin (has terminal:execute and notifications:show)
      bridge.registerPlugin(
        const PluginManifest(
          id: authorizedPluginId,
          name: 'Docker Monitor',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: ['terminal:execute', 'notifications:show'],
        ),
      );

      // Register unauthorized plugin (no permissions)
      bridge.registerPlugin(
        const PluginManifest(
          id: unauthorizedPluginId,
          name: 'Restricted Plugin',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: [],
        ),
      );

      // Register test methods
      bridge.registerHandler(
        'terminal.runCommand',
        (pluginId, params) async {
          final cmd =
              (params as Map<String, dynamic>?)?['command'] as String? ?? '';
          return {'output': 'Executed: $cmd'};
        },
        requiredPermission: PluginPermissions.terminalExecute,
      );

      bridge.registerHandler(
        'notifications.show',
        (pluginId, params) async {
          return {'delivered': true};
        },
        requiredPermission: PluginPermissions.notificationsShow,
      );

      bridge.registerHandler(
        'app.getVersion',
        (pluginId, params) async {
          return {'version': '1.0.0'};
        },
        // No permission required
      );
    });

    tearDown(() {
      bridge.dispose();
    });

    test('executes method successfully when plugin has required permission',
        () async {
      final outgoingFuture =
          bridge.outgoingMessagesStream(authorizedPluginId).first;

      await bridge.handleIncomingMessage(
        authorizedPluginId,
        {
          'jsonrpc': '2.0',
          'id': 'req-1',
          'method': 'terminal.runCommand',
          'params': {'command': 'docker ps'},
        },
      );

      final response = await outgoingFuture;
      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 'req-1');
      expect(response['result'], {'output': 'Executed: docker ps'});
      expect(response.containsKey('error'), isFalse);
    });

    test('rejects RPC call with -32003 when plugin lacks required permission',
        () async {
      final outgoingFuture =
          bridge.outgoingMessagesStream(unauthorizedPluginId).first;

      await bridge.handleIncomingMessage(
        unauthorizedPluginId,
        {
          'jsonrpc': '2.0',
          'id': 'req-2',
          'method': 'terminal.runCommand',
          'params': {'command': 'rm -rf /'},
        },
      );

      final response = await outgoingFuture;
      expect(response['jsonrpc'], '2.0');
      expect(response['id'], 'req-2');
      expect(response.containsKey('result'), isFalse);
      expect(response['error'], isNotNull);

      final error = response['error'] as Map<String, dynamic>;
      expect(error['code'], JsonRpcErrorCodes.permissionDenied);
      expect(
          error['message'], contains("Missing permission 'terminal:execute'"));
    });

    test('rejects unknown plugin when calling protected method', () async {
      const unknownId = 'com.unknown.rogue';
      final outgoingFuture = bridge.outgoingMessagesStream(unknownId).first;

      await bridge.handleIncomingMessage(
        unknownId,
        {
          'jsonrpc': '2.0',
          'id': 'req-3',
          'method': 'terminal.runCommand',
          'params': {'command': 'whoami'},
        },
      );

      final response = await outgoingFuture;
      final error = response['error'] as Map<String, dynamic>;
      expect(error['code'], JsonRpcErrorCodes.permissionDenied);
    });

    test('allows unrestricted method without permissions', () async {
      final outgoingFuture =
          bridge.outgoingMessagesStream(unauthorizedPluginId).first;

      await bridge.handleIncomingMessage(
        unauthorizedPluginId,
        {
          'jsonrpc': '2.0',
          'id': 'req-4',
          'method': 'app.getVersion',
        },
      );

      final response = await outgoingFuture;
      expect(response['result'], {'version': '1.0.0'});
    });

    test('returns -32601 Method Not Found for unregistered method', () async {
      final outgoingFuture =
          bridge.outgoingMessagesStream(authorizedPluginId).first;

      await bridge.handleIncomingMessage(
        authorizedPluginId,
        {
          'jsonrpc': '2.0',
          'id': 'req-5',
          'method': 'nonExistentMethod',
        },
      );

      final response = await outgoingFuture;
      final error = response['error'] as Map<String, dynamic>;
      expect(error['code'], JsonRpcErrorCodes.methodNotFound);
    });

    test('returns -32600 Invalid Request for wrong jsonrpc version', () async {
      final outgoingFuture =
          bridge.outgoingMessagesStream(authorizedPluginId).first;

      await bridge.handleIncomingMessage(
        authorizedPluginId,
        {
          'jsonrpc': '1.0',
          'id': 'req-6',
          'method': 'app.getVersion',
        },
      );

      final response = await outgoingFuture;
      final error = response['error'] as Map<String, dynamic>;
      expect(error['code'], JsonRpcErrorCodes.invalidRequest);
    });

    test('Shellit can send request to plugin and receive response', () async {
      // Listen for outgoing request on the plugin's side
      bridge.outgoingMessagesStream(authorizedPluginId).listen((msg) {
        if (msg.containsKey('method') &&
            msg['method'] == 'plugin.onStateUpdate') {
          // Simulate plugin replying
          bridge.handleIncomingMessage(
            authorizedPluginId,
            {
              'jsonrpc': '2.0',
              'id': msg['id'],
              'result': {'acknowledged': true},
            },
          );
        }
      });

      final result = await bridge.sendRequest(
        authorizedPluginId,
        'plugin.onStateUpdate',
        {'state': 'active'},
      );

      expect(result, {'acknowledged': true});
    });

    test('Shellit can send one-way notification to plugin', () async {
      final outgoingFuture =
          bridge.outgoingMessagesStream(authorizedPluginId).first;

      bridge.sendNotification(
        authorizedPluginId,
        'terminal.onData',
        {'data': 'user input'},
      );

      final msg = await outgoingFuture;
      expect(msg['jsonrpc'], '2.0');
      expect(msg['method'], 'terminal.onData');
      expect(msg['params'], {'data': 'user input'});
      expect(msg.containsKey('id'), isFalse);
    });
  });

  group('DesktopPluginBridge - Terminal Command Execution Events', () {
    late DesktopPluginBridge bridge;

    setUp(() {
      bridge = DesktopPluginBridge();
      bridge.registerPlugin(
        const PluginManifest(
          id: 'com.test.terminal-plugin',
          name: 'Terminal Plugin',
          version: '1.0.0',
          author: 'Test',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: ['terminal:execute'],
        ),
      );
      bridge.registerPlugin(
        const PluginManifest(
          id: 'com.test.unauthorized-plugin',
          name: 'Unauthorized',
          version: '1.0.0',
          author: 'Test',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: [],
        ),
      );
      bridge.registerHandler(
        'terminal.runCommand',
        (pluginId, params) async => {'done': true},
        requiredPermission: PluginPermissions.terminalExecute,
      );
    });

    tearDown(() => bridge.dispose());

    test('broadcasts PluginCommandEvent on authorized terminal command',
        () async {
      final eventFuture = bridge.onCommandExecution.first;

      await bridge.handleIncomingMessage(
        'com.test.terminal-plugin',
        {
          'jsonrpc': '2.0',
          'id': 'cmd-1',
          'method': 'terminal.runCommand',
          'params': {'command': 'uptime'},
        },
      );

      final event = await eventFuture;
      expect(event.pluginId, 'com.test.terminal-plugin');
      expect(event.method, 'terminal.runCommand');
      expect(event.command, 'uptime');
      expect(event.params, {'command': 'uptime'});
      expect(event.timestamp, isNotNull);
    });

    test('does not broadcast PluginCommandEvent when permission denied',
        () async {
      var eventEmitted = false;
      final sub = bridge.onCommandExecution.listen((_) => eventEmitted = true);

      await bridge.handleIncomingMessage(
        'com.test.unauthorized-plugin',
        {
          'jsonrpc': '2.0',
          'id': 'cmd-2',
          'method': 'terminal.runCommand',
          'params': {'command': 'reboot'},
        },
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(eventEmitted, isFalse);
      await sub.cancel();
    });

    test('notifyCommandExecution manually broadcasts to onCommandExecution',
        () async {
      final eventFuture = bridge.onCommandExecution.first;

      final customEvent = PluginCommandEvent(
        pluginId: 'manual.plugin',
        method: 'terminal.execute',
        params: {'command': 'top'},
      );
      bridge.notifyCommandExecution(customEvent);

      final received = await eventFuture;
      expect(received.pluginId, 'manual.plugin');
      expect(received.method, 'terminal.execute');
      expect(received.command, 'top');
    });
  });

  group('DesktopPluginBridge - Isolated Local Storage Namespaces', () {
    late DesktopPluginBridge bridge;
    const pluginA = 'com.shellit.pluginA';
    const pluginB = 'com.shellit.pluginB';
    const unauthPlugin = 'com.shellit.unauth';

    setUp(() {
      bridge = DesktopPluginBridge();
      bridge.registerPlugin(
        const PluginManifest(
          id: pluginA,
          name: 'Plugin A',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: ['storage:local'],
        ),
      );
      bridge.registerPlugin(
        const PluginManifest(
          id: pluginB,
          name: 'Plugin B',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: ['storage:local'],
        ),
      );
      bridge.registerPlugin(
        const PluginManifest(
          id: unauthPlugin,
          name: 'Unauth Plugin',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: [],
        ),
      );
    });

    tearDown(() => bridge.dispose());

    test('enforces strict storage namespace isolation between plugins',
        () async {
      // 1. Plugin A sets key 'theme' -> 'dark'
      final outA1 = bridge.outgoingMessagesStream(pluginA).first;
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-1',
        'method': 'storage.set',
        'params': {'key': 'theme', 'value': 'dark'},
      });
      final resA1 = await outA1;
      expect(resA1['result']['success'], isTrue);

      // 2. Plugin B sets same key 'theme' -> 'solarized'
      final outB1 = bridge.outgoingMessagesStream(pluginB).first;
      await bridge.handleIncomingMessage(pluginB, {
        'jsonrpc': '2.0',
        'id': 'b-1',
        'method': 'storage.set',
        'params': {'key': 'theme', 'value': 'solarized'},
      });
      final resB1 = await outB1;
      expect(resB1['result']['success'], isTrue);

      // 3. Plugin A gets 'theme' -> must be 'dark'
      final outA2 = bridge.outgoingMessagesStream(pluginA).first;
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-2',
        'method': 'storage.get',
        'params': {'key': 'theme'},
      });
      final resA2 = await outA2;
      expect(resA2['result']['value'], 'dark');

      // 4. Plugin B gets 'theme' -> must be 'solarized'
      final outB2 = bridge.outgoingMessagesStream(pluginB).first;
      await bridge.handleIncomingMessage(pluginB, {
        'jsonrpc': '2.0',
        'id': 'b-2',
        'method': 'storage.get',
        'params': {'key': 'theme'},
      });
      final resB2 = await outB2;
      expect(resB2['result']['value'], 'solarized');

      // 5. Host level inspection verifies isolation
      expect(bridge.getPluginStorage(pluginA), {'theme': 'dark'});
      expect(bridge.getPluginStorage(pluginB), {'theme': 'solarized'});
    });

    test('prevents namespace spoofing via params', () async {
      // Plugin B sets secret
      await bridge.handleIncomingMessage(pluginB, {
        'jsonrpc': '2.0',
        'id': 'b-set',
        'method': 'storage.set',
        'params': {'key': 'secret', 'value': 'b_secret_value'},
      });

      // Plugin A attempts to spoof pluginId in params
      final outA = bridge.outgoingMessagesStream(pluginA).first;
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-hack',
        'method': 'storage.get',
        'params': {'key': 'secret', 'pluginId': pluginB},
      });
      final resA = await outA;
      // Plugin A gets null, cannot read Plugin B's data
      expect(resA['result']['value'], isNull);
    });

    test('denies storage operations when storage:local permission is missing',
        () async {
      final out = bridge.outgoingMessagesStream(unauthPlugin).first;
      await bridge.handleIncomingMessage(unauthPlugin, {
        'jsonrpc': '2.0',
        'id': 'unauth-1',
        'method': 'storage.set',
        'params': {'key': 'foo', 'value': 'bar'},
      });
      final res = await out;
      expect(res['error']['code'], JsonRpcErrorCodes.permissionDenied);
      expect(res['error']['message'],
          contains("Missing permission 'storage:local'"));
    });

    test(
        'supports storage.delete and storage.clear without cross-contamination',
        () async {
      // Setup data for both plugins
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-init1',
        'method': 'storage.set',
        'params': {'key': 'k1', 'value': 'v1'},
      });
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-init2',
        'method': 'storage.set',
        'params': {'key': 'k2', 'value': 'v2'},
      });
      await bridge.handleIncomingMessage(pluginB, {
        'jsonrpc': '2.0',
        'id': 'b-init1',
        'method': 'storage.set',
        'params': {'key': 'k1', 'value': 'b_v1'},
      });

      // Delete k1 on Plugin A
      final outDel = bridge.outgoingMessagesStream(pluginA).first;
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-del',
        'method': 'storage.delete',
        'params': {'key': 'k1'},
      });
      final resDel = await outDel;
      expect(resDel['result']['deleted'], isTrue);

      // Plugin A has only k2; Plugin B still has k1
      expect(bridge.getPluginStorage(pluginA), {'k2': 'v2'});
      expect(bridge.getPluginStorage(pluginB), {'k1': 'b_v1'});

      // Clear Plugin A
      final outClr = bridge.outgoingMessagesStream(pluginA).first;
      await bridge.handleIncomingMessage(pluginA, {
        'jsonrpc': '2.0',
        'id': 'a-clr',
        'method': 'storage.clear',
      });
      final resClr = await outClr;
      expect(resClr['result']['success'], isTrue);

      expect(bridge.getPluginStorage(pluginA), isEmpty);
      expect(bridge.getPluginStorage(pluginB), {'k1': 'b_v1'});
    });
  });

  group('DesktopPluginBridge - JSON-RPC Protocol & Schema Validation', () {
    late DesktopPluginBridge bridge;
    const testPluginId = 'com.shellit.schema-tester';

    setUp(() {
      bridge = DesktopPluginBridge();
      bridge.registerPlugin(
        const PluginManifest(
          id: testPluginId,
          name: 'Schema Tester',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: [
            'terminal:execute',
            'terminal:write',
            'terminal:read',
            'storage:local',
            'vault:read_hosts',
            'hosts:read',
          ],
        ),
      );
    });

    tearDown(() => bridge.dispose());

    test(
        'rejects request with invalid id type (e.g. Map) with -32600 and id null',
        () async {
      final outFuture = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': {'invalid': 'id_type'},
        'method': 'storage.get',
      });

      final res = await outFuture;
      expect(res['jsonrpc'], '2.0');
      expect(res['id'], isNull);
      expect(res['error'], isNotNull);
      expect(res['error']['code'], JsonRpcErrorCodes.invalidRequest);
      expect(res['error']['message'],
          contains("'id' must be a String, Number, or null"));
    });

    test('rejects request with missing or empty method string with -32600',
        () async {
      final out1 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'empty-method',
        'method': '   ',
      });
      final res1 = await out1;
      expect(res1['error']['code'], JsonRpcErrorCodes.invalidRequest);

      final out2 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'null-method',
        'params': <String, dynamic>{},
      });
      final res2 = await out2;
      expect(res2['error']['code'], JsonRpcErrorCodes.invalidRequest);
    });

    test('rejects request with primitive params (non-structured) with -32600',
        () async {
      final outFuture = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'primitive-params',
        'method': 'storage.get',
        'params': 'string_is_not_allowed_as_raw_params',
      });
      final res = await outFuture;
      expect(res['error']['code'], JsonRpcErrorCodes.invalidRequest);
      expect(res['error']['message'],
          contains("must be a structured Map or List"));
    });
  });

  group('DesktopPluginBridge - Method Whitelist Enforcement', () {
    late DesktopPluginBridge bridge;
    const testPluginId = 'com.shellit.whitelist-tester';

    setUp(() {
      bridge = DesktopPluginBridge();
      bridge.registerPlugin(
        const PluginManifest(
          id: testPluginId,
          name: 'Whitelist Tester',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: ['terminal:execute', 'storage:local'],
        ),
      );
    });

    tearDown(() => bridge.dispose());

    test('rejects non-whitelisted dangerous or arbitrary methods with -32601',
        () async {
      const forbiddenMethods = [
        'system.exec',
        'fs.writeFile',
        'process.spawn',
        'eval',
        'shell.openExternal',
        'window.danger',
      ];

      for (final badMethod in forbiddenMethods) {
        final outFuture = bridge.outgoingMessagesStream(testPluginId).first;
        await bridge.handleIncomingMessage(testPluginId, {
          'jsonrpc': '2.0',
          'id': 'bad-$badMethod',
          'method': badMethod,
          'params': {'cmd': 'whoami'},
        });

        final res = await outFuture;
        expect(res['error']['code'], JsonRpcErrorCodes.methodNotFound,
            reason: 'Method $badMethod should be rejected as methodNotFound');
      }
    });

    test('allows dynamically whitelisted methods via allowMethod', () async {
      bridge.allowMethod('custom.safeOperation');
      bridge.registerHandler('custom.safeOperation', (pluginId, params) async {
        return {'status': 'allowed'};
      });

      final outFuture = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'allow-1',
        'method': 'custom.safeOperation',
      });

      final res = await outFuture;
      expect(res['result'], {'status': 'allowed'});

      // Disallow and verify it is rejected
      bridge.disallowMethod('custom.safeOperation');
      final outFuture2 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'allow-2',
        'method': 'custom.safeOperation',
      });

      final res2 = await outFuture2;
      expect(res2['error']['code'], JsonRpcErrorCodes.methodNotFound);
    });
  });

  group('DesktopPluginBridge - Argument Type & Injection Validation', () {
    late DesktopPluginBridge bridge;
    const testPluginId = 'com.shellit.args-tester';

    setUp(() {
      bridge = DesktopPluginBridge();
      bridge.registerPlugin(
        const PluginManifest(
          id: testPluginId,
          name: 'Args Tester',
          version: '1.0.0',
          author: 'Dev',
          description: '',
          entryPoint: 'index.html',
          target: PluginTarget.sidebar,
          permissions: [
            'terminal:execute',
            'terminal:write',
            'terminal:read',
            'storage:local',
            'vault:read_hosts',
            'hosts:read',
          ],
        ),
      );
    });

    tearDown(() => bridge.dispose());

    test('terminal.write validates params and rejects non-string text',
        () async {
      // 1. Non-map params
      final out1 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'tw-1',
        'method': 'terminal.write',
        'params': ['not a map'],
      });
      final res1 = await out1;
      expect(res1['error']['code'], JsonRpcErrorCodes.invalidParams);

      // 2. Missing text
      final out2 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'tw-2',
        'method': 'terminal.write',
        'params': <String, dynamic>{},
      });
      final res2 = await out2;
      expect(res2['error']['code'], JsonRpcErrorCodes.invalidParams);

      // 3. Non-string text (integer)
      final out3 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'tw-3',
        'method': 'terminal.write',
        'params': {'text': 12345},
      });
      final res3 = await out3;
      expect(res3['error']['code'], JsonRpcErrorCodes.invalidParams);
      expect(res3['error']['message'],
          contains("Parameter 'text' must be a String"));

      // 4. Null byte injection in text
      final out4 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'tw-4',
        'method': 'terminal.write',
        'params': {'text': 'echo test\x00malicious'},
      });
      final res4 = await out4;
      expect(res4['error']['code'], JsonRpcErrorCodes.invalidParams);
      expect(res4['error']['message'], contains('cannot contain null bytes'));

      // 5. Valid text succeeds
      final out5 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'tw-5',
        'method': 'terminal.write',
        'params': {'text': 'ls -la\n'},
      });
      final res5 = await out5;
      expect(res5['result']['success'], isTrue);
      expect(res5['result']['bytesWritten'], 7);
    });

    test('storage operations reject path traversal (..) and invalid keys',
        () async {
      // 1. Path traversal in storage.set key
      final out1 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'st-1',
        'method': 'storage.set',
        'params': {'key': '../../etc/passwd', 'value': 'evil'},
      });
      final res1 = await out1;
      expect(res1['error']['code'], JsonRpcErrorCodes.invalidParams);
      expect(res1['error']['message'],
          contains("path traversal sequence '..' is not allowed"));

      // 2. Non-string key in storage.set
      final out2 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'st-2',
        'method': 'storage.set',
        'params': {'key': 999, 'value': 'val'},
      });
      final res2 = await out2;
      expect(res2['error']['code'], JsonRpcErrorCodes.invalidParams);
      expect(res2['error']['message'], contains('must be a String'));

      // 3. Null byte in storage.set key
      final out3 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'st-3',
        'method': 'storage.set',
        'params': {'key': 'key\x00poison', 'value': 'val'},
      });
      final res3 = await out3;
      expect(res3['error']['code'], JsonRpcErrorCodes.invalidParams);

      // 4. Path traversal in storage.get key
      final out4 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'st-4',
        'method': 'storage.get',
        'params': {'key': '..\\..\\windows\\system32'},
      });
      final res4 = await out4;
      expect(res4['error']['code'], JsonRpcErrorCodes.invalidParams);

      // 5. Path traversal in storage.delete key
      final out5 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'st-5',
        'method': 'storage.delete',
        'params': {'key': '../other_plugin/key'},
      });
      final res5 = await out5;
      expect(res5['error']['code'], JsonRpcErrorCodes.invalidParams);
    });

    test('terminal execution blocks command containing null byte injection',
        () async {
      final out = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'cmd-null',
        'method': 'terminal.runCommand',
        'params': {'command': 'cat file.txt\x00; rm -rf /'},
      });
      final res = await out;
      expect(res['error']['code'], JsonRpcErrorCodes.invalidParams);
      expect(res['error']['message'], contains('cannot contain null bytes'));
    });

    test('terminal.getBuffer validates linesCount parameter', () async {
      // Negative linesCount
      final out1 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'gb-1',
        'method': 'terminal.getBuffer',
        'params': {'linesCount': -10},
      });
      final res1 = await out1;
      expect(res1['error']['code'], JsonRpcErrorCodes.invalidParams);
      expect(res1['error']['message'], contains('positive integer'));

      // Non-integer linesCount
      final out2 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'gb-2',
        'method': 'terminal.getBuffer',
        'params': {'linesCount': 'all'},
      });
      final res2 = await out2;
      expect(res2['error']['code'], JsonRpcErrorCodes.invalidParams);

      // Valid call succeeds
      final out3 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'gb-3',
        'method': 'terminal.getBuffer',
        'params': {'linesCount': 100},
      });
      final res3 = await out3;
      expect(res3['result']['lines'], isA<List<dynamic>>());
    });

    test('server.list and vault.readHosts return host catalog when authorized',
        () async {
      final out1 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'srv-1',
        'method': 'server.list',
      });
      final res1 = await out1;
      expect(res1['result']['servers'], isA<List<dynamic>>());

      final out2 = bridge.outgoingMessagesStream(testPluginId).first;
      await bridge.handleIncomingMessage(testPluginId, {
        'jsonrpc': '2.0',
        'id': 'vault-1',
        'method': 'vault.readHosts',
      });
      final res2 = await out2;
      expect(res2['result']['hosts'], isA<List<dynamic>>());
    });
  });
}
