import 'dart:convert';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';

/// Metadata resulting from a parsed SSH private key.
class ParsedKeyInfo {
  final List<SSHKeyPair> keyPairs;
  final KeyType keyType;
  final String publicKeyString;
  final String fingerprint;
  final bool isEncrypted;
  final String? comment;

  const ParsedKeyInfo({
    required this.keyPairs,
    required this.keyType,
    required this.publicKeyString,
    required this.fingerprint,
    required this.isEncrypted,
    this.comment,
  });

  /// Primary key pair (first one in case of multiple keys).
  SSHKeyPair get primaryKeyPair => keyPairs.first;

  @override
  String toString() =>
      'ParsedKeyInfo(type: $keyType, fp: $fingerprint, encrypted: $isEncrypted)';
}

/// Service for parsing and validating SSH private keys (Ed25519, RSA, ECDSA).
class KeyParserService {
  const KeyParserService();

  /// Detects whether the provided PEM string or key bytes are encrypted.
  bool isEncrypted(String pemText) {
    try {
      return SSHKeyPair.isEncryptedPem(pemText.trim());
    } catch (_) {
      return pemText.contains('ENCRYPTED') || pemText.contains('bcrypt');
    }
  }

  /// Detects the key algorithm type (Ed25519, RSA, ECDSA) by inspecting key headers/content.
  KeyType detectKeyType(String pemText) {
    final lower = pemText.toLowerCase();
    if (lower.contains('ec private key')) {
      return KeyType.ecdsa;
    }
    if (lower.contains('rsa private key')) {
      return KeyType.rsa;
    }

    // Inspect OpenSSH PEM structure directly
    try {
      final pem = SSHPem.decode(pemText.trim());
      if (pem.type == 'OPENSSH PRIVATE KEY') {
        final keypairs = OpenSSHKeyPairs.decode(pem.content);
        if (keypairs.publicKeys.isNotEmpty) {
          final bytes = keypairs.publicKeys.first;
          if (bytes.length >= 4) {
            final len = (bytes[0] << 24) |
                (bytes[1] << 16) |
                (bytes[2] << 8) |
                bytes[3];
            if (bytes.length >= 4 + len) {
              final pubType =
                  ascii.decode(bytes.sublist(4, 4 + len)).toLowerCase();
              if (pubType.contains('ecdsa') || pubType.contains('nistp')) {
                return KeyType.ecdsa;
              }
              if (pubType.contains('rsa')) {
                return KeyType.rsa;
              }
              if (pubType.contains('ed25519')) {
                return KeyType.ed25519;
              }
            }
          }
        }
      }
    } catch (_) {}

    if (lower.contains('ecdsa') || lower.contains('nistp')) {
      return KeyType.ecdsa;
    }
    if (lower.contains('ssh-rsa') || lower.contains('rsa')) {
      return KeyType.rsa;
    }

    return KeyType.ed25519;
  }

  /// Parses a PEM-formatted private key with an optional passphrase.
  Result<ParsedKeyInfo, NetworkFailure> parseKey({
    required String pem,
    String? passphrase,
  }) {
    final trimmedPem = pem.trim();
    if (trimmedPem.isEmpty) {
      return const Result.error(
        NetworkFailure(
          'SSH ключ пуст.',
          type: NetworkFailureType.keyParseError,
        ),
      );
    }

    try {
      final encrypted = isEncrypted(trimmedPem);

      if (encrypted && (passphrase == null || passphrase.isEmpty)) {
        return const Result.error(
          NetworkFailure(
            'SSH ключ зашифрован. Требуется passphrase.',
            type: NetworkFailureType.keyParseError,
          ),
        );
      }

      // dartssh2 throws ArgumentError if passphrase is not null for unencrypted keys
      final effectivePassphrase = encrypted ? passphrase : null;
      final keyPairs = SSHKeyPair.fromPem(trimmedPem, effectivePassphrase);

      if (keyPairs.isEmpty) {
        return const Result.error(
          NetworkFailure(
            'В PEM файле не найдено действительных SSH ключей.',
            type: NetworkFailureType.keyParseError,
          ),
        );
      }

      final primary = keyPairs.first;
      final keyType = _mapKeyType(primary);
      final pubBytes = primary.toPublicKey().encode();
      final fingerprint = computeFingerprint(pubBytes);
      final publicKeyString = formatPublicKey(primary);

      return Result.success(
        ParsedKeyInfo(
          keyPairs: keyPairs,
          keyType: keyType,
          publicKeyString: publicKeyString,
          fingerprint: fingerprint,
          isEncrypted: encrypted,
        ),
      );
    } on SSHKeyDecryptError catch (e, stack) {
      return Result.error(
        NetworkFailure(
          'Неверный passphrase для расшифровки SSH ключа.',
          type: NetworkFailureType.keyParseError,
          cause: e,
          stackTrace: stack,
        ),
      );
    } catch (e, stack) {
      return Result.error(
        NetworkFailure(
          'Ошибка при парсинге SSH ключа: $e',
          type: NetworkFailureType.keyParseError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  /// Parses private key raw bytes (decoding as UTF-8 PEM text).
  Result<ParsedKeyInfo, NetworkFailure> parseKeyBytes({
    required List<int> bytes,
    String? passphrase,
  }) {
    try {
      final pemString = utf8.decode(bytes);
      return parseKey(pem: pemString, passphrase: passphrase);
    } catch (e, stack) {
      return Result.error(
        NetworkFailure(
          'Не удалось прочитать байты SSH ключа в формате UTF-8.',
          type: NetworkFailureType.keyParseError,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  /// Computes the standard OpenSSH SHA256 base64 fingerprint without padding.
  /// Example: SHA256:roX2tJvX92...
  String computeFingerprint(Uint8List publicKeyBytes) {
    final digest = sha256.convert(publicKeyBytes);
    final b64 = base64.encode(digest.bytes).replaceAll('=', '');
    return 'SHA256:$b64';
  }

  /// Formats the public key in standard OpenSSH authorized_keys format.
  /// Example: `ssh-ed25519 AAAAC3... user@example.com`
  String formatPublicKey(SSHKeyPair keyPair, {String? comment}) {
    final pubBytes = keyPair.toPublicKey().encode();
    final b64 = base64.encode(pubBytes);
    final commentSuffix =
        (comment != null && comment.isNotEmpty) ? ' $comment' : '';
    return '${keyPair.name} $b64$commentSuffix';
  }

  KeyType _mapKeyType(SSHKeyPair keyPair) {
    final name = keyPair.name.toLowerCase();
    if (name.contains('ed25519')) {
      return KeyType.ed25519;
    }
    if (name.contains('ecdsa') || name.contains('nistp')) {
      return KeyType.ecdsa;
    }
    if (name.contains('rsa')) {
      return KeyType.rsa;
    }
    return KeyType.ed25519;
  }
}
