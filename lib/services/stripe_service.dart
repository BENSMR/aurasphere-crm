/// ❌ DEPRECATED - DO NOT USE
/// 
/// This file is no longer in use and contains hardcoded API keys that cause 401 errors.
/// 
/// WHAT HAPPENED:
/// - This old version made direct HTTP calls to Stripe API
/// - It used hardcoded placeholder keys: 'sk_test_YOUR_SECRET_KEY'
/// - These invalid keys resulted in 401 Unauthorized authentication errors
/// 
/// MIGRATION PATH:
/// All functionality has been moved to stripe_payment_service.dart which uses:
/// - Supabase Edge Functions as a secure proxy (supabase/functions/stripe-proxy/)
/// - Secrets stored safely in Supabase (Settings → Secrets)
/// - No API keys exposed on the frontend
/// 
/// IF YOU SEE THIS ERROR:
/// - "invalid api key" / "401 Unauthorized"
/// - Make sure ALL imports use stripe_payment_service.dart NOT this file
/// - This file should be completely removed in cleanup
/// 
/// CORRECT USAGE:
/// import 'package:aura_crm/services/stripe_payment_service.dart';
/// final result = await StripePaymentService().createSubscription(...);
/// 
/// WRONG USAGE (DO NOT DO):
/// import 'package:aura_crm/services/stripe_service.dart';  // ❌ DEPRECATED
/// 
/// Deprecated: 2025-01-17
/// Status: DISABLED - Do not use
library;

// Dummy class to prevent accidental usage
class StripeService {
  // ignore: unused_field
  static final StripeService _instance = StripeService._internal();
  
  StripeService._internal() {
    throw UnsupportedError(
      'stripe_service.dart is deprecated. Use stripe_payment_service.dart instead.',
    );
  }
  
  factory StripeService() {
    throw UnsupportedError(
      'stripe_service.dart is deprecated. Use stripe_payment_service.dart instead.',
    );
  }
}


