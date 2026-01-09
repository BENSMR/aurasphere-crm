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
        final newKey = encryptLib.Key.fromSecureRandom(32); // 256-bit key
        final newIv = encryptLib.IV.fromSecureRandom(16); // 128-bit IV
        _encryptionKey = newKey;
        _iv = newIv;
        
        // Store securely
        await _storage.write(key: _keyName, value: newKey.base64);
        await _storage.write(key: _ivName, value: newIv.base64);
        _logger.d('✅ New AES-256 encryption key generated and stored securely');
      }
          
      _initialized = true;
    } catch (e) {
      _logger.e('❌ PKI initialization failed: $e');
      rethrow; // Don't silently fail - encryption is critical
    }
  }

  /// Encrypt sensitive data using AES-256-CBC
  static String encrypt(String data) {
    if (!_initialized || _encryptionKey == null || _iv == null) {
      _logger.w('⚠️ Encryption not initialized, returning base64');
      return base64.encode(utf8.encode(data));
    }

    try {
      _logger.d('🔒 Encrypting data with AES-256...');
      final encrypter = encryptLib.Encrypter(
        encryptLib.AES(_encryptionKey!, mode: encryptLib.AESMode.cbc),
      );
      
      final encrypted = encrypter.encrypt(data, iv: _iv!);
      _logger.d('✅ Data encrypted successfully');
      return encrypted.base64;
    } catch (e) {
      _logger.e('❌ Encryption failed, returning base64: $e');
      return base64.encode(utf8.encode(data));
    }
  }

  /// Decrypt data using AES-256-CBC
  static String decrypt(String encrypted) {
    if (!_initialized || _encryptionKey == null || _iv == null) {
      _logger.w('⚠️ Encryption not initialized, trying base64 decode');
      try {
        return utf8.decode(base64.decode(encrypted));
      } catch (e) {
        return encrypted;
      }
    }

    try {
      _logger.d('🔓 Decrypting data with AES-256...');
      final encrypter = encryptLib.Encrypter(
        encryptLib.AES(_encryptionKey!, mode: encryptLib.AESMode.cbc),
      );
      
      final decrypted = encrypter.decrypt64(encrypted, iv: _iv!);
      _logger.d('✅ Data decrypted successfully');
      return decrypted;
    } catch (e) {
      _logger.e('❌ Decryption failed, trying base64: $e');
      try {
        return utf8.decode(base64.decode(encrypted));
      } catch (e2) {
        _logger.e('❌ Base64 decode also failed: $e2');
        return encrypted;
      }
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
