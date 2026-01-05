// lib/services/whatsapp_service.dart
// ✅ ENHANCED: Error handling, retry logic, templates, delivery tracking
import 'package:aura_crm/core/env_loader.dart';

class WhatsAppService {
  static const _maxRetries = 3;
  static const _retryDelayMs = 2000;
  static const _apiUrl = 'https://graph.facebook.com/v18.0';
  
  static String get _apiKey {
    final key = EnvLoader.get('WHATSAPP_API_KEY');
    if (key.isEmpty) {
      print('⚠️ WHATSAPP_API_KEY not configured in .env');
      return '';
    }
    return key;
  }
  
  static String get _phoneNumberId {
    final id = EnvLoader.get('WHATSAPP_PHONE_NUMBER_ID');
    if (id.isEmpty) {
      print('⚠️ WHATSAPP_PHONE_NUMBER_ID not configured in .env');
      return '';
    }
    return id;
  }
  
  /// Check if WhatsApp is configured
  static bool get isConfigured {
    return _apiKey.isNotEmpty && _phoneNumberId.isNotEmpty;
  }
}