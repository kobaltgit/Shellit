import 'dart:typed_data';
import 'package:meta/meta.dart';
import '../enums/enums.dart';

/// Represents a secure SSH Key Pair (Ed25519, RSA, ECDSA).
@immutable
class KeyEntity {
  final String id;
  final String label;
  final KeyType keyType;
  final Uint8List encryptedPrivateKey;
  final String publicKey;
  final Uint8List? encryptedPassphrase;
  final String? fingerprint;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KeyEntity({
    required this.id,
    required this.label,
    required this.keyType,
    required this.encryptedPrivateKey,
    required this.publicKey,
    this.encryptedPassphrase,
    this.fingerprint,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns true if this private key is protected by an additional passphrase.
  bool get hasPassphrase =>
      encryptedPassphrase != null && encryptedPassphrase!.isNotEmpty;

  KeyEntity copyWith({
    String? id,
    String? label,
    KeyType? keyType,
    Uint8List? encryptedPrivateKey,
    String? publicKey,
    Uint8List? encryptedPassphrase,
    String? fingerprint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KeyEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      keyType: keyType ?? this.keyType,
      encryptedPrivateKey: encryptedPrivateKey ?? this.encryptedPrivateKey,
      publicKey: publicKey ?? this.publicKey,
      encryptedPassphrase: encryptedPassphrase ?? this.encryptedPassphrase,
      fingerprint: fingerprint ?? this.fingerprint,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'KeyEntity($label, type: $keyType, fp: $fingerprint)';
}
