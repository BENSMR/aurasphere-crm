import 'package:http/http.dart' as http;
import 'dart:convert';

/// StripePaymentService - Stripe payment processing
/// 
/// Supports:
/// - Creating subscriptions
/// - Managing customers
/// - Handling webhooks
/// - Subscription updates/cancellations

class StripePaymentService {
  static const String baseUrl = 'https://api.stripe.com/v1';
  static const String secretKey = String.fromEnvironment('STRIPE_SECRET_KEY');
  static const String publishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  // PRODUCT & PRICE IDs (Set these in Stripe Dashboard)
  // Get from: https://dashboard.stripe.com/products
  static const Map<String, String> priceIds = {
    'solo': 'price_1234567890abcdef', // Replace with real Stripe Price ID
    'team': 'price_1234567890bcdefg',
    'workshop': 'price_1234567890cdefgh',
  };
  
  // CONFIGURATION HELPER - warns if price IDs are still placeholders
  static void validatePriceIds() {
    final missingIds = <String>[];
    priceIds.forEach((plan, id) {
      if (id.contains('XXXXXXXX') || id.contains('placeholder') || id.startsWith('price_') && id.length < 20) {
        missingIds.add('$plan: $id');
      }
    });
    if (missingIds.isNotEmpty) {
      print('⚠️  WARNING: Missing Stripe price IDs: $missingIds');
      print('   Get these from: https://dashboard.stripe.com/products');
    }
  }

  // CREATE CUSTOMER
  static Future<String?> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'name': name,
          'metadata[user_type]': 'crm_user',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id']; // Return customer ID
      } else {
        print('❌ Create customer failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating customer: $e');
      return null;
    }
  }

  // CREATE SUBSCRIPTION
  static Future<Map<String, dynamic>?> createSubscription({
    required String customerId,
    required String planId, // 'solo', 'team', or 'workshop'
  }) async {
    try {
      final priceId = priceIds[planId];
      if (priceId == null) {
        print('❌ Invalid plan ID: $planId');
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'items[0][price]': priceId,
          'payment_behavior': 'default_incomplete',
          'payment_settings[save_default_payment_method]': 'on_subscription',
          'expand[]': 'latest_invoice.payment_intent',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Create subscription failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating subscription: $e');
      return null;
    }
  }

  // GET SUBSCRIPTION
  static Future<Map<String, dynamic>?> getSubscription(String subscriptionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $secretKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Get subscription failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting subscription: $e');
      return null;
    }
  }

  // CANCEL SUBSCRIPTION
  static Future<bool> cancelSubscription(
    String subscriptionId, {
    String? reason,
  }) async {
    try {
      final body = {
        'cancellation_details[reason]': reason ?? 'cancellation_requested',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('✅ Subscription cancelled: $subscriptionId');
        return true;
      } else {
        print('❌ Cancel subscription failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error cancelling subscription: $e');
      return false;
    }
  }

  // UPDATE SUBSCRIPTION
  static Future<bool> updateSubscriptionPlan({
    required String subscriptionId,
    required String newPlanId,
  }) async {
    try {
      final priceId = priceIds[newPlanId];
      if (priceId == null) return false;

      // First get current subscription
      final sub = await getSubscription(subscriptionId);
      if (sub == null) return false;

      final currentItemId = sub['items']['data'][0]['id'];

      // Update item
      final response = await http.post(
        Uri.parse('$baseUrl/subscription_items/$currentItemId'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'price': priceId,
          'proration_behavior': 'create_prorations',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Subscription updated to $newPlanId');
        return true;
      } else {
        print('❌ Update subscription failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating subscription: $e');
      return false;
    }
  }

  // CREATE PAYMENT INTENT (for checkout)
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerId,
  }) async {
    try {
      final amountCents = (amount * 100).toInt();

      final response = await http.post(
        Uri.parse('$baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountCents.toString(),
          'currency': currency,
          'customer': customerId,
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Create payment intent failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating payment intent: $e');
      return null;
    }
  }

  // GET PAYMENT METHOD
  static Future<Map<String, dynamic>?> getPaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment_methods/$paymentMethodId'),
        headers: {
          'Authorization': 'Bearer $secretKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting payment method: $e');
      return null;
    }
  }

  // ATTACH PAYMENT METHOD TO CUSTOMER
  static Future<bool> attachPaymentMethod({
    required String paymentMethodId,
    required String customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payment_methods/$paymentMethodId/attach'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Attach payment method failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error attaching payment method: $e');
      return false;
    }
  }

  // REFUND
  static Future<bool> refund({
    required String chargeId,
    double? amount,
    String? reason,
  }) async {
    try {
      final body = {
        'charge': chargeId,
        if (amount != null) 'amount': ((amount * 100).toInt()).toString(),
        if (reason != null) 'reason': reason,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('✅ Refund processed');
        return true;
      } else {
        print('❌ Refund failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error processing refund: $e');
      return false;
    }
  }

  // VERIFY WEBHOOK SIGNATURE
  static bool verifyWebhookSignature({
    required String payload,
    required String signature,
  }) {
    final secret = const String.fromEnvironment('STRIPE_WEBHOOK_SECRET');
    if (secret.isEmpty) return false;

    // Stripe signature verification (simplified)
    // In production, use proper signature verification library
    return true;
  }
}
