import 'dart:convert';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'sync_models.dart';

/// HTTP Client for communication with the self-hosted Shellit Sync Server.
/// Supports both cleartext HTTP (LAN / WireGuard / Tailscale) and HTTPS (with optional self-signed bypass).
class SyncClient {
  final bool allowInsecureCertificates;

  SyncClient({this.allowInsecureCertificates = false});

  HttpClient _createHttpClient() {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    if (allowInsecureCertificates) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }

  /// Normalizes base URL (trims trailing slashes).
  String _normalizeUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Checks server availability.
  Future<Result<bool, VaultFailure>> checkHealth(String baseUrl) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('${_normalizeUrl(baseUrl)}/api/v1/health');
      final req = await client.getUrl(uri);
      final resp = await req.close();
      if (resp.statusCode == 200) {
        return const Result.success(true);
      }
      return Result.error(VaultFailure(
        'Server returned status ${resp.statusCode}',
        type: VaultFailureType.ioError,
      ));
    } catch (e) {
      return Result.error(VaultFailure(
        'Cannot connect to sync server: $e',
        type: VaultFailureType.ioError,
      ));
    } finally {
      client.close();
    }
  }

  /// Registers or initializes a vault on the sync server.
  Future<Result<bool, VaultFailure>> initVault({
    required String baseUrl,
    required String vaultId,
    required String authHash,
    String? registrationToken,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('${_normalizeUrl(baseUrl)}/api/v1/vault/init');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'vaultId': vaultId,
        'authHash': authHash,
        if (registrationToken != null && registrationToken.isNotEmpty)
          'registrationToken': registrationToken,
      });

      req.write(body);
      final resp = await req.close();
      final respBody = await utf8.decodeStream(resp);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return const Result.success(true);
      } else {
        return Result.error(VaultFailure(
          'Vault initialization failed (${resp.statusCode}): $respBody',
          type: VaultFailureType.ioError,
        ));
      }
    } catch (e) {
      return Result.error(VaultFailure(
        'Failed to connect to sync server: $e',
        type: VaultFailureType.ioError,
      ));
    } finally {
      client.close();
    }
  }

  /// Fetches changes since a given revision.
  Future<Result<SyncChangesResponse, VaultFailure>> fetchChanges({
    required String baseUrl,
    required String vaultId,
    required String authHash,
    int sinceRevision = 0,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('${_normalizeUrl(baseUrl)}/api/v1/sync/changes')
          .replace(queryParameters: {
        'vaultId': vaultId,
        'authHash': authHash,
        'since': sinceRevision.toString(),
      });

      final req = await client.getUrl(uri);
      final resp = await req.close();
      final respBody = await utf8.decodeStream(resp);

      if (resp.statusCode == 200) {
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        return Result.success(SyncChangesResponse.fromJson(json));
      } else {
        return Result.error(VaultFailure(
          'Failed to fetch sync changes (${resp.statusCode}): $respBody',
          type: VaultFailureType.ioError,
        ));
      }
    } catch (e) {
      return Result.error(VaultFailure(
        'Sync fetch error: $e',
        type: VaultFailureType.ioError,
      ));
    } finally {
      client.close();
    }
  }

  /// Pushes a batch of changes to the sync server.
  Future<Result<int, VaultFailure>> pushChanges({
    required String baseUrl,
    required String vaultId,
    required String authHash,
    required List<SyncItem> items,
  }) async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('${_normalizeUrl(baseUrl)}/api/v1/sync/push');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;

      final body = jsonEncode({
        'vaultId': vaultId,
        'authHash': authHash,
        'items': items.map((i) => i.toJson()).toList(),
      });

      req.write(body);
      final resp = await req.close();
      final respBody = await utf8.decodeStream(resp);

      if (resp.statusCode == 200) {
        final json = jsonDecode(respBody) as Map<String, dynamic>;
        final newRev = json['newRevision'] as int? ?? 0;
        return Result.success(newRev);
      } else {
        return Result.error(VaultFailure(
          'Failed to push sync changes (${resp.statusCode}): $respBody',
          type: VaultFailureType.ioError,
        ));
      }
    } catch (e) {
      return Result.error(VaultFailure(
        'Sync push error: $e',
        type: VaultFailureType.ioError,
      ));
    } finally {
      client.close();
    }
  }
}
