/// ❌ DEPRECATED - DO NOT USE
/// 
/// This file is no longer in use and contains hardcoded API keys that cause 401 errors.
/// 
/// WHAT HAPPENED:
/// - This old version made direct HTTP calls to Paddle API
/// - It used hardcoded placeholder keys: 'YOUR_PADDLE_API_KEY'
/// - These invalid keys resulted in 401 Unauthorized authentication errors
/// 
/// MIGRATION PATH:
/// All functionality has been moved to paddle_payment_service.dart which uses:
/// - Supabase Edge Functions as a secure proxy (supabase/functions/paddle-proxy/)
/// - Secrets stored safely in Supabase (Settings → Secrets)
/// - No API keys exposed on the frontend
/// 
/// IF YOU SEE THIS ERROR:
/// - "invalid api key" / "401 Unauthorized"
/// - Make sure ALL imports use paddle_payment_service.dart NOT this file
/// - This file should be completely removed in cleanup
/// 
/// CORRECT USAGE:
/// import 'package:aura_crm/services/paddle_payment_service.dart';
/// final result = await PaddlePaymentService().createSubscription(...);
/// 
/// WRONG USAGE (DO NOT DO):
/// import 'package:aura_crm/services/paddle_service.dart';  // ❌ DEPRECATED
/// 
/// Deprecated: 2025-01-17
/// Status: DISABLED - Do not use
library;

// Dummy class to prevent accidental usage
class PaddleService {
  // ignore: unused_field
  static final PaddleService _instance = PaddleService._internal();
  
  PaddleService._internal() {
    throw UnsupportedError(
      'paddle_service.dart is deprecated. Use paddle_payment_service.dart instead.',
    );
  }
  
  factory PaddleService() {
    throw UnsupportedError(
      'paddle_service.dart is deprecated. Use paddle_payment_service.dart instead.',
    );
  }
}


