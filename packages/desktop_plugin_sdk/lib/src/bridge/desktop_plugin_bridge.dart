import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import '../manifest/plugin_permissions.dart';
import 'json_rpc_message.dart';

/// Method handler callback signature for JSON-RPC calls from plugins.
typedef PluginMethodHandler = Future<dynamic> Function(
    String pluginId, dynamic params);

/// Desktop implementation of [IPluginBridge] managing two-way JSON-RPC 2.0 communication
/// and permission enforcement between Shellit and JS plugin sandboxes.
class DesktopPluginBridge implements IPluginBridge {
  final Map<String, PluginManifest> _registeredManifests = {};
  final Map<String, _RegisteredMethod> _methodHandlers = {};
  final Map<String, StreamController<Map<String, dynamic>>>
      _incomingControllers = {};
  final Map<String, StreamController<Map<String, dynamic>>>
      _outgoingControllers = {};
  final Map<dynamic, Completer<dynamic>> _pendingRequests = {};
  int _nextRequestId = 1;

  DesktopPluginBridge() {
    _registerDefaultMethodPermissions();
  }

  void _registerDefaultMethodPermissions() {
    // Built-in method default permissions mapping
    _defaultRequiredPermissions['terminal.runCommand'] =
        PluginPermissions.terminalExecute;
    _defaultRequiredPermissions['terminal.execute'] =
        PluginPermissions.terminalExecute;
    _defaultRequiredPermissions['notifications.show'] =
        PluginPermissions.notificationsShow;
    _defaultRequiredPermissions['vault.readHosts'] =
        PluginPermissions.vaultReadHosts;
    _defaultRequiredPermissions['storage.get'] = PluginPermissions.storageLocal;
    _defaultRequiredPermissions['storage.set'] = PluginPermissions.storageLocal;
    _defaultRequiredPermissions['clipboard.read'] =
        PluginPermissions.clipboardRead;
    _defaultRequiredPermissions['clipboard.write'] =
        PluginPermissions.clipboardWrite;
  }

  final Map<String, String> _defaultRequiredPermissions = {};

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
  void registerHandler(
    String method,
    PluginMethodHandler handler, {
    String? requiredPermission,
  }) {
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

    return manifest.permissions.contains(requiredPerm);
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
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(
            rawMessage['id'],
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
      if (rawMessage.containsKey('id') && rawMessage['id'] != null) {
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(
            rawMessage['id'],
            JsonRpcError.invalidRequest(e.toString()),
          ).toJson(),
        );
      }
      return;
    }

    final method = request.method;
    final registered = _methodHandlers[method];

    // Method not found
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

    // 3. Permission Validation Check
    final requiredPermission = registered.requiredPermission;
    if (requiredPermission != null) {
      final manifest = _registeredManifests[pluginId];
      final isAllowed =
          manifest != null && manifest.permissions.contains(requiredPermission);

      if (!isAllowed) {
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

    // 4. Execution
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
        postMessageToPlugin(
          pluginId,
          JsonRpcResponse.error(request.id, JsonRpcError.internal(e.toString()))
              .toJson(),
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
  }
}

class _RegisteredMethod {
  final PluginMethodHandler handler;
  final String? requiredPermission;

  _RegisteredMethod({required this.handler, this.requiredPermission});
}
