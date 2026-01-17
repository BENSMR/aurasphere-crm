/// Environment variable loader for web (no .env file support)
/// 
/// SECURITY NOTE: In production, sensitive API keys (Groq, Resend, OCR) should NOT
/// be stored in client code. These are now handled by Supabase Edge Functions
/// (see backend_api_proxy.dart for implementation details).
/// 
/// Only public, non-sensitive values should be in frontend code.
class EnvLoader {
  static final Map<String, String> _env = {
    // ✅ PUBLIC: Supabase URL (safe to expose, contains no secrets)
    'SUPABASE_URL': 'https://lxufgzembtogmsvwhdvq.supabase.co',
    
    // ✅ SEMI-PUBLIC: Supabase Anon Key (limited scope via RLS policies)
    'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4dWZnemVtYnRvZ21zdndoZHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTAxMTAsImV4cCI6MjA4NDEyNjExMH0.5Ha4bS4HeuMEqqalpPa_wCSol116rxlllR5s__kVtFs',
    
    // ✅ PUBLIC: Supabase Publishable Key (for Stripe/integrations)
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_1ABjyAYUOpPWz_IfNsUM3A_JC2mu00A',
    
    // 🔒 SENSITIVE KEYS MOVED TO BACKEND EDGE FUNCTIONS:
    // - GROQ_API_KEY → supabase/functions/groq-proxy
    // - RESEND_API_KEY → supabase/functions/email-proxy  
    // - OCR_API_KEY → supabase/functions/ocr-proxy
    // Call BackendApiProxy instead of direct APIs to avoid exposing keys
  };

  /// Initialize environment (no-op for web)
  static Future<void> init() async {
    // Flutter Web doesn't support .env files - values are set above
    // For production, consider using Firebase Remote Config for dynamic keys
  }

  /// Get an environment variable
  static String get(String key) {
    return _env[key] ?? '';
  }

  /// Check if API key is configured
  static bool isApiKeyConfigured(String apiName) {
    return _env['${apiName}_API_KEY']?.isNotEmpty ?? false;
  }

  /// Set API key dynamically (useful for Supabase Edge Function integration)
  static void setApiKey(String apiName, String key) {
    _env['${apiName}_API_KEY'] = key;
  }
}
