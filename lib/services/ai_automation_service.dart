// lib/services/ai_automation_service.dart
/// 🤖 AI Automation & Cost Control Service
/// Manages: automation enablement, proactivity levels, usage tracking, cost limits
/// Features: per-agent control, organization-wide quotas, abuse prevention, real-time alerts
/// Plan-based limits: Solo=$2/month, Team=$4/month, Workshop=$6/month
library;


import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

class AIAutomationService {
  static final AIAutomationService _instance = AIAutomationService._internal();
  
  final supabase = Supabase.instance.client;

  AIAutomationService._internal();

  factory AIAutomationService() {
    return _instance;
  }

  // ==================== PLAN-BASED COST LIMITS ====================
  
  /// Get monthly cost limit based on subscription plan
  /// - Solo: $2/month
  /// - Team: $4/month
  /// - Workshop: $6/month
  /// - Trial/Free: $2/month (same as Solo)
  double getPlanCostLimit(String plan) {
    switch (plan.toLowerCase()) {
      case 'solo':
        return 2.0;
      case 'team':
        return 4.0;
      case 'workshop':
        return 6.0;
      case 'trial':
      case 'free':
        return 2.0;
      default:
        return 2.0; // Default to Solo pricing
    }
  }

  /// Get API call limit based on plan
  /// - Solo: 500 calls/month
  /// - Team: 1000 calls/month
  /// - Workshop: 1500 calls/month
  /// - Trial/Free: 500 calls/month
  int getPlanApiCallLimit(String plan) {
    switch (plan.toLowerCase()) {
      case 'solo':
        return 500;
      case 'team':
        return 1000;
      case 'workshop':
        return 1500;
      case 'trial':
      case 'free':
        return 500;
      default:
        return 500;
    }
  }

  // ==================== AUTOMATION SETTINGS ====================

  /// Get automation settings for an organization
  /// Returns: {automation_enabled, proactivity_level, agents: {...}}
  Future<Map<String, dynamic>> getAutomationSettings(String orgId) async {
    try {
      final settings = await supabase
          .from('ai_automation_settings')
          .select('*')
          .eq('org_id', orgId)
          .maybeSingle();

      if (settings == null) {
        // Create default settings if not exists
        return await _createDefaultSettings(orgId);
      }

      return settings;
    } catch (e) {
      _logger.e('❌ Error fetching automation settings: $e');
      return {};
    }
  }

  /// Create default automation settings
  Future<Map<String, dynamic>> _createDefaultSettings(String orgId) async {
    try {
      // Fetch organization plan
      final org = await supabase
          .from('organizations')
          .select('plan')
          .eq('id', orgId)
          .maybeSingle();
      
      final plan = org?['plan'] as String? ?? 'solo';
      final monthlyCostLimit = getPlanCostLimit(plan);
      final monthlyApiLimit = getPlanApiCallLimit(plan);

      final defaults = {
        'org_id': orgId,
        'automation_enabled': true,
        'proactivity_level': 'balanced', // 'conservative', 'balanced', 'aggressive'
        'agents': {
          'cfo': {'enabled': true, 'proactive': true, 'api_calls_limit': (monthlyApiLimit * 0.25).toInt()},
          'ceo': {'enabled': true, 'proactive': true, 'api_calls_limit': (monthlyApiLimit * 0.20).toInt()},
          'marketing': {'enabled': true, 'proactive': false, 'api_calls_limit': (monthlyApiLimit * 0.15).toInt()},
          'sales': {'enabled': true, 'proactive': false, 'api_calls_limit': (monthlyApiLimit * 0.20).toInt()},
          'admin': {'enabled': false, 'proactive': false, 'api_calls_limit': (monthlyApiLimit * 0.10).toInt()},
        },
        'monthly_api_limit': monthlyApiLimit,
        'monthly_cost_limit': monthlyCostLimit,
        'plan': plan,
        'cost_alert_threshold': 0.8, // Alert at 80% of limit
        'auto_pause_on_limit': true, // Auto-stop agents when limit reached
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('ai_automation_settings').insert(defaults);
      
      _logger.i('✅ Created automation settings for $plan plan (limit: \$$monthlyCostLimit/month)');
      return defaults;
    } catch (e) {
      _logger.e('❌ Error creating default settings: $e');
      return {};
    }
  }

  /// Update automation enabled/disabled
  Future<bool> setAutomationEnabled(String orgId, bool enabled) async {
    try {
      await supabase
          .from('ai_automation_settings')
          .update({'automation_enabled': enabled})
          .eq('org_id', orgId);
      
      _logger.i('✅ Automation ${enabled ? 'ENABLED' : 'DISABLED'} for org: $orgId');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating automation: $e');
      return false;
    }
  }

  /// Update proactivity level (conservative/balanced/aggressive)
  Future<bool> setProactivityLevel(String orgId, String level) async {
    if (!['conservative', 'balanced', 'aggressive'].contains(level)) {
      _logger.w('⚠️ Invalid proactivity level: $level');
      return false;
    }

    try {
      await supabase
          .from('ai_automation_settings')
          .update({'proactivity_level': level})
          .eq('org_id', orgId);
      
      _logger.i('✅ Proactivity level set to: $level');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating proactivity level: $e');
      return false;
    }
  }

  /// Enable/disable specific agent
  Future<bool> setAgentEnabled(String orgId, String agent, bool enabled) async {
    try {
      final settings = await getAutomationSettings(orgId);
      settings['agents'][agent]['enabled'] = enabled;

      await supabase
          .from('ai_automation_settings')
          .update({'agents': settings['agents']})
          .eq('org_id', orgId);
      
      _logger.i('✅ Agent $agent ${enabled ? 'ENABLED' : 'DISABLED'}');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating agent: $e');
      return false;
    }
  }

  /// Set proactivity for specific agent
  Future<bool> setAgentProactive(String orgId, String agent, bool proactive) async {
    try {
      final settings = await getAutomationSettings(orgId);
      settings['agents'][agent]['proactive'] = proactive;

      await supabase
          .from('ai_automation_settings')
          .update({'agents': settings['agents']})
          .eq('org_id', orgId);
      
      _logger.i('✅ Agent $agent proactivity set to: $proactive');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating agent proactivity: $e');
      return false;
    }
  }

  // ==================== USAGE TRACKING ====================

  /// Log API call for usage tracking
  Future<void> logApiCall({
    required String orgId,
    required String agentName,
    required String action,
    required int tokensUsed,
    required double estimatedCost,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      
      await supabase.from('ai_usage_log').insert({
        'org_id': orgId,
        'user_id': userId,
        'agent_name': agentName,
        'action': action,
        'tokens_used': tokensUsed,
        'estimated_cost': estimatedCost,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('📊 API call logged: $agentName - $action ($tokensUsed tokens)');
    } catch (e) {
      _logger.e('❌ Error logging API call: $e');
    }
  }

  /// Get current month's usage for organization
  Future<Map<String, dynamic>> getCurrentMonthUsage(String orgId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

      final logs = await supabase
          .from('ai_usage_log')
          .select('tokens_used, estimated_cost, agent_name')
          .eq('org_id', orgId)
          .gte('timestamp', monthStart);

      int totalTokens = 0;
      double totalCost = 0.0;
      final agentBreakdown = <String, Map<String, dynamic>>{};

      for (var log in logs) {
        totalTokens += log['tokens_used'] as int? ?? 0;
        totalCost += log['estimated_cost'] as double? ?? 0.0;

        final agent = log['agent_name'] as String? ?? 'unknown';
        if (!agentBreakdown.containsKey(agent)) {
          agentBreakdown[agent] = {'tokens': 0, 'cost': 0.0, 'count': 0};
        }
        agentBreakdown[agent]?['tokens'] = (agentBreakdown[agent]?['tokens'] as int? ?? 0) + (log['tokens_used'] as int? ?? 0);
        agentBreakdown[agent]?['cost'] = (agentBreakdown[agent]?['cost'] as double? ?? 0.0) + (log['estimated_cost'] as double? ?? 0.0);
        agentBreakdown[agent]?['count'] = (agentBreakdown[agent]?['count'] as int? ?? 0) + 1;
      }

      return {
        'total_tokens': totalTokens,
        'total_cost': totalCost,
        'api_calls': logs.length,
        'breakdown': agentBreakdown,
      };
    } catch (e) {
      _logger.e('❌ Error fetching usage: $e');
      return {'total_tokens': 0, 'total_cost': 0.0, 'api_calls': 0};
    }
  }

  // ==================== QUOTA & LIMIT ENFORCEMENT ====================

  /// Check if API call is allowed (respects quotas)
  /// Returns: {allowed: bool, reason: String, usage: Map}
  Future<Map<String, dynamic>> checkCallAllowed({
    required String orgId,
    required String agentName,
  }) async {
    try {
      final settings = await getAutomationSettings(orgId);

      // Check if automation is enabled
      if (!settings['automation_enabled']) {
        return {
          'allowed': false,
          'reason': '⚠️ Automation is disabled for this organization',
        };
      }

      // Check if agent is enabled
      if (!settings['agents'][agentName]['enabled']) {
        return {
          'allowed': false,
          'reason': '⚠️ Agent $agentName is disabled',
        };
      }

      // Get organization plan for limit enforcement
      final org = await supabase
          .from('organizations')
          .select('plan')
          .eq('id', orgId)
          .maybeSingle();
      
      final plan = org?['plan'] as String? ?? 'solo';
      
      // Use plan-based limits instead of settings
      final planCostLimit = getPlanCostLimit(plan);
      final planApiLimit = getPlanApiCallLimit(plan);

      // Get current usage
      final usage = await getCurrentMonthUsage(orgId);
      final totalCost = usage['total_cost'] as double;
      final totalApiCalls = usage['total_calls'] as int? ?? 0;

      // Check cost limit (plan-based)
      if (totalCost >= planCostLimit) {
        if (settings['auto_pause_on_limit'] as bool? ?? true) {
          await setAutomationEnabled(orgId, false);
          return {
            'allowed': false,
            'reason': '💰 ${plan.toUpperCase()} plan cost limit (\$${planCostLimit.toStringAsFixed(2)}/month) reached. Automation paused.',
            'usage': usage,
          };
        }
      }

      // Check API call limit (plan-based)
      if (totalApiCalls >= planApiLimit) {
        if (settings['auto_pause_on_limit'] as bool? ?? true) {
          await setAutomationEnabled(orgId, false);
          return {
            'allowed': false,
            'reason': '📞 ${plan.toUpperCase()} plan API call limit ($planApiLimit/month) reached. Automation paused.',
            'usage': usage,
          };
        }
      }

      // Check cost alert threshold (80%)
      final threshold = planCostLimit * (settings['cost_alert_threshold'] as double? ?? 0.8);
      if (totalCost >= threshold) {
        final percentUsed = (totalCost / planCostLimit * 100).toStringAsFixed(1);
        _logger.w('⚠️ COST ALERT: $percentUsed% of ${plan.toUpperCase()} plan limit used (\$${totalCost.toStringAsFixed(2)}/\$${planCostLimit.toStringAsFixed(2)})');
      }

      return {
        'allowed': true,
        'reason': 'OK',
        'usage': usage,
        'plan': plan,
        'limit': planCostLimit,
      };
    } catch (e) {
      _logger.e('❌ Error checking call allowed: $e');
      return {'allowed': false, 'reason': '❌ Error checking quotas: $e'};
    }
  }

  /// Set monthly API call limit
  Future<bool> setMonthlyApiLimit(String orgId, int limit) async {
    try {
      await supabase
          .from('ai_automation_settings')
          .update({'monthly_api_limit': limit})
          .eq('org_id', orgId);
      
      _logger.i('✅ Monthly API limit set to: $limit');
      return true;
    } catch (e) {
      _logger.e('❌ Error setting API limit: $e');
      return false;
    }
  }

  /// Set monthly cost limit in USD
  Future<bool> setMonthlyCostLimit(String orgId, double limit) async {
    try {
      await supabase
          .from('ai_automation_settings')
          .update({'monthly_cost_limit': limit})
          .eq('org_id', orgId);
      
      _logger.i('✅ Monthly cost limit set to: \$$limit');
      return true;
    } catch (e) {
      _logger.e('❌ Error setting cost limit: $e');
      return false;
    }
  }

  /// Enable/disable auto-pause when limit is reached
  Future<bool> setAutoPauseOnLimit(String orgId, bool enabled) async {
    try {
      await supabase
          .from('ai_automation_settings')
          .update({'auto_pause_on_limit': enabled})
          .eq('org_id', orgId);
      
      _logger.i('✅ Auto-pause on limit: ${enabled ? 'ENABLED' : 'DISABLED'}');
      return true;
    } catch (e) {
      _logger.e('❌ Error updating auto-pause: $e');
      return false;
    }
  }

  // ==================== ESTIMATE & COST CALCULATION ====================

  /// Estimate cost for API call (Groq pricing)
  /// Input: ~$0.05 per 1M tokens, Output: ~$0.15 per 1M tokens
  double estimateApiCost({
    required int inputTokens,
    required int outputTokens,
  }) {
    const inputCostPer1M = 0.05;
    const outputCostPer1M = 0.15;

    final inputCost = (inputTokens / 1000000) * inputCostPer1M;
    final outputCost = (outputTokens / 1000000) * outputCostPer1M;
    
    return inputCost + outputCost;
  }

  /// Get remaining budget for current month
  Future<Map<String, dynamic>> getRemainingBudget(String orgId) async {
    try {
      final settings = await getAutomationSettings(orgId);
      final usage = await getCurrentMonthUsage(orgId);

      final monthlyCostLimit = settings['monthly_cost_limit'] as double? ?? 100.0;
      final currentCost = usage['total_cost'] as double? ?? 0.0;
      final remaining = monthlyCostLimit - currentCost;
      final percentUsed = (currentCost / monthlyCostLimit * 100);

      return {
        'limit': monthlyCostLimit,
        'used': currentCost,
        'remaining': remaining,
        'percent_used': percentUsed,
        'status': remaining <= 0
            ? '🚫 LIMIT_REACHED'
            : percentUsed > 90
                ? '🔴 CRITICAL'
                : percentUsed > 80
                    ? '🟠 WARNING'
                    : '🟢 OK',
      };
    } catch (e) {
      _logger.e('❌ Error getting remaining budget: $e');
      return {
        'limit': 0,
        'used': 0,
        'remaining': 0,
        'percent_used': 0,
        'status': '❌ ERROR',
      };
    }
  }

  // ==================== ANALYTICS & REPORTING ====================

  /// Get agent usage breakdown
  Future<Map<String, dynamic>> getAgentBreakdown(String orgId) async {
    try {
      final usage = await getCurrentMonthUsage(orgId);
      return usage['breakdown'] ?? {};
    } catch (e) {
      _logger.e('❌ Error getting agent breakdown: $e');
      return {};
    }
  }

  /// Get usage trend (last 7 days)
  Future<List<Map<String, dynamic>>> getUsageTrend(String orgId, {int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days)).toIso8601String();

      final logs = await supabase
          .from('ai_usage_log')
          .select('timestamp, estimated_cost')
          .eq('org_id', orgId)
          .gte('timestamp', startDate);

      // Group by day
      final dailyUsage = <String, double>{};
      for (var log in logs) {
        final date = log['timestamp'].split('T')[0];
        dailyUsage[date] = (dailyUsage[date] ?? 0.0) + log['estimated_cost'];
      }

      return dailyUsage.entries
          .map((e) => {'date': e.key, 'cost': e.value})
          .toList();
    } catch (e) {
      _logger.e('❌ Error fetching usage trend: $e');
      return [];
    }
  }
}
