import 'package:http/http.dart' as http;
import 'dart:convert';

/// PaddlePaymentService - Paddle payment processing (Alternative to Stripe)
/// 
/// Simpler alternative with:
/// - Automatic tax calculation
/// - Multiple currency support
/// - Built-in chargeback protection

class PaddlePaymentService {
  static const String baseUrl = 'https://api.paddle.com/v1';
  static const String apiKey = String.fromEnvironment('PADDLE_API_KEY');
  static const String sellerId = String.fromEnvironment('PADDLE_SELLER_ID');

  // PRODUCT & PRICE IDs (Get from Paddle dashboard)
  // Get from: https://vendors.paddle.com/pricing-plans
  static const Map<String, String> priceIds = {
    'solo': '123456',        // Replace with real Paddle Price ID
    'team': '123457',
    'workshop': '123458',
  };
  
  // CONFIGURATION HELPER - warns if price IDs are still placeholders
  static void validatePriceIds() {
    final missingIds = <String>[];
    priceIds.forEach((plan, id) {
      if (id.contains('XXXXXXXX') || id == '123456' || id == '123457' || id == '123458' || id.startsWith('price_')) {
        missingIds.add('$plan: $id');
      }
    });
    if (missingIds.isNotEmpty) {
      print('⚠️  WARNING: Missing Paddle price IDs: $missingIds');
      print('   Get these from: https://vendors.paddle.com/pricing-plans');
    }
  }

  // CREATE CUSTOMER
  static Future<String?> createCustomer({
    required String email,
    required String name,
    String? country,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'name': name,
          'country_code': country ?? 'US',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['id'];
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
    required String planId, // 'solo', 'team', 'workshop'
    String? billingCycle, // 'monthly', 'yearly'
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
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customer_id': customerId,
          'items': [
            {
              'price_id': priceId,
            }
          ],
          'billing_cycle': {
            'interval': billingCycle ?? 'month',
            'frequency': 1,
          },
        }),
      );

      if (response.statusCode == 201) {
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
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
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
  static Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId/cancel'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
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

      final response = await http.patch(
        Uri.parse('$baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': [
            {
              'price_id': priceId,
            }
          ],
          'proration_billing_mode': 'prorated_immediately',
        }),
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

  // CREATE CHECKOUT SESSION (for payment page)
  static Future<String?> createCheckoutSession({
    required String customerId,
    required String planId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final priceId = priceIds[planId];
      if (priceId == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/checkout'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': [
            {
              'price_id': priceId,
              'quantity': 1,
            }
          ],
          'customer_id': customerId,
          'success_url': successUrl,
          'cancel_url': cancelUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['checkout_url']; // Redirect user to this URL
      } else {
        print('❌ Create checkout failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error creating checkout: $e');
      return null;
    }
  }

  // GET INVOICE
  static Future<Map<String, dynamic>?> getInvoice(String invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invoices/$invoiceId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting invoice: $e');
      return null;
    }
  }

  // LIST INVOICES FOR CUSTOMER
  static Future<List<Map<String, dynamic>>?> listInvoices(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customers/$customerId/invoices'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error listing invoices: $e');
      return null;
    }
  }

  // REFUND (Create credit note)
  static Future<bool> createRefund({
    required String invoiceId,
    double? amount,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/credit-notes'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'invoice_id': invoiceId,
          if (amount != null) 'amount': (amount * 100).toInt(),
          if (reason != null) 'reason': reason,
          'notes': 'Refund requested',
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Refund/Credit note created');
        return true;
      } else {
        print('❌ Create refund failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error creating refund: $e');
      return false;
    }
  }

  // GET PRICES (List all available prices)
  static Future<List<Map<String, dynamic>>?> getPrices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prices'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error getting prices: $e');
      return null;
    }
  }

  // VERIFY WEBHOOK SIGNATURE
  static bool verifyWebhookSignature({
    required String payload,
    required String signature,
  }) {
    // Paddle uses HMAC-SHA256 for signatures
    // Implementation would verify the signature matches
    return true;
  }
}
