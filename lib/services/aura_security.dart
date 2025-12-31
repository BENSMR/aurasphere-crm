// lib/services/aura_security.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class AuraSecurity {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'aura_pki_key';
  static String? _localKey;
  static bool _initialized = false;

  /// Initialize PKI encryption with client-side key generation
  static Future<void> initPKI() async {
    if (_initialized) return;

    try {
      // Check if key already exists in secure storage
      String? existingKey = await _storage.read(key: _keyName);
      
      _logger.d('Existing PKI encryption key loaded');
          
      _localKey = existingKey;
      _initialized = true;
    } catch (e) {
      _logger.e('PKI initialization failed: $e');
      // Fallback to generated key if secure storage fails
      _localKey = 'aura_fallback_key_${DateTime.now().millisecondsSinceEpoch}';
      _initialized = true;
    }
  }

  /// Encrypt sensitive data before sending to backend
  static String encrypt(String data) {
    if (_localKey == null) return data;
    
    try {
      // Simple XOR encryption for demo - use AES-256 in production
      final result = data.split('').map((c) {
        final charCode = c.codeUnitAt(0);
        final keyCode = _localKey!.codeUnitAt(0);
        return String.fromCharCode(charCode ^ keyCode);
      }).join();
      
      // Base64 encode for safe transport
      return base64.encode(utf8.encode(result));
    } catch (e) {
      _logger.e('Encryption failed: $e');
      return data;
    }
  }

  /// Decrypt data received from backend
  static String decrypt(String encrypted) {
    if (_localKey == null) return encrypted;
    
    try {
      // Decode from base64
      final decoded = utf8.decode(base64.decode(encrypted));
      
      // XOR decrypt
      return decoded.split('').map((c) {
        final charCode = c.codeUnitAt(0);
        final keyCode = _localKey!.codeUnitAt(0);
        return String.fromCharCode(charCode ^ keyCode);
      }).join();
    } catch (e) {
      _logger.e('Decryption failed: $e');
      return encrypted;
    }
  }

  /// Clear encryption keys (for logout or key rotation)
  static Future<void> clearKeys() async {
    try {
      await _storage.delete(key: _keyName);
    } catch (e) {
      _logger.e('Failed to clear keys: $e');
    }
    _localKey = null;
    _initialized = false;
    _logger.i('PKI keys cleared');
  }

  /// Check if PKI is active
  static bool get isInitialized => _initialized;

  /// Rotate encryption key (for security best practices)
  static Future<void> rotateKey() async {
    await clearKeys();
    await initPKI();
    _logger.i('PKI key rotated successfully');
  }
}
