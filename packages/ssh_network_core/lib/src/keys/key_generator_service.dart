import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart' as ed25519;
import 'package:pointycastle/export.dart' as pc;

/// Result of generating a new SSH key pair.
class GeneratedKeyPair {
  final String privateKeyPem;
  final String publicKeyString;
  final String fingerprint;
  final KeyType keyType;
  final String? comment;

  const GeneratedKeyPair({
    required this.privateKeyPem,
    required this.publicKeyString,
    required this.fingerprint,
    required this.keyType,
    this.comment,
  });

  @override
  String toString() =>
      'GeneratedKeyPair(type: $keyType, fp: $fingerprint, comment: $comment)';
}

/// Service for generating cryptographically secure SSH key pairs (Ed25519, RSA).
class KeyGeneratorService {
  const KeyGeneratorService();

  /// Generates a new Ed25519 SSH key pair (fast, modern, recommended).
  GeneratedKeyPair generateEd25519({
    String? comment,
  }) {
    final effectiveComment = comment ?? '';
    final signingKey = ed25519.SigningKey.generate();

    final privateKeyBytes = signingKey.asTypedList;
    final publicKeyBytes = signingKey.verifyKey.asTypedList;

    final keyPair = OpenSSHEd25519KeyPair(
      publicKeyBytes,
      privateKeyBytes,
      effectiveComment,
    );

    final privateKeyPem = keyPair.toPem();
    final pubKeyBytes = keyPair.toPublicKey().encode();
    final fingerprint = _computeFingerprint(pubKeyBytes);
    final b64Pub = base64.encode(pubKeyBytes);
    final suffix = effectiveComment.isNotEmpty ? ' $effectiveComment' : '';
    final publicKeyString = 'ssh-ed25519 $b64Pub$suffix';

    return GeneratedKeyPair(
      privateKeyPem: privateKeyPem,
      publicKeyString: publicKeyString,
      fingerprint: fingerprint,
      keyType: KeyType.ed25519,
      comment: effectiveComment.isNotEmpty ? effectiveComment : null,
    );
  }

  /// Generates a new RSA SSH key pair (default 4096-bit for maximum compatibility).
  GeneratedKeyPair generateRsa({
    int bitLength = 4096,
    String? comment,
  }) {
    final effectiveComment = comment ?? '';
    final secureRandom = _getSecureRandom();

    final keyGen = pc.RSAKeyGenerator();
    keyGen.init(
      pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ),
    );

    final pair = keyGen.generateKeyPair();
    final pub = pair.publicKey;
    final priv = pair.privateKey;

    final p = priv.p!;
    final q = priv.q!;
    final iqmp = q.modInverse(p);

    final keyPair = OpenSSHRsaKeyPair(
      pub.modulus!,
      pub.exponent!,
      priv.exponent!,
      iqmp,
      p,
      q,
      effectiveComment,
    );

    final privateKeyPem = keyPair.toPem();
    final pubKeyBytes = keyPair.toPublicKey().encode();
    final fingerprint = _computeFingerprint(pubKeyBytes);
    final b64Pub = base64.encode(pubKeyBytes);
    final suffix = effectiveComment.isNotEmpty ? ' $effectiveComment' : '';
    final publicKeyString = 'ssh-rsa $b64Pub$suffix';

    return GeneratedKeyPair(
      privateKeyPem: privateKeyPem,
      publicKeyString: publicKeyString,
      fingerprint: fingerprint,
      keyType: KeyType.rsa,
      comment: effectiveComment.isNotEmpty ? effectiveComment : null,
    );
  }

  /// Computes OpenSSH SHA256 base64 fingerprint without padding.
  String _computeFingerprint(Uint8List publicKeyBytes) {
    final digest = sha256.convert(publicKeyBytes);
    final b64 = base64.encode(digest.bytes).replaceAll('=', '');
    return 'SHA256:$b64';
  }

  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.SecureRandom('Fortuna');
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}
