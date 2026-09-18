import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'key_parser_service.dart';

/// Information about an SSH key discovered on the local file system.
class DiscoveredKey {
  final String fileName;
  final String privateKeyPath;
  final String? publicKeyPath;
  final KeyType keyType;
  final bool isEncrypted;
  final String? publicKeyString;
  final String? fingerprint;
  final String? comment;

  const DiscoveredKey({
    required this.fileName,
    required this.privateKeyPath,
    this.publicKeyPath,
    required this.keyType,
    required this.isEncrypted,
    this.publicKeyString,
    this.fingerprint,
    this.comment,
  });

  @override
  String toString() =>
      'DiscoveredKey($fileName, type: $keyType, enc: $isEncrypted, fp: $fingerprint)';
}

/// Service that discovers and inspects SSH keys in the local `~/.ssh` directory.
class SshDirectoryDiscoveryService {
  final KeyParserService _keyParser;

  const SshDirectoryDiscoveryService({
    KeyParserService keyParser = const KeyParserService(),
  }) : _keyParser = keyParser;

  /// Returns the standard default path to the user's `~/.ssh` folder on this OS.
  String? getDefaultSshDirectoryPath() {
    try {
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null && userProfile.isNotEmpty) {
          final sep = Platform.pathSeparator;
          return '$userProfile$sep.ssh';
        }
      } else {
        final home = Platform.environment['HOME'];
        if (home != null && home.isNotEmpty) {
          final sep = Platform.pathSeparator;
          return '$home$sep.ssh';
        }
      }
    } catch (_) {
      // Platform checks may throw on Web or unsupported environments
    }
    return null;
  }

  /// Scans the given directory (or default `~/.ssh`) and returns all discovered private keys.
  Future<List<DiscoveredKey>> scanDirectory([String? customPath]) async {
    final dirPath = customPath ?? getDefaultSshDirectoryPath();
    if (dirPath == null) return [];

    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final List<DiscoveredKey> results = [];

    try {
      final entries = await dir.list().toList();

      // Collect all .pub files into a map for fast lookup: basename -> content & path
      final Map<String, (String path, String content)> pubFiles = {};
      for (final entity in entries) {
        if (entity is File && entity.path.endsWith('.pub')) {
          final baseName = _getBaseName(entity.path);
          final privName = baseName.substring(0, baseName.length - 4);
          try {
            final pubContent = await entity.readAsString();
            pubFiles[privName] = (entity.path, pubContent.trim());
          } catch (_) {}
        }
      }

      // Scan private key candidates
      for (final entity in entries) {
        if (entity is! File) continue;

        final baseName = _getBaseName(entity.path);

        // Skip non-key files
        if (baseName.endsWith('.pub') ||
            baseName.startsWith('known_hosts') ||
            baseName.startsWith('config') ||
            baseName.startsWith('authorized_keys')) {
          continue;
        }

        try {
          final content = await entity.readAsString();
          if (!_isPrivateKeyFile(content)) continue;

          final keyType = _keyParser.detectKeyType(content);
          final encrypted = _keyParser.isEncrypted(content);

          String? pubKeyStr;
          String? fingerprint;
          String? comment;
          String? pubPath;

          // Check if we have a matching .pub file
          if (pubFiles.containsKey(baseName)) {
            final (pPath, pContent) = pubFiles[baseName]!;
            pubPath = pPath;
            pubKeyStr = pContent;
            final parts = pContent.split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              comment = parts.sublist(2).join(' ');
            }
          }

          // If not encrypted, parse key directly to get real fingerprint and pubkey
          if (!encrypted) {
            final parseRes = _keyParser.parseKey(pem: content);
            if (parseRes.isSuccess) {
              final info = parseRes.valueOrNull!;
              pubKeyStr ??= info.publicKeyString;
              fingerprint ??= info.fingerprint;
              comment ??= info.comment;
            }
          }

          results.add(
            DiscoveredKey(
              fileName: baseName,
              privateKeyPath: entity.path,
              publicKeyPath: pubPath,
              keyType: keyType,
              isEncrypted: encrypted,
              publicKeyString: pubKeyStr,
              fingerprint: fingerprint,
              comment: comment,
            ),
          );
        } catch (_) {
          // File might be binary or unreadable; skip gracefully
        }
      }
    } catch (_) {
      // Directory access error
    }

    return results;
  }

  bool _isPrivateKeyFile(String content) {
    final trimmed = content.trim();
    return trimmed.contains('-----BEGIN ') &&
        trimmed.contains('PRIVATE KEY-----');
  }

  String _getBaseName(String fullPath) {
    final sep = fullPath.contains('/') ? '/' : '\\';
    return fullPath.split(sep).last;
  }
}
