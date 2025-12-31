import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvLoader {
  // Fallback values for web (when .env fails to load)
  static final Map<String, String> _fallbackEnv = {
    'SUPABASE_URL': 'https://uielvgnzaurhopolerok.supabase.co',
    'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.xxxxx',
    'GROQ_API_KEY': 'gsk_xxxx',
    'RESEND_API_KEY': 're_xxxx',
    'OCR_API_KEY': 'K_xxxx',
  };

  static Future<void> init() async {
    try {
      // Web: Load from assets
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Fallback: dotenv couldn't load, but we have values in _fallbackEnv
      // Silently continue with fallback values
    }
  }

  static String get(String key) {
    // Try to get from dotenv first
    final value = dotenv.env[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    // Fall back to hardcoded values
    return _fallbackEnv[key] ?? '';
  }
}

