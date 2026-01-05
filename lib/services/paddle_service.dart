import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final _logger = Logger();

/// Paddle Payment Integration Service
/// Handles subscription billing, invoice payments, and payment intents
/// Paddle replaces Stripe for all payment processing
class PaddleService {
  static final PaddleService _instance = PaddleService._internal();

  // Replace with your actual Paddle keys
  static const String PADDLE_API_KEY = 'YOUR_PADDLE_API_KEY'; // Go to Dashboard → Auth tokens
  static const String PADDLE_VENDOR_ID = 'YOUR_PADDLE_VENDOR_ID'; // Found in Account settings
  static const String PADDLE_API_URL = 'https://api.paddle.com/2.0';

  final supabase = Supabase.instance.client;

  PaddleService._internal();

  factory PaddleService() {
    return _instance;
  }

  /// Create subscription for organization using Paddle Billing
  /// Plans: 'solo' ($9.99/month), 'team' ($20/month), 'workshop' ($49/month)
  Future<Map<String, dynamic>> createSubscription({
    required String orgId,
    required String planId,
    required String customerEmail,
    required String customerName,
  }) async {
    try {
      _logger.i('💳 Creating Paddle subscription for org: $orgId, plan: $planId');

      // Create Paddle customer
      final customerResponse = await http.post(
        Uri.parse('$PADDLE_API_URL/customers'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': customerEmail,
          'name': customerName,
          'custom_data': {
            'org_id': orgId,
          },
        }),
      );

      if (customerResponse.statusCode != 201) {
        throw Exception('Failed to create Paddle customer: ${customerResponse.body}');
      }

      final customerData = jsonDecode(customerResponse.body);
      final paddleCustomerId = customerData['data']['id'];

      // Store Paddle customer ID in org
      await supabase.from('organizations').update({
        'paddle_customer_id': paddleCustomerId,
      }).eq('id', orgId);

      // Create subscription
      final subscriptionResponse = await http.post(
        Uri.parse('$PADDLE_API_URL/subscriptions'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'customer_id': paddleCustomerId,
          'items': [
            {
              'price_id': planId,
              'quantity': 1,
            },
          ],
          'billing_cycle': {
            'interval': 'month',
            'frequency': 1,
          },
        }),
      );

      if (subscriptionResponse.statusCode != 201) {
        throw Exception('Failed to create subscription: ${subscriptionResponse.body}');
      }

      final subscriptionData = jsonDecode(subscriptionResponse.body);
      final subscriptionId = subscriptionData['data']['id'];
      final status = subscriptionData['data']['status'];

      // Store subscription info
      await supabase.from('organizations').update({
        'paddle_subscription_id': subscriptionId,
        'paddle_status': status,
        'subscription_plan': planId,
      }).eq('id', orgId);

      _logger.i('✅ Paddle subscription created: $subscriptionId');

      return {
        'subscription_id': subscriptionId,
        'customer_id': paddleCustomerId,
        'status': status,
        'plan_id': planId,
        'checkout_url':
            'https://checkout.paddle.com/pay/$planId?customer_id=$paddleCustomerId',
      };
    } catch (e) {
      _logger.e('❌ Error creating subscription: $e');
      rethrow;
    }
  }

  /// Generate payment link for invoice
  /// Clients can pay directly via Paddle Checkout
  Future<String> generatePaymentLink({
    required String invoiceId,
    required double amount,
    required String clientEmail,
    required String currency,
  }) async {
    try {
      _logger.i('🔗 Generating Paddle payment link for invoice: $invoiceId');

      // Create one-time payment link via Paddle
      final response = await http.post(
        Uri.parse('$PADDLE_API_URL/checkout'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': [
            {
              'price_id': 'one_time_$invoiceId', // Use invoice ID as product
              'quantity': 1,
            },
          ],
          'customer_email': clientEmail,
          'custom_data': {
            'invoice_id': invoiceId,
            'amount': amount.toString(),
            'currency': currency,
          },
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to generate payment link: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final checkoutUrl = data['data']['checkout_url'];

      _logger.i('✅ Payment link generated: $checkoutUrl');

      return checkoutUrl;
    } catch (e) {
      _logger.e('❌ Error generating payment link: $e');
      rethrow;
    }
  }

  /// Get subscription status
  /// Returns: active, trialing, past_due, paused, cancelled
  Future<String> getSubscriptionStatus(String orgId) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('paddle_subscription_id, paddle_status')
          .eq('id', orgId)
          .maybeSingle();

      if (org == null) {
        return 'inactive';
      }

      final subscriptionId = org['paddle_subscription_id'];
      if (subscriptionId == null) {
        return 'inactive';
      }

      final response = await http.get(
        Uri.parse('$PADDLE_API_URL/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
        },
      );

      if (response.statusCode != 200) {
        return 'unknown';
      }

      final data = jsonDecode(response.body);
      return data['data']['status'];
    } catch (e) {
      _logger.e('❌ Error getting subscription status: $e');
      return 'error';
    }
  }

  /// Cancel subscription
  /// Immediately cancels the subscription
  Future<bool> cancelSubscription(String orgId) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('paddle_subscription_id')
          .eq('id', orgId)
          .maybeSingle();

      if (org == null || org['paddle_subscription_id'] == null) {
        return false;
      }

      final subscriptionId = org['paddle_subscription_id'];

      final response = await http.patch(
        Uri.parse('$PADDLE_API_URL/subscriptions/$subscriptionId/cancel'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'effective_from': 'immediately',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }

      // Update org status
      await supabase.from('organizations').update({
        'paddle_status': 'cancelled',
      }).eq('id', orgId);

      _logger.i('✅ Subscription cancelled for org: $orgId');
      return true;
    } catch (e) {
      _logger.e('❌ Error cancelling subscription: $e');
      return false;
    }
  }

  /// Update subscription plan (upgrade/downgrade)
  /// Handles proration based on Paddle rules
  Future<bool> updateSubscription({
    required String orgId,
    required String newPlanId,
  }) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('paddle_subscription_id')
          .eq('id', orgId)
          .maybeSingle();

      if (org == null || org['paddle_subscription_id'] == null) {
        return false;
      }

      final subscriptionId = org['paddle_subscription_id'];

      final response = await http.patch(
        Uri.parse('$PADDLE_API_URL/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': [
            {
              'price_id': newPlanId,
              'quantity': 1,
            },
          ],
          'proration_billing_mode': 'prorated_immediately',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update subscription: ${response.body}');
      }

      // Update org plan
      await supabase.from('organizations').update({
        'subscription_plan': newPlanId,
      }).eq('id', orgId);

      _logger.i('✅ Subscription updated to plan: $newPlanId');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating subscription: $e');
      return false;
    }
  }

  /// Verify webhook signature from Paddle
  /// Validate webhook authenticity for payment events
  bool verifyWebhookSignature(
    String signature,
    String body,
    String webhookSecret,
  ) {
    try {
      // Implement HMAC-SHA256 verification
      // Paddle sends: X-Paddle-Signature header
      // Body is raw JSON payload
      _logger.i('🔐 Verifying Paddle webhook signature');
      return true; // Implement actual verification
    } catch (e) {
      _logger.e('❌ Webhook verification failed: $e');
      return false;
    }
  }

  /// Get transaction history
  /// Returns all payments/invoices for an org
  Future<List<Map<String, dynamic>>> getTransactionHistory(String orgId) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('paddle_customer_id')
          .eq('id', orgId)
          .maybeSingle();

      if (org == null || org['paddle_customer_id'] == null) {
        return [];
      }

      final customerId = org['paddle_customer_id'];

      final response = await http.get(
        Uri.parse('$PADDLE_API_URL/transactions?customer_id=$customerId'),
        headers: {
          'Authorization': 'Bearer $PADDLE_API_KEY',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch transactions: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final transactions = (data['data'] as List)
          .map((t) => {
                'id': t['id'],
                'amount': t['total']?['amount'],
                'currency': t['total']?['currency'],
                'status': t['status'],
                'created_at': t['billed_at'],
              })
          .toList();

      return transactions;
    } catch (e) {
      _logger.e('❌ Error fetching transactions: $e');
      return [];
    }
  }
}
