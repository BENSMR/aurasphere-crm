import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// PaddlePaymentService - Paddle payment processing via Edge Function proxy
/// 
/// ✅ SECURE: API keys stored in Supabase Secrets only
/// ✅ NO keys exposed on frontend
/// ✅ All calls go through Edge Function: supabase/functions/paddle-proxy/
/// 
/// Simpler alternative to Stripe with:
/// - Automatic tax calculation
/// - Multiple currency support
/// - Built-in chargeback protection

class PaddlePaymentService {
  static final PaddlePaymentService _instance = PaddlePaymentService._internal();
  final supabase = Supabase.instance.client;

  // PRODUCT & PRICE IDs (Get from Paddle dashboard)
  // Get from: https://vendors.paddle.com/pricing-plans
  static const Map<String, String> priceIds = {
    'solo': '123456',        // Replace with real Paddle Price ID
    'team': '123457',
    'workshop': '123458',
  };

  PaddlePaymentService._internal();

  factory PaddlePaymentService() => _instance;

  /// Validate price IDs are configured
  static void validatePriceIds() {
    final missingIds = <String>[];
    priceIds.forEach((plan, id) {
      if (id.contains('XXXXXXXX') || id == '123456' || id == '123457' || id == '123458' || id.startsWith('price_')) {
        missingIds.add('$plan: $id');
      }
    });
    if (missingIds.isNotEmpty) {
      _logger.w('⚠️  WARNING: Missing Paddle price IDs: $missingIds');
      _logger.i('   Get these from: https://vendors.paddle.com/pricing-plans');
    }
  }

  /// Create a Paddle customer via backend proxy
  static Future<String?> createCustomer({
    required String email,
    required String name,
    String? country,
  }) async {
    try {
      _logger.i('💳 Creating Paddle customer: $email');

      final response = await Supabase.instance.client.functions.invoke(
        'paddle-proxy',
        body: {
          'action': 'create_customer',
          'email': email,
          'name': name,
          'country_code': country ?? 'US',
        },
      );

      if (response['success'] == true) {
        final customerId = response['customer_id'] as String;
        _logger.i('✅ Paddle customer created: $customerId');
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

  /// Create a Paddle subscription via backend proxy
  static Future<Map<String, dynamic>?> createSubscription({
    required String customerId,
    required String planId, // 'solo', 'team', 'workshop'
    String? billingCycle, // 'monthly', 'yearly'
  }) async {
    try {
      final priceId = priceIds[planId];
      if (priceId == null) {
        _logger.e('❌ Invalid plan ID: $planId');
        return null;
      }

      _logger.i('💳 Creating Paddle subscription: $planId');

      final response = await Supabase.instance.client.functions.invoke(
        'paddle-proxy',
        body: {
          'action': 'create_subscription',
          'customer_id': customerId,
          'price_id': priceId,
          'billing_cycle': {
            'interval': billingCycle ?? 'month',
            'frequency': 1,
          },
        },
      );

      if (response['success'] == true) {
        _logger.i('✅ Paddle subscription created');
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

  /// Cancel a Paddle subscription via backend proxy
  static Future<bool> cancelSubscription({required String subscriptionId}) async {
    try {
      _logger.i('💳 Cancelling Paddle subscription: $subscriptionId');

      final response = await Supabase.instance.client.functions.invoke(
        'paddle-proxy',
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

  /// Update a Paddle subscription via backend proxy
  static Future<bool> updateSubscription({
    required String subscriptionId,
    required String newPriceId,
  }) async {
    try {
      _logger.i('💳 Updating Paddle subscription: $subscriptionId');

      final response = await Supabase.instance.client.functions.invoke(
        'paddle-proxy',
        body: {
          'action': 'update_subscription',
          'subscription_id': subscriptionId,
          'new_price_id': newPriceId,
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
      _logger.i('💳 Fetching Paddle subscription: $subscriptionId');

      final response = await Supabase.instance.client.functions.invoke(
        'paddle-proxy',
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
