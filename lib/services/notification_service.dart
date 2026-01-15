/// ❌ DEPRECATED - Notification Service
/// This service is DISABLED because it contains hardcoded placeholder Twilio credentials:
/// - TWILIO_ACCOUNT_SID = 'YOUR_TWILIO_ACCOUNT_SID' (INVALID - causes 401)
/// - TWILIO_AUTH_TOKEN = 'YOUR_TWILIO_AUTH_TOKEN' (INVALID - causes 401)
/// - TWILIO_PHONE_NUMBER = '+1234567890' (INVALID)
/// 
/// These hardcoded placeholders cause 401 Unauthorized errors.
/// 
/// MIGRATION: Use Edge Functions with Supabase Secrets for secure SMS
/// See: supabase/functions/send-sms/ (when implemented)
/// 
/// STATUS: DISABLED - Throws error if instantiated
library;

class NotificationService {
  NotificationService._internal() {
    throw UnsupportedError('NotificationService is deprecated. Use Edge Functions instead.');
  }

  factory NotificationService() {
    throw UnsupportedError('NotificationService is deprecated. Use Edge Functions instead.');
  }
}
