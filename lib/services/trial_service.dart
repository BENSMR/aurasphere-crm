import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

class TrialService {
  static final TrialService _instance = TrialService._internal();
  final supabase = Supabase.instance.client;

  factory TrialService() {
    return _instance;
  }

  TrialService._internal();

  /// Check if organization is in active trial
  Future<bool> isOrganizationInTrial(String orgId) async {
    try {
      final response = await supabase.from('organizations').select(
        'is_trial_active, trial_ends_at',
      ).eq('id', orgId).single();

      final isTrialActive = response['is_trial_active'] as bool? ?? false;
      final trialEndsAt = DateTime.parse(response['trial_ends_at'] as String);

      return isTrialActive && trialEndsAt.isAfter(DateTime.now());
    } catch (e) {
      _logger.e('❌ Error checking trial status: $e');
      return false;
    }
  }

  /// Get remaining trial days
  Future<int> getRemainingTrialDays(String orgId) async {
    try {
      final response =
          await supabase.from('organizations').select('trial_ends_at').eq('id', orgId).single();

      final trialEndsAt = DateTime.parse(response['trial_ends_at'] as String);
      final now = DateTime.now();

      if (trialEndsAt.isBefore(now)) {
        return 0;
      }

      return trialEndsAt.difference(now).inDays;
    } catch (e) {
      _logger.e('❌ Error calculating trial days: $e');
      return 0;
    }
  }

  /// Get remaining discount days
  Future<int> getRemainingDiscountDays(String orgId) async {
    try {
      final response = await supabase
          .from('organizations')
          .select('discount_ends_at')
          .eq('id', orgId)
          .single();

      final discountEndsAt = DateTime.parse(response['discount_ends_at'] as String);
      final now = DateTime.now();

      if (discountEndsAt.isBefore(now)) {
        return 0;
      }

      return discountEndsAt.difference(now).inDays;
    } catch (e) {
      _logger.e('❌ Error calculating discount days: $e');
      return 0;
    }
  }

  /// Check if organization has active discount
  Future<bool> hasActiveDiscount(String orgId) async {
    try {
      final response = await supabase
          .from('organizations')
          .select('discount_percentage, discount_ends_at')
          .eq('id', orgId)
          .single();

      final discountPercentage = response['discount_percentage'] as num? ?? 0;
      final discountEndsAt = DateTime.parse(response['discount_ends_at'] as String);

      return discountPercentage > 0 && discountEndsAt.isAfter(DateTime.now());
    } catch (e) {
      _logger.e('❌ Error checking discount: $e');
      return false;
    }
  }

  /// Calculate discounted price
  Future<double> getDiscountedPrice(String orgId, double basePrice) async {
    try {
      final response = await supabase
          .from('organizations')
          .select('discount_percentage, discount_ends_at')
          .eq('id', orgId)
          .single();

      final discountPercentage = response['discount_percentage'] as num? ?? 0;
      final discountEndsAt = DateTime.parse(response['discount_ends_at'] as String);

      if (discountPercentage > 0 && discountEndsAt.isAfter(DateTime.now())) {
        return basePrice * (1 - (discountPercentage / 100));
      }

      return basePrice;
    } catch (e) {
      _logger.e('❌ Error calculating discounted price: $e');
      return basePrice;
    }
  }

  /// Create trial for new organization
  Future<void> createTrial(String orgId, String userId, String planId) async {
    try {
      final trialEndsAt = DateTime.now().add(const Duration(days: 7));
      final discountEndsAt = DateTime.now().add(const Duration(days: 60));

      // Update organization
      await supabase.from('organizations').update({
        'is_trial_active': true,
        'trial_ends_at': trialEndsAt.toIso8601String(),
        'discount_percentage': 50.0,
        'discount_ends_at': discountEndsAt.toIso8601String(),
      }).eq('id', orgId);

      // Create subscription record
      await supabase.from('subscriptions').insert({
        'org_id': orgId,
        'user_id': userId,
        'plan': planId,
        'status': 'trial',
        'trial_started_at': DateTime.now().toIso8601String(),
        'trial_ends_at': trialEndsAt.toIso8601String(),
        'trial_used': false,
        'subscription_started_at': DateTime.now().toIso8601String(),
        'discount_percentage': 50.0,
        'discount_months_remaining': 2,
        'discount_applied_at': DateTime.now().toIso8601String(),
        'discount_ends_at': discountEndsAt.toIso8601String(),
      });

      _logger.i('✅ Trial created for org: $orgId');
    } catch (e) {
      _logger.e('❌ Error creating trial: $e');
      rethrow;
    }
  }

  /// Convert trial to paid subscription
  Future<void> activatePaidSubscription(
    String orgId,
    String stripeCustomerId,
    String stripeSubscriptionId,
  ) async {
    try {
      // Update organization
      await supabase.from('organizations').update({
        'is_trial_active': false,
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
      }).eq('id', orgId);

      // Update subscription
      await supabase.from('subscriptions').update({
        'status': 'active',
        'trial_used': true,
        'stripe_customer_id': stripeCustomerId,
        'stripe_subscription_id': stripeSubscriptionId,
        'subscription_started_at': DateTime.now().toIso8601String(),
        'next_billing_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      }).eq('org_id', orgId);

      _logger.i('✅ Trial converted to paid subscription for org: $orgId');
    } catch (e) {
      _logger.e('❌ Error activating paid subscription: $e');
      rethrow;
    }
  }

  /// Track trial feature usage
  Future<void> trackTrialFeatureUsage(String orgId, String userId, String feature) async {
    try {
      await supabase.from('trial_usage').upsert({
        'org_id': orgId,
        'user_id': userId,
        'feature_accessed': feature,
        'accessed_at': DateTime.now().toIso8601String(),
      });

      _logger.i('✅ Trial feature usage tracked: $feature');
    } catch (e) {
      _logger.w('⚠️ Could not track trial usage: $e');
      // Don't throw - this is not critical
    }
  }

  /// Send trial ending reminder
  Future<void> sendTrialReminder(String orgId, String userId, String reminderType) async {
    try {
      await supabase.from('trial_reminders').upsert({
        'org_id': orgId,
        'user_id': userId,
        'reminder_type': reminderType,
        'sent_at': DateTime.now().toIso8601String(),
      });

      _logger.i('✅ Trial reminder sent: $reminderType');
    } catch (e) {
      _logger.w('⚠️ Could not send trial reminder: $e');
    }
  }

  /// Get organization subscription details
  Future<Map<String, dynamic>?> getSubscriptionDetails(String orgId) async {
    try {
      final response = await supabase.from('subscriptions').select(
        '*',
      ).eq('org_id', orgId).maybeSingle();

      return response;
    } catch (e) {
      _logger.e('❌ Error fetching subscription details: $e');
      return null;
    }
  }

  /// Check if user should see trial warning
  Future<bool> shouldShowTrialWarning(String orgId) async {
    try {
      final remainingDays = await getRemainingTrialDays(orgId);

      // Show warning when 1 day or less remains
      return remainingDays <= 1 && remainingDays > 0;
    } catch (e) {
      _logger.e('❌ Error checking trial warning: $e');
      return false;
    }
  }

  /// End trial (without payment)
  Future<void> endTrial(String orgId) async {
    try {
      await supabase.from('organizations').update({
        'is_trial_active': false,
      }).eq('id', orgId);

      await supabase.from('subscriptions').update({
        'status': 'cancelled',
      }).eq('org_id', orgId).eq('status', 'trial');

      _logger.i('✅ Trial ended for org: $orgId');
    } catch (e) {
      _logger.e('❌ Error ending trial: $e');
      rethrow;
    }
  }
}
