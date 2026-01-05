/// Environment variable loader for web (no .env file support)
/// 
/// Flutter Web doesn't support .env files or dotenv package.
/// Uses hardcoded values from Supabase project configuration.
/// 
/// 🔐 API KEYS SETUP:
/// 1. GROQ_API_KEY - Get from https://console.groq.com → API Keys
/// 2. RESEND_API_KEY - Get from https://resend.com → API Keys (starts with 're_')
/// 
/// Add these to Supabase Secrets: https://app.supabase.com → Settings → Secrets
class EnvLoader {
  // Fallback values for web (hardcoded from Supabase project)
  static final Map<String, String> _fallbackEnv = {
    // Supabase Configuration
    'SUPABASE_URL': 'https://fppmvibvpxrkwmymszhd.supabase.co',
    'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwcG11aWJ2cHhya3dteW1zemhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYxMjU1MzUsImV4cCI6MjA4MTcwMTUzNX0.Qm99GcdIdl9iBywdsjmP8Gh5SMLk3UYulwytxXTnzxA',
    
    // AI & LLM Configuration
    'GROQ_API_KEY': '', // ← Add your Groq API key here (https://console.groq.com)
    
    // Email Service Configuration  
    'RESEND_API_KEY': '', // ← Add your Resend API key here (https://resend.com)
    
    // Optional: Payment Configuration
    'STRIPE_PUBLIC_KEY': '',
    'STRIPE_SECRET_KEY': '',
    
    // Optional: WhatsApp Configuration
    'TWILIO_ACCOUNT_SID': '',
    'TWILIO_AUTH_TOKEN': '',
  };

  static Future<void> init() async {
    // No-op for web - values are hardcoded above
    // For production: load from Supabase Secrets via admin API
  }

  static String get(String key) {
    final value = _fallbackEnv[key];
    if (value == null || value.isEmpty) {
      print('⚠️  Environment variable "$key" is not set. Some features may be disabled.');
    }
    return value ?? '';
  }

  /// Check if an API key is configured
  static bool isConfigured(String key) {
    return (_fallbackEnv[key] ?? '').isNotEmpty;
  }
}

