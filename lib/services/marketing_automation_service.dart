import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Marketing Automation & Flow Service
/// Automates marketing campaigns, lead nurturing, email flows, and customer engagement
class MarketingAutomationService {
  static final MarketingAutomationService _instance = MarketingAutomationService._internal();
  
  final supabase = Supabase.instance.client;

  MarketingAutomationService._internal();

  factory MarketingAutomationService() {
    return _instance;
  }

  /// Create automated email flow for new customers
  /// Flow: Welcome → Value prop → Testimonial → Upgrade offer
  Future<Map<String, dynamic>> createNewCustomerWelcomeFlow({
    required String orgId,
    required String clientEmail,
    required String clientName,
  }) async {
    try {
      _logger.i('📧 Creating welcome flow for: $clientEmail');

      final flowData = {
        'org_id': orgId,
        'type': 'welcome_sequence',
        'client_email': clientEmail,
        'client_name': clientName,
        'status': 'active',
        'emails_sent': 0,
        'created_at': DateTime.now().toIso8601String(),
        'steps': [
          {
            'day': 0,
            'subject': 'Welcome to AuraSphere! 🚀',
            'content': 'Hi $clientName,\n\nThanks for joining! Your job management is about to get easier.',
            'sent': false,
          },
          {
            'day': 2,
            'subject': 'Here\'s what you can do with AuraSphere',
            'content': 'Track jobs, manage invoices, dispatch teams - all in one place.',
            'sent': false,
          },
          {
            'day': 4,
            'subject': 'See how others are saving time',
            'content': 'Real success stories from trades professionals like you.',
            'sent': false,
          },
          {
            'day': 7,
            'subject': 'Ready to upgrade? Get more features',
            'content': 'Unlock advanced features at a special intro rate.',
            'sent': false,
          },
        ],
      };

      // Store in database
      await supabase
          .from('marketing_flows')
          .insert(flowData);

      _logger.i('✅ Welcome flow created for: $clientEmail');

      return {
        'flow_id': '${orgId}_$clientEmail',
        'type': 'welcome_sequence',
        'status': 'active',
        'total_emails': 4,
        'first_email_scheduled': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('❌ Welcome flow error: $e');
      return {'error': e.toString()};
    }
  }

  /// Create automated re-engagement flow for inactive clients
  Future<Map<String, dynamic>> createReEngagementFlow({
    required String orgId,
    required String clientEmail,
    required String lastActivityDaysAgo,
  }) async {
    try {
      _logger.i('🔄 Creating re-engagement flow for inactive client: $clientEmail');

      final flowData = {
        'org_id': orgId,
        'type': 're_engagement',
        'client_email': clientEmail,
        'last_activity_days_ago': int.parse(lastActivityDaysAgo),
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'steps': [
          {
            'day': 0,
            'subject': 'We miss you! 👋',
            'content': 'You haven\'t used AuraSphere in $lastActivityDaysAgo days. Let us know if we can help!',
            'sent': false,
          },
          {
            'day': 3,
            'subject': 'Quick tip to boost your productivity',
            'content': 'Here\'s a feature you might have missed that saves hours per week.',
            'sent': false,
          },
          {
            'day': 7,
            'subject': 'Special offer just for you',
            'content': 'Get 20% off your next month - valid only through this week.',
            'sent': false,
          },
        ],
      };

      await supabase
          .from('marketing_flows')
          .insert(flowData);

      _logger.i('✅ Re-engagement flow created');

      return {
        'flow_type': 're_engagement',
        'status': 'active',
        'emails_scheduled': 3,
      };
    } catch (e) {
      _logger.e('❌ Re-engagement flow error: $e');
      return {'error': e.toString()};
    }
  }

  /// Create upsell/cross-sell flow for existing customers
  Future<Map<String, dynamic>> createUpsellFlow({
    required String orgId,
    required String clientEmail,
    required String currentPlan,
  }) async {
    try {
      _logger.i('💰 Creating upsell flow for: $clientEmail (current plan: $currentPlan)');

      String targetPlan = currentPlan == 'solo_trades' ? 'small_team' : 'workshop';
      String targetPrice = currentPlan == 'solo_trades' ? '\$20' : '\$49';
      String benefit = currentPlan == 'solo_trades'
          ? 'Add up to 3 team members and 4x more jobs'
          : 'Get unlimited jobs and premium integrations';

      final flowData = {
        'org_id': orgId,
        'type': 'upsell',
        'client_email': clientEmail,
        'from_plan': currentPlan,
        'to_plan': targetPlan,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'steps': [
          {
            'day': 0,
            'subject': 'Your business is growing! 📈',
            'content': 'We noticed you\'re hitting your plan limits. Time to upgrade?',
            'sent': false,
          },
          {
            'day': 3,
            'subject': 'Unlock $targetPrice/month - $benefit',
            'content': 'Your business deserves better tools. See what you\'re missing.',
            'sent': false,
          },
          {
            'day': 7,
            'subject': 'Limited time: Upgrade and save 20%',
            'content': 'Exclusive offer for valued customers - expires soon!',
            'sent': false,
          },
        ],
      };

      await supabase
          .from('marketing_flows')
          .insert(flowData);

      _logger.i('✅ Upsell flow created');

      return {
        'flow_type': 'upsell',
        'current_plan': currentPlan,
        'target_plan': targetPlan,
        'potential_increase': targetPrice,
        'emails_scheduled': 3,
      };
    } catch (e) {
      _logger.e('❌ Upsell flow error: $e');
      return {'error': e.toString()};
    }
  }

  /// Get all active marketing flows
  Future<List<Map<String, dynamic>>> getAllActiveFlows({
    required String orgId,
  }) async {
    try {
      _logger.i('📊 Fetching all active flows for org: $orgId');

      final flows = await supabase
          .from('marketing_flows')
          .select('*')
          .eq('org_id', orgId)
          .eq('status', 'active');

      _logger.i('✅ Found ${flows.length} active flows');

      return List<Map<String, dynamic>>.from(flows);
    } catch (e) {
      _logger.e('❌ Error fetching flows: $e');
      return [];
    }
  }

  /// Track email engagement (opens, clicks)
  Future<void> trackEmailEngagement({
    required String flowId,
    required int emailIndex,
    required String eventType, // 'sent', 'opened', 'clicked'
  }) async {
    try {
      _logger.i('📊 Tracking event: $eventType for flow: $flowId');

      await supabase
          .from('email_engagement')
          .insert({
            'flow_id': flowId,
            'email_index': emailIndex,
            'event_type': eventType,
            'timestamp': DateTime.now().toIso8601String(),
          });

      _logger.i('✅ Event tracked');
    } catch (e) {
      _logger.e('❌ Engagement tracking error: $e');
    }
  }

  /// Get marketing performance analytics
  Future<Map<String, dynamic>> getMarketingAnalytics({
    required String orgId,
  }) async {
    try {
      _logger.i('📈 Generating marketing analytics for org: $orgId');

      final flows = await supabase
          .from('marketing_flows')
          .select('*')
          .eq('org_id', orgId);

      final engagement = await supabase
          .from('email_engagement')
          .select('*')
          .inFilter('flow_id', flows.map((f) => f['id']).toList());

      int totalEmailsSent = 0;
      int totalOpens = 0;
      int totalClicks = 0;

      for (var event in engagement) {
        if (event['event_type'] == 'sent') totalEmailsSent++;
        if (event['event_type'] == 'opened') totalOpens++;
        if (event['event_type'] == 'clicked') totalClicks++;
      }

      double openRate = totalEmailsSent > 0 ? (totalOpens / totalEmailsSent) * 100 : 0;
      double clickRate = totalOpens > 0 ? (totalClicks / totalOpens) * 100 : 0;

      _logger.i('✅ Analytics generated');

      return {
        'total_flows': flows.length,
        'active_flows': flows.where((f) => f['status'] == 'active').length,
        'total_emails_sent': totalEmailsSent,
        'total_opens': totalOpens,
        'total_clicks': totalClicks,
        'open_rate_percent': openRate.toStringAsFixed(2),
        'click_rate_percent': clickRate.toStringAsFixed(2),
        'engagement_quality': openRate > 30 ? 'Excellent' : openRate > 15 ? 'Good' : 'Needs Improvement',
      };
    } catch (e) {
      _logger.e('❌ Analytics error: $e');
      return {'error': e.toString()};
    }
  }

  /// Auto-generate personalized SMS campaigns
  Future<Map<String, dynamic>> generateSMSCampaign({
    required String orgId,
    required String clientPhone,
    required String campaignType, // 'invoice_reminder', 'payment_thanks', 'special_offer'
  }) async {
    try {
      _logger.i('📱 Generating SMS campaign: $campaignType');

      String message = '';
      switch (campaignType) {
        case 'invoice_reminder':
          message = 'Hi! Your invoice is due tomorrow. View & pay: [link]';
          break;
        case 'payment_thanks':
          message = 'Thank you for your payment! New job available. Check it out: [link]';
          break;
        case 'special_offer':
          message = 'Special offer: Upgrade your plan & save 20%. Valid 7 days: [link]';
          break;
        default:
          message = 'Hi from AuraSphere!';
      }

      await supabase
          .from('sms_campaigns')
          .insert({
            'org_id': orgId,
            'phone': clientPhone,
            'campaign_type': campaignType,
            'message': message,
            'status': 'scheduled',
            'scheduled_at': DateTime.now().toIso8601String(),
          });

      _logger.i('✅ SMS campaign created');

      return {
        'campaign_type': campaignType,
        'phone': clientPhone,
        'message': message,
        'status': 'scheduled',
      };
    } catch (e) {
      _logger.e('❌ SMS campaign error: $e');
      return {'error': e.toString()};
    }
  }
}
