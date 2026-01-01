// lib/services/aura_security.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encryptLib;
import 'package:logger/logger.dart';

final _logger = Logger();

class AuraSecurity {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'aura_aes_key';
  static const _ivName = 'aura_aes_iv';
  static encryptLib.Key? _encryptionKey;
  static encryptLib.IV? _iv;
  static bool _initialized = false;

  /// Initialize AES-256 encryption with secure key generation
  static Future<void> initPKI() async {
    if (_initialized) return;

    try {
      // Check if key already exists in secure storage
      String? existingKeyStr = await _storage.read(key: _keyName);
      String? existingIvStr = await _storage.read(key: _ivName);
      
      if (existingKeyStr != null && existingIvStr != null) {
        // Load existing key and IV
        _encryptionKey = encryptLib.Key(base64.decode(existingKeyStr));
        _iv = encryptLib.IV(base64.decode(existingIvStr));
        _logger.d('✅ Existing AES-256 encryption key loaded from secure storage');
      } else {
        // Generate new key and IV
        _encryptionKey = encryptLib.Key.fromSecureRandom(32); // 256-bit key
        _iv = encryptLib.IV.fromSecureRandom(16); // 128-bit IV
        
        // Store in secure storage
        await _storage.write(
          key: _keyName,
          value: base64.encode(_encryptionKey!.bytes),
        );
        await _storage.write(
          key: _ivName,
          value: base64.encode(_iv!.bytes),
        );
        _logger.i('✅ New AES-256 encryption keys generated and stored securely');
      }
      
      _initialized = true;
    } catch (e) {
      _logger.e('❌ PKI initialization failed: $e');
      rethrow; // Don't silently fail - encryption is critical
    }
  }

  /// Encrypt sensitive data using AES-256-CBC
  static String encrypt(String data) {
    if (_encryptionKey == null || _iv == null) {
      _logger.w('⚠️ Encryption key not initialized');
      return data;
    }
    
    try {
      final cipher = encryptLib.Encrypter(encryptLib.AES(_encryptionKey!, encryptLib.AESMode.cbc));
      final encrypted = cipher.encrypt(data, iv: _iv!);
      
      // Return base64-encoded encrypted data
      return base64.encode(utf8.encode(encrypted.base64));
    } catch (e) {
      _logger.e('❌ Encryption failed: $e');
      throw Exception('Encryption failed: $e');
    }
  }

  /// Decrypt data using AES-256-CBC
  static String decrypt(String encrypted) {
    if (_encryptionKey == null || _iv == null) {
      _logger.w('⚠️ Encryption key not initialized');
      return encrypted;
    }
    
    try {
      // Decode from base64
      final encryptedBase64 = utf8.decode(base64.decode(encrypted));
      
      final cipher = encryptLib.Encrypter(encryptLib.AES(_encryptionKey!, encryptLib.AESMode.cbc));
      final decrypted = cipher.decrypt64(encryptedBase64, iv: _iv!);
      
      return decrypted;
    } catch (e) {
      _logger.e('❌ Decryption failed: $e');
      throw Exception('Decryption failed: $e');
    }
  }

  /// Clear encryption keys (for logout or key rotation)
  static Future<void> clearKeys() async {
    try {
      await _storage.delete(key: _keyName);
      await _storage.delete(key: _ivName);
    } catch (e) {
      _logger.e('❌ Failed to clear keys: $e');
    }
    _encryptionKey = null;
    _iv = null;
    _initialized = false;
    _logger.i('✅ PKI keys cleared');
  }

  /// Check if PKI is active
  static bool get isInitialized => _initialized;

  /// Rotate encryption keys (for security best practices)
  static Future<void> rotateKey() async {
    _logger.i('🔄 Starting key rotation...');
    await clearKeys();
    _initialized = false; // Force re-initialization
    await initPKI();
    _logger.i('✅ AES-256 keys rotated successfully');
  }
}
