import 'dart:io';
import 'package:drift/native.dart';
import 'vault_database.dart';

/// Builder and connection provider for [VaultDatabase] with optional SQLCipher encryption pragma.
class VaultDatabaseConnection {
  VaultDatabaseConnection._();

  /// Creates an in-memory [VaultDatabase], useful for testing or ephemeral sessions.
  static VaultDatabase inMemory({String? encryptionKeyHex}) {
    final executor = NativeDatabase.memory(
      setup: (rawDb) {
        if (encryptionKeyHex != null && encryptionKeyHex.isNotEmpty) {
          rawDb.execute("PRAGMA key = \"x'$encryptionKeyHex'\";");
        }
      },
    );
    return VaultDatabase(executor);
  }

  /// Creates a file-backed [VaultDatabase] at [file], applying SQLCipher [encryptionKeyHex] if specified.
  static VaultDatabase openFile(File file, {String? encryptionKeyHex}) {
    final executor = NativeDatabase(
      file,
      setup: (rawDb) {
        if (encryptionKeyHex != null && encryptionKeyHex.isNotEmpty) {
          rawDb.execute("PRAGMA key = \"x'$encryptionKeyHex'\";");
        }
      },
    );
    return VaultDatabase(executor);
  }
}
