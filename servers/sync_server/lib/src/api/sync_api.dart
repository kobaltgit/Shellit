import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import '../db/sync_database.dart';
import 'ws_hub.dart';

/// Shelf HTTP & WebSocket router for Shellit Sync Server.
class SyncApi {
  final SyncDatabase _db;
  final WsHub _wsHub;
  final String? _registrationToken;

  SyncApi({
    required SyncDatabase db,
    required WsHub wsHub,
    String? registrationToken,
  })  : _db = db,
        _wsHub = wsHub,
        _registrationToken = registrationToken;

  Handler get handler {
    final router = Router();

    // 1. Health check
    router.get('/api/v1/health', (Request request) {
      return Response.ok(
        jsonEncode({
          'status': 'ok',
          'service': 'shellit-sync-server',
          'version': '0.1.0',
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    // 2. Vault Init / Registration
    router.post('/api/v1/vault/init', (Request request) async {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;

      final vaultId = body['vaultId'] as String?;
      final authHash = body['authHash'] as String?;
      final regToken = body['registrationToken'] as String?;

      if (vaultId == null || authHash == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'vaultId and authHash are required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (_db.hasVault(vaultId)) {
        // Existing vault: verify auth credentials
        if (!_db.authenticateVault(vaultId, authHash)) {
          return Response(
            401,
            body:
                jsonEncode({'error': 'Invalid credentials for existing vault'}),
            headers: {'content-type': 'application/json'},
          );
        }
      } else {
        // New vault: check registration token if server enforces it
        final token = _registrationToken;
        if (token != null && token.isNotEmpty) {
          if (regToken != token) {
            return Response.forbidden(
              jsonEncode({'error': 'Invalid or missing registration token'}),
              headers: {'content-type': 'application/json'},
            );
          }
        }
        _db.initOrVerifyVault(vaultId, authHash);
      }

      return Response.ok(
        jsonEncode({'success': true, 'vaultId': vaultId}),
        headers: {'content-type': 'application/json'},
      );
    });

    // 3. Fetch changes
    router.get('/api/v1/sync/changes', (Request request) {
      final vaultId = request.url.queryParameters['vaultId'];
      final authHash = request.url.queryParameters['authHash'];
      final sinceStr = request.url.queryParameters['since'] ?? '0';
      final since = int.tryParse(sinceStr) ?? 0;

      if (vaultId == null || authHash == null) {
        return Response.badRequest(
          body: jsonEncode(
              {'error': 'vaultId and authHash query params required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (!_db.authenticateVault(vaultId, authHash)) {
        return Response(
          401,
          body: jsonEncode({'error': 'Unauthorized vault credentials'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final currentRev = _db.getCurrentRevision(vaultId);
      final items = _db.getItemsSince(vaultId: vaultId, sinceRevision: since);

      return Response.ok(
        jsonEncode({
          'currentRevision': currentRev,
          'items': items,
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    // 4. Push batch of changes
    router.post('/api/v1/sync/push', (Request request) async {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr) as Map<String, dynamic>;

      final vaultId = body['vaultId'] as String?;
      final authHash = body['authHash'] as String?;
      final rawItems = body['items'] as List<dynamic>?;

      if (vaultId == null || authHash == null || rawItems == null) {
        return Response.badRequest(
          body: jsonEncode(
              {'error': 'vaultId, authHash, and items are required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (!_db.authenticateVault(vaultId, authHash)) {
        return Response(
          401,
          body: jsonEncode({'error': 'Unauthorized vault credentials'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final items = rawItems.cast<Map<String, dynamic>>();
      final newRev = _db.pushItems(vaultId: vaultId, items: items);

      // Broadcast WebSocket notification to all clients subscribed to this vault
      _wsHub.broadcastRevision(vaultId, newRev);

      return Response.ok(
        jsonEncode({
          'success': true,
          'newRevision': newRev,
        }),
        headers: {'content-type': 'application/json'},
      );
    });

    // 5. WebSocket realtime subscription
    final wsHandler = webSocketHandler((channel, ping) {
      // In webSocketHandler, request context isn't passed directly into callback in shelf_web_socket v3,
      // but channel can receive an initial registration message: {"action": "subscribe", "vaultId": "...", "authHash": "..."}
      channel.stream.listen((rawMessage) {
        try {
          final data = jsonDecode(rawMessage as String) as Map<String, dynamic>;
          if (data['action'] == 'subscribe') {
            final vId = data['vaultId'] as String?;
            final aHash = data['authHash'] as String?;
            if (vId != null &&
                aHash != null &&
                _db.authenticateVault(vId, aHash)) {
              _wsHub.addChannel(vId, channel);
              channel.sink
                  .add(jsonEncode({'status': 'subscribed', 'vaultId': vId}));
            } else {
              channel.sink.add(jsonEncode({'error': 'Unauthorized'}));
            }
          }
        } catch (_) {}
      });
    });

    router.get('/api/v1/sync/ws', wsHandler);

    return router;
  }
}
