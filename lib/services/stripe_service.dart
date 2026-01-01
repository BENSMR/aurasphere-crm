import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final _logger = Logger();

/// Stripe Payment Integration Service
/// Handles subscription billing, invoice payments, and payment intents
class StripeService {
  static final StripeService _instance = StripeService._internal();
  
  // Replace with your actual Stripe keys
  static const String STRIPE_PUBLISHABLE_KEY = 'pk_test_YOUR_PUBLISHABLE_KEY';
  static const String STRIPE_SECRET_KEY = 'sk_test_YOUR_SECRET_KEY';
  static const String STRIPE_API_URL = 'https://api.stripe.com/v1';

  final supabase = Supabase.instance.client;

  StripeService._internal();

  factory StripeService() {
    return _instance;
  }

  /// Create subscription for organization
  /// Plans: 'price_solo' ($9.99/month), 'price_team' ($20/month), 'price_workshop' ($49/month)
  Future<Map<String, dynamic>> createSubscription({
    required String orgId,
    required String planPriceId,
    required String customerEmail,
  }) async {
    try {
      _logger.i('💳 Creating subscription for org: $orgId, plan: $planPriceId');

      // Create Stripe customer
      final customerResponse = await http.post(
        Uri.parse('$STRIPE_API_URL/customers'),
        headers: {
          'Authorization': 'Bearer $STRIPE_SECRET_KEY',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': customerEmail,
          'metadata[org_id]': orgId,
        },
      );

      if (customerResponse.statusCode != 200) {
        throw Exception('Failed to create Stripe customer: ${customerResponse.body}');
      }

      final customerData = jsonDecode(customerResponse.body);
      final stripeCustomerId = customerData['id'];

      // Store Stripe customer ID in org
      await supabase
          .from('organizations')
          .update({'stripe_customer_id': stripeCustomerId})
          .eq('id', orgId);

      // Create subscription
      final subscriptionResponse = await http.post(
        Uri.parse('$STRIPE_API_URL/subscriptions'),
        headers: {
          'Authorization': 'Bearer $STRIPE_SECRET_KEY',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': stripeCustomerId,
          'items[0][price]': planPriceId,
          'payment_behavior': 'default_incomplete',
          'expand[]': 'latest_invoice.payment_intent',
        },
      );

      if (subscriptionResponse.statusCode != 200) {
        throw Exception('Failed to create subscription: ${subscriptionResponse.body}');
      }

      final subscriptionData = jsonDecode(subscriptionResponse.body);
      final subscriptionId = subscriptionData['id'];

      // Store subscription info
      await supabase
          .from('organizations')
          .update({
            'stripe_subscription_id': subscriptionId,
            'stripe_status': subscriptionData['status'],
          })
          .eq('id', orgId);

      _logger.i('✅ Subscription created: $subscriptionId');

      return {
        'subscription_id': subscriptionId,
        'customer_id': stripeCustomerId,
        'status': subscriptionData['status'],
        'client_secret': subscriptionData['latest_invoice']?['payment_intent']?['client_secret'],
      };
    } catch (e) {
      _logger.e('❌ Error creating subscription: $e');
      rethrow;
    }
  }

  /// Create payment intent for invoice payment
  Future<Map<String, dynamic>> createPaymentIntent({
    required String invoiceId,
    required double amount,
    required String orgId,
  }) async {
    try {
      _logger.i('💰 Creating payment intent for invoice: $invoiceId, amount: \$$amount');

      // Get organization's Stripe customer ID
      final org = await supabase
          .from('organizations')
          .select('stripe_customer_id')
          .eq('id', orgId)
          .single();

      final stripeCustomerId = org['stripe_customer_id'] as String?;
      if (stripeCustomerId == null) {
        throw Exception('Organization does not have Stripe customer ID');
      }

      // Create payment intent
      final response = await http.post(
        Uri.parse('$STRIPE_API_URL/payment_intents'),
        headers: {
          'Authorization': 'Bearer $STRIPE_SECRET_KEY',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (amount * 100).toInt().toString(), // Convert to cents
          'currency': 'usd',
          'customer': stripeCustomerId,
          'metadata[invoice_id]': invoiceId,
          'metadata[org_id]': orgId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }

      final paymentData = jsonDecode(response.body);
      final clientSecret = paymentData['client_secret'];

      _logger.i('✅ Payment intent created: ${paymentData['id']}');

      return {
        'payment_intent_id': paymentData['id'],
        'client_secret': clientSecret,
        'status': paymentData['status'],
        'amount': amount,
      };
    } catch (e) {
      _logger.e('❌ Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Confirm payment (webhook from Stripe)
  Future<void> confirmInvoicePayment({
    required String invoiceId,
    required String paymentIntentId,
    required String status,
  }) async {
    try {
      if (status == 'succeeded') {
        _logger.i('✅ Payment confirmed for invoice: $invoiceId');

        // Update invoice status
        await supabase
            .from('invoices')
            .update({
              'status': 'paid',
              'paid_at': DateTime.now().toIso8601String(),
              'stripe_payment_intent_id': paymentIntentId,
            })
            .eq('id', invoiceId);

        // Log payment
        await supabase.from('payment_logs').insert({
          'invoice_id': invoiceId,
          'payment_intent_id': paymentIntentId,
          'status': 'succeeded',
          'processed_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      _logger.e('❌ Error confirming payment: $e');
      rethrow;
    }
  }

  /// Update subscription plan
  Future<Map<String, dynamic>> updateSubscriptionPlan({
    required String orgId,
    required String newPlanPriceId,
  }) async {
    try {
      _logger.i('🔄 Updating subscription plan for org: $orgId');

      // Get current subscription
      final org = await supabase
          .from('organizations')
          .select('stripe_subscription_id')
          .eq('id', orgId)
          .single();

      final subscriptionId = org['stripe_subscription_id'] as String?;
      if (subscriptionId == null) {
        throw Exception('No active subscription found');
      }

      // Get subscription details to update items
      final getSubResponse = await http.get(
        Uri.parse('$STRIPE_API_URL/subscriptions/$subscriptionId'),
        headers: {'Authorization': 'Bearer $STRIPE_SECRET_KEY'},
      );

      final subData = jsonDecode(getSubResponse.body);
      final itemId = subData['items']['data'][0]['id'];

      // Update subscription item
      final updateResponse = await http.post(
        Uri.parse('$STRIPE_API_URL/subscription_items/$itemId'),
        headers: {
          'Authorization': 'Bearer $STRIPE_SECRET_KEY',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'price': newPlanPriceId,
          'proration_behavior': 'create_prorations',
        },
      );

      if (updateResponse.statusCode == 200) {
        _logger.i('✅ Subscription plan updated');
        return {'status': 'success', 'subscription_id': subscriptionId};
      } else {
        throw Exception('Failed to update subscription: ${updateResponse.body}');
      }
    } catch (e) {
      _logger.e('❌ Error updating subscription plan: $e');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription({required String orgId}) async {
    try {
      _logger.i('❌ Cancelling subscription for org: $orgId');

      final org = await supabase
          .from('organizations')
          .select('stripe_subscription_id')
          .eq('id', orgId)
          .single();

      final subscriptionId = org['stripe_subscription_id'] as String?;
      if (subscriptionId == null) return;

      final response = await http.delete(
        Uri.parse('$STRIPE_API_URL/subscriptions/$subscriptionId'),
        headers: {'Authorization': 'Bearer $STRIPE_SECRET_KEY'},
      );

      if (response.statusCode == 200) {
        // Update org status
        await supabase
            .from('organizations')
            .update({'stripe_status': 'cancelled'})
            .eq('id', orgId);

        _logger.i('✅ Subscription cancelled');
      }
    } catch (e) {
      _logger.e('❌ Error cancelling subscription: $e');
      rethrow;
    }
  }

  /// Get subscription details
  Future<Map<String, dynamic>> getSubscriptionDetails({
    required String orgId,
  }) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('stripe_subscription_id, stripe_status')
          .eq('id', orgId)
          .single();

      final subscriptionId = org['stripe_subscription_id'] as String?;
      if (subscriptionId == null) {
        return {'status': 'no_subscription'};
      }

      final response = await http.get(
        Uri.parse('$STRIPE_API_URL/subscriptions/$subscriptionId'),
        headers: {'Authorization': 'Bearer $STRIPE_SECRET_KEY'},
      );

      final subData = jsonDecode(response.body);

      return {
        'subscription_id': subscriptionId,
        'status': subData['status'],
        'current_period_start': subData['current_period_start'],
        'current_period_end': subData['current_period_end'],
        'cancel_at_period_end': subData['cancel_at_period_end'],
        'plan_id': subData['items']['data'][0]['price']['id'],
        'amount_per_cycle': (subData['items']['data'][0]['price']['unit_amount'] / 100).toStringAsFixed(2),
      };
    } catch (e) {
      _logger.e('❌ Error getting subscription details: $e');
      rethrow;
    }
  }
}
