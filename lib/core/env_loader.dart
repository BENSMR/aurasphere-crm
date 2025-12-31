import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvLoader {
  // Fallback values for web (when .env fails to load)
  static final Map<String, String> _fallbackEnv = {
    'SUPABASE_URL': 'https://fppmvibvpxrkwmymszhd.supabase.co',
    'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA',
    'SUPABASE_PUBLISHABLE_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA',
    'GROQ_API_KEY': 'gsk_xxxx',
    'RESEND_API_KEY': 're_xxxx',
    'OCR_API_KEY': 'K_xxxx',
  };

  late String supabaseUrl;
  late String supabaseAnonKey;

  EnvLoader() {
    supabaseUrl = _getValue('SUPABASE_URL');
    supabaseAnonKey = _getValue('SUPABASE_ANON_KEY');
  }

  String _getValue(String key) {
    // Try to get from dotenv first
    final value = dotenv.env[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    // Fall back to hardcoded values
    return _fallbackEnv[key] ?? '';
  }

  static Future<void> init() async {
    try {
      // Web: Load from assets
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Fallback: dotenv couldn't load, but we have values in _fallbackEnv
      print('⚠️ dotenv load failed (using fallback): $e');
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
