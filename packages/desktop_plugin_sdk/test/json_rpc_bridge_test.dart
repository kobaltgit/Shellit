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
}
