/// ❌ DEPRECATED - Resend Email Service
/// This service is DISABLED because it uses String.fromEnvironment for API keys.
/// String.fromEnvironment returns EMPTY STRINGS at runtime, causing 401 auth errors.
/// 
/// PROBLEM:
/// static const String apiKey = String.fromEnvironment('RESEND_API_KEY');
/// At runtime: apiKey = '' (empty string)
/// Result: All HTTP requests fail with 401 Unauthorized
/// 
/// MIGRATION: Use email_service.dart with Edge Function proxy instead
/// See: lib/services/email_service.dart and supabase/functions/send-email/
/// 
/// STATUS: DISABLED - Throws error if instantiated
library;

class ResendEmailService {
  // ignore: unused_element
  ResendEmailService._internal() {
    throw UnsupportedError(
      'ResendEmailService is deprecated. Use email_service.dart with Edge Functions instead.',
    );
  }

  factory ResendEmailService() {
    throw UnsupportedError(
      'ResendEmailService is deprecated. Use email_service.dart with Edge Functions instead.',
    );
  }
}
