import 'dart:convert';
import 'dart:typed_data';

/// Utility functions for cryptographic byte manipulations.
class CryptoUtils {
  CryptoUtils._();

  /// Converts bytes to a lowercase hexadecimal string.
  static String bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Parses a hexadecimal string into [Uint8List].
  static Uint8List hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError('Hex string must have an even length');
    }
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  /// Encodes bytes to Base64.
  static String bytesToBase64(List<int> bytes) => base64.encode(bytes);

  /// Decodes Base64 to [Uint8List].
  static Uint8List base64ToBytes(String str) => base64.decode(str);
}
