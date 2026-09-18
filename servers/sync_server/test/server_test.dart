import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shellit_sync_server/sync_server.dart';
import 'package:test/test.dart';

void main() {
  group('Sync Server REST API Tests', () {
    late SyncDatabase db;
    late WsHub wsHub;
    late SyncApi api;
    late dynamic server;
    late String baseUrl;

    setUp(() async {
      db = SyncDatabase.inMemory();
      wsHub = WsHub();
      api = SyncApi(
        db: db,
        wsHub: wsHub,
        registrationToken: 'secret-invite-token',
      );

      server = await io.serve(api.handler, '127.0.0.1', 0);
      baseUrl = 'http://${server.address.host}:${server.port}';
    });

    tearDown(() async {
      await server.close(force: true);
      db.close();
    });

    test('GET /api/v1/health returns 200 OK', () async {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/health'));
      expect(res.statusCode, equals(200));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      expect(body['status'], equals('ok'));
      expect(body['service'], equals('shellit-sync-server'));
    });

    test(
        'POST /api/v1/vault/init rejects missing token and accepts valid token',
        () async {
      // 1. Without registration token -> 403 Forbidden
      final badRes = await http.post(
        Uri.parse('$baseUrl/api/v1/vault/init'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'vaultId': 'v-100',
          'authHash': 'hash-abc',
        }),
      );
      expect(badRes.statusCode, equals(403));

      // 2. With valid registration token -> 200 OK
      final goodRes = await http.post(
        Uri.parse('$baseUrl/api/v1/vault/init'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'vaultId': 'v-100',
          'authHash': 'hash-abc',
          'registrationToken': 'secret-invite-token',
        }),
      );
      expect(goodRes.statusCode, equals(200));
      final body = jsonDecode(goodRes.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
    });

    test('Sync Push & Fetch Changes Workflow', () async {
      // 1. Init vault
      await http.post(
        Uri.parse('$baseUrl/api/v1/vault/init'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'vaultId': 'v-200',
          'authHash': 'auth-200',
          'registrationToken': 'secret-invite-token',
        }),
      );

      // 2. Push 2 items
      final pushRes = await http.post(
        Uri.parse('$baseUrl/api/v1/sync/push'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'vaultId': 'v-200',
          'authHash': 'auth-200',
          'items': [
            {
              'itemId': 'host-1',
              'entityType': 'host',
              'version': 1,
              'isDeleted': false,
              'encryptedBlob': 'blob-data-1',
              'updatedAt': DateTime.now().toIso8601String(),
            },
            {
              'itemId': 'snippet-1',
              'entityType': 'snippet',
              'version': 1,
              'isDeleted': false,
              'encryptedBlob': 'blob-data-2',
              'updatedAt': DateTime.now().toIso8601String(),
            },
          ],
        }),
      );
      expect(pushRes.statusCode, equals(200));
      final pushBody = jsonDecode(pushRes.body) as Map<String, dynamic>;
      expect(pushBody['success'], isTrue);
      expect(pushBody['newRevision'], equals(1));

      // 3. Fetch changes since rev 0
      final fetchRes = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/sync/changes?vaultId=v-200&authHash=auth-200&since=0'),
      );
      expect(fetchRes.statusCode, equals(200));
      final fetchBody = jsonDecode(fetchRes.body) as Map<String, dynamic>;
      expect(fetchBody['currentRevision'], equals(1));
      final items = fetchBody['items'] as List<dynamic>;
      expect(items.length, equals(2));

      // 4. Fetch changes since rev 1 -> should be empty
      final emptyRes = await http.get(
        Uri.parse(
            '$baseUrl/api/v1/sync/changes?vaultId=v-200&authHash=auth-200&since=1'),
      );
      expect(emptyRes.statusCode, equals(200));
      final emptyBody = jsonDecode(emptyRes.body) as Map<String, dynamic>;
      expect((emptyBody['items'] as List<dynamic>).isEmpty, isTrue);
    });
  });
}
