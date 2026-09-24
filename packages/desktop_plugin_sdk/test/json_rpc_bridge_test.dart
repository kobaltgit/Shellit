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
}
