import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// StripePaymentService - Stripe payment processing via Edge Function proxy
/// 
/// ✅ SECURE: API keys stored in Supabase Secrets only
/// ✅ NO keys exposed on frontend
/// ✅ All calls go through Edge Function: supabase/functions/stripe-proxy/
/// 
/// Supports:
/// - Creating subscriptions
/// - Managing customers
/// - Handling webhooks
/// - Subscription updates/cancellations

class StripePaymentService {
  static final StripePaymentService _instance = StripePaymentService._internal();
  final supabase = Supabase.instance.client;

  // PRODUCT & PRICE IDs (Set these in Stripe Dashboard)
  // Get from: https://dashboard.stripe.com/products
  static const Map<String, String> priceIds = {
    'solo': 'price_1234567890abcdef', // Replace with real Stripe Price ID
    'team': 'price_1234567890bcdefg',
    'workshop': 'price_1234567890cdefgh',
  };

  StripePaymentService._internal();

  factory StripePaymentService() => _instance;

  /// Validate price IDs are configured
  static void validatePriceIds() {
    final missingIds = <String>[];
    priceIds.forEach((plan, id) {
      if (id.contains('XXXXXXXX') || id.contains('placeholder') || id.startsWith('price_') && id.length < 20) {
        missingIds.add('$plan: $id');
      }
    });
    if (missingIds.isNotEmpty) {
      _logger.w('⚠️  WARNING: Missing Stripe price IDs: $missingIds');
      _logger.i('   Get these from: https://dashboard.stripe.com/products');
    }
  }

  /// Create a Stripe customer via backend proxy
  static Future<String?> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      _logger.i('💳 Creating Stripe customer: $email');
      
      final response = await Supabase.instance.client.functions.invoke(
        'stripe-proxy',
        body: {
          'action': 'create_customer',
          'email': email,
          'name': name,
          'metadata': {'user_type': 'crm_user'},
        },
      );

      if (response['success'] == true) {
        final customerId = response['customer_id'] as String;
        _logger.i('✅ Stripe customer created: $customerId');
        return customerId;
      } else {
        _logger.e('❌ Create customer failed: ${response['error']}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error creating customer: $e');
      return null;
    }
  }

  /// Create a Stripe subscription via backend proxy
  static Future<Map<String, dynamic>?> createSubscription({
    required String customerId,
    required String planId, // 'solo', 'team', or 'workshop'
  }) async {
    try {
      final priceId = priceIds[planId];
      if (priceId == null) {
        _logger.e('❌ Invalid plan ID: $planId');
        return null;
      }

      _logger.i('💳 Creating Stripe subscription: $planId');

      final response = await Supabase.instance.client.functions.invoke(
        'stripe-proxy',
        body: {
          'action': 'create_subscription',
          'customer_id': customerId,
          'price_id': priceId,
          'payment_behavior': 'default_incomplete',
          'payment_settings': {'save_default_payment_method': 'on_subscription'},
        },
      );

      if (response['success'] == true) {
        _logger.i('✅ Stripe subscription created');
        return response as Map<String, dynamic>;
      } else {
        _logger.e('❌ Create subscription failed: ${response['error']}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error creating subscription: $e');
      return null;
    }
  }

  /// Cancel a Stripe subscription via backend proxy
  static Future<bool> cancelSubscription({required String subscriptionId}) async {
    try {
      _logger.i('💳 Cancelling Stripe subscription: $subscriptionId');

      final response = await Supabase.instance.client.functions.invoke(
        'stripe-proxy',
        body: {
          'action': 'cancel_subscription',
          'subscription_id': subscriptionId,
        },
      );

      if (response['success'] == true) {
        _logger.i('✅ Subscription cancelled');
        return true;
      } else {
        _logger.e('❌ Cancel failed: ${response['error']}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error cancelling subscription: $e');
      return false;
    }
  }

  /// Update a Stripe subscription via backend proxy
  static Future<bool> updateSubscription({
    required String subscriptionId,
    required String newPriceId,
  }) async {
    try {
      _logger.i('💳 Updating Stripe subscription: $subscriptionId');

      final response = await Supabase.instance.client.functions.invoke(
        'stripe-proxy',
        body: {
          'action': 'update_subscription',
          'subscription_id': subscriptionId,
          'new_price_id': newPriceId,
          'proration_behavior': 'create_prorations',
        },
      );

      if (response['success'] == true) {
        _logger.i('✅ Subscription updated');
        return true;
      } else {
        _logger.e('❌ Update failed: ${response['error']}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error updating subscription: $e');
      return false;
    }
  }

  /// Get subscription details via backend proxy
  static Future<Map<String, dynamic>?> getSubscription({required String subscriptionId}) async {
    try {
      _logger.i('💳 Fetching Stripe subscription: $subscriptionId');

      final response = await Supabase.instance.client.functions.invoke(
        'stripe-proxy',
        body: {
          'action': 'get_subscription',
          'subscription_id': subscriptionId,
        },
      );

      if (response['success'] == true) {
        _logger.i('✅ Subscription retrieved');
        return response as Map<String, dynamic>;
      } else {
        _logger.e('❌ Fetch failed: ${response['error']}');
        return null;
      }
    } catch (e) {
      _logger.e('❌ Error fetching subscription: $e');
      return null;
    }
  }
}
