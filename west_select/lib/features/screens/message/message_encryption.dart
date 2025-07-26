import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class MessageEncryptionService {
  static final _instance = MessageEncryptionService._internal();
  factory MessageEncryptionService() => _instance;
  MessageEncryptionService._internal();

  // Use a consistent key derivation method
  static const String _keyDerivationSalt = 'west_select_msg_salt_2024';

  /// Derives an encryption key from conversation ID and user IDs
  Key _deriveKey(String conversationId, String userId1, String userId2) {
    // Sort user IDs to ensure consistent key generation regardless of order
    final sortedUsers = [userId1, userId2]..sort();
    final keyMaterial =
        '$conversationId${sortedUsers[0]}${sortedUsers[1]}$_keyDerivationSalt';

    // SHA-256 to derive a 32-byte key
    final bytes = utf8.encode(keyMaterial);
    final digest = sha256.convert(bytes);
    return Key(Uint8List.fromList(digest.bytes));
  }

  /// Generates a random IV for each message
  IV _generateIV() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }
    return IV(bytes);
  }

  /// Encrypts a message text
  String encryptMessage({
    required String plaintext,
    required String conversationId,
    required String senderId,
    required String receiverId,
  }) {
    try {
      if (plaintext.trim().isEmpty) return plaintext;

      final key = _deriveKey(conversationId, senderId, receiverId);
      final iv = _generateIV();
      final encrypter = Encrypter(AES(key));

      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combine IV and encrypted data, then base64 encode
      final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
      return base64.encode(combined);
    } catch (e) {
      return plaintext;
    }
  }

  /// Decrypts a message text
  String decryptMessage({
    required String encryptedText,
    required String conversationId,
    required String senderId,
    required String receiverId,
  }) {
    try {
      if (encryptedText.trim().isEmpty) return encryptedText;

      // Try to decode base64 - if it fails, assume it's unencrypted
      Uint8List combined;
      try {
        combined = base64.decode(encryptedText);
      } catch (e) {
        return encryptedText;
      }
      if (combined.length < 17) {
        // 16 bytes IV + at least 1 byte data
        return encryptedText;
      }
      final iv = IV(combined.sublist(0, 16));
      final encryptedBytes = combined.sublist(16);

      final key = _deriveKey(conversationId, senderId, receiverId);
      final encrypter = Encrypter(AES(key));

      final encrypted = Encrypted(encryptedBytes);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return encryptedText;
    }
  }

  /// Checks if a message appears to be encrypted
  bool isEncrypted(String message) {
    try {
      if (message.trim().isEmpty) return false;
      final decoded = base64.decode(message);
      return decoded.length >= 17;
    } catch (e) {
      return false;
    }
  }
}
