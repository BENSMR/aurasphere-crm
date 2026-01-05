// lib/ai_automation_settings_page.dart
/// 🤖 AI Automation & Cost Control Settings Page
/// User controls: enable/disable automation, set proactivity level, manage costs/limits
library;


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/ai_automation_service.dart';

class AIAutomationSettingsPage extends StatefulWidget {
  const AIAutomationSettingsPage({super.key});

  @override
  State<AIAutomationSettingsPage> createState() => _AIAutomationSettingsPageState();
}

class _AIAutomationSettingsPageState extends State<AIAutomationSettingsPage> {
  final supabase = Supabase.instance.client;
  final automationService = AIAutomationService();
  
  late String orgId;
  late Map<String, dynamic> settings;
  late Map<String, dynamic> usage;
  late Map<String, dynamic> budget;
  
  bool loading = true;
  String? selectedProactivityLevel;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      final org = await supabase.from('organizations').select('id, plan').single();
      orgId = org['id'];

      settings = await automationService.getAutomationSettings(orgId);
      usage = await automationService.getCurrentMonthUsage(orgId);
      
      // Fetch plan-based limits
      final plan = org['plan'] as String? ?? 'solo';
      final planLimit = automationService.getPlanCostLimit(plan);
      final planApiLimit = automationService.getPlanApiCallLimit(plan);
      
      budget = await automationService.getRemainingBudget(orgId);
      budget['limit'] = planLimit; // Override with plan limit
      budget['plan'] = plan;
      budget['api_limit'] = planApiLimit;
      
      selectedProactivityLevel = settings['proactivity_level'] ?? 'balanced';

      if (mounted) setState(() => loading = false);
    } catch (e) {
      print('❌ Error initializing: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Automation Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================== MAIN TOGGLE ====================
                  _buildMainAutomationToggle(),
                  const SizedBox(height: 24),

                  // ==================== COST & BUDGET ====================
                  _buildBudgetSection(),
                  const SizedBox(height: 24),

                  // ==================== PROACTIVITY LEVEL ====================
                  _buildProactivityControl(),
                  const SizedBox(height: 24),

                  // ==================== AGENT CONTROLS ====================
                  _buildAgentControls(),
                  const SizedBox(height: 24),

                  // ==================== USAGE ANALYTICS ====================
                  _buildUsageAnalytics(),
                  const SizedBox(height: 24),

                  // ==================== COST LIMITS ====================
                  _buildCostLimits(),
                ],
              ),
            ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildMainAutomationToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚙️ Automation Master Control',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: settings['automation_enabled'] ?? true,
                  onChanged: (val) async {
                    await automationService.setAutomationEnabled(orgId, val);
                    await _refreshData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              settings['automation_enabled'] == true
                  ? '✅ Automation is ACTIVE - AI agents can run automatically'
                  : '⏸️ Automation is PAUSED - AI agents disabled',
              style: TextStyle(
                color: settings['automation_enabled'] == true
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    final status = budget['status'] ?? '❓';
    final percentUsed = budget['percent_used'] as double? ?? 0;
    final used = budget['used'] as double? ?? 0;
    final limit = budget['limit'] as double? ?? 100;
    final plan = budget['plan'] as String? ?? 'solo';
    final apiLimit = budget['api_limit'] as int? ?? 500;

    return Card(
      color: _getStatusColor(status),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$status Monthly Budget',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${plan.toUpperCase()} Plan',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${used.toStringAsFixed(2)} / \$${limit.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  '${percentUsed.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentUsed / 100).clamp(0, 1),
                minHeight: 10,
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentUsed > 90 ? Colors.red : percentUsed > 80 ? Colors.orange : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Remaining Budget', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Text(
                      '\$${(budget['remaining'] as double? ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('API Calls Limit', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Text(
                      '$apiLimit/month',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProactivityControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Proactivity Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Control how aggressively AI agents work',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildProactivityOption('conservative', '🛡️ Conservative', 'Minimal automation, manual approval required'),
            const SizedBox(height: 8),
            _buildProactivityOption('balanced', '⚖️ Balanced', 'Recommended - smart automation with alerts'),
            const SizedBox(height: 8),
            _buildProactivityOption('aggressive', '🔥 Aggressive', 'Maximum automation, higher API usage'),
          ],
        ),
      ),
    );
  }

  Widget _buildProactivityOption(String value, String title, String desc) {
    final isSelected = selectedProactivityLevel == value;
    
    return GestureDetector(
      onTap: () async {
        await automationService.setProactivityLevel(orgId, value);
        setState(() => selectedProactivityLevel = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Proactivity level changed to: $title')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentControls() {
    final agents = settings['agents'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🤖 Agent Control Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...agents.entries.map((entry) {
              final agentName = entry.key;
              final config = entry.value as Map<String, dynamic>;
              final isEnabled = config['enabled'] as bool? ?? true;
              final isProactive = config['proactive'] as bool? ?? false;

              return _buildAgentCard(agentName, isEnabled, isProactive, config);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(String agent, bool enabled, bool proactive, Map<String, dynamic> config) {
    final agentInfo = {
      'cfo': {'color': Colors.green, 'title': 'CFO Agent', 'role': 'Financial Analysis'},
      'ceo': {'color': Colors.blue, 'title': 'CEO Agent', 'role': 'Strategic Planning'},
      'marketing': {'color': Colors.orange, 'title': 'Marketing Agent', 'role': 'Campaign Automation'},
      'sales': {'color': Colors.purple, 'title': 'Sales Agent', 'role': 'Lead Management'},
      'admin': {'color': Colors.red, 'title': 'Admin Agent', 'role': 'Team Management'},
    };

    final info = agentInfo[agent] ?? {};

    return Card(
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  info['title'] as String? ?? agent,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: enabled,
                  onChanged: (val) async {
                    await automationService.setAgentEnabled(orgId, agent, val);
                    await _refreshData();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              info['role'] as String? ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text('Proactive: '),
                      Switch(
                        value: proactive && enabled,
                        onChanged: enabled
                            ? (val) async {
                                await automationService.setAgentProactive(orgId, agent, val);
                                await _refreshData();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    'Limit: ${config['api_calls_limit']} calls',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageAnalytics() {
    final apiCalls = usage['api_calls'] as int? ?? 0;
    final totalCost = usage['total_cost'] as double? ?? 0;
    final breakdown = usage['breakdown'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 This Month\'s Usage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBox('API Calls', apiCalls.toString()),
                _buildStatBox('Cost', '\$${totalCost.toStringAsFixed(2)}'),
                _buildStatBox('Agents Active', breakdown.length.toString()),
              ],
            ),
            if (breakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Agent Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              ...breakdown.entries.map((e) {
                final agentName = e.key;
                final data = e.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(agentName),
                      Text(
                        '${data['count']} calls • \$${(data['cost'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostLimits() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 Cost Control Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Monthly Cost Limit',
              '\$${(settings['monthly_cost_limit'] as num? ?? 100).toStringAsFixed(2)}',
              'Auto-pause agents when reached',
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              'Alert Threshold',
              '${((settings['cost_alert_threshold'] as num? ?? 0.8) * 100).toStringAsFixed(0)}%',
              'Alert when this % of budget is used',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Auto-Pause on Limit'),
                Switch(
                  value: settings['auto_pause_on_limit'] as bool? ?? true,
                  onChanged: (val) async {
                    await automationService.setAutoPauseOnLimit(orgId, val);
                    await _refreshData();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String value, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('LIMIT_REACHED') || status.contains('ERROR')) return Colors.red;
    if (status.contains('CRITICAL')) return Colors.red[700]!;
    if (status.contains('WARNING')) return Colors.orange;
    return Colors.green;
  }

  Future<void> _refreshData() async {
    settings = await automationService.getAutomationSettings(orgId);
    usage = await automationService.getCurrentMonthUsage(orgId);
    budget = await automationService.getRemainingBudget(orgId);
    if (mounted) setState(() {});
  }
}
