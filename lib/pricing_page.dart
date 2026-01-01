// lib/pricing_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PricingPage extends StatelessWidget {
  final VoidCallback? onOrganizationCreated;
  
  const PricingPage({super.key, this.onOrganizationCreated});

  static final supabase = Supabase.instance.client;

  // Tradesperson-focused pricing plans
  static const plans = [
    {
      'name': 'Solo',
      'price': '\$9.99',
      'description': '1 user • 30 jobs/month • Advanced invoicing • SMS notifications • HubSpot & QuickBooks integrations • Autonomous AI agents (CEO, COO, CFO) • All features',
      'plan_id': 'solo_trades',
      'max_users': 1,
      'max_jobs': 30,
      'stripe_url': 'https://buy.stripe.com/abc123', // ← Replace with your SOLO link
      'color': 0xFF2196F3, // Blue
    },
    {
      'name': 'Team',
      'price': '\$20',
      'description': '3 users • 120 jobs/month • Advanced invoicing • SMS notifications • HubSpot & QuickBooks integrations • Autonomous AI agents (CEO, COO, CFO) • Marketing automation • All features',
      'plan_id': 'small_team',
      'max_users': 3,
      'max_jobs': 120,
      'stripe_url': 'https://buy.stripe.com/def456', // ← Replace with your TEAM link
      'color': 0xFF3F51B5, // Indigo
    },
    {
      'name': 'Workshop',
      'price': '\$49',
      'description': '7 users • Unlimited jobs • Advanced invoicing • SMS notifications • HubSpot & QuickBooks integrations • Autonomous AI agents (CEO, COO, CFO) • Marketing automation • Dedicated support • Corporate & special requests • All features',
      'plan_id': 'workshop',
      'max_users': 7,
      'max_jobs': 999999,
      'stripe_url': 'https://buy.stripe.com/ghi789', // ← Replace with your WORKSHOP link
      'color': 0xFF9C27B0, // Purple
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AuraSphere for Trades',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Job management built for plumbers, electricians, and contractors',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            
            // Plan cards
            ...plans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPlanCard(
                context,
                plan['name'] as String,
                plan['price'] as String,
                plan['description'] as String,
                plan['stripe_url'] as String,
                plan['plan_id'] as String,
                plan['max_users'] as int,
                Color(plan['color'] as int),
              ),
            )),            
            const SizedBox(height: 48),
            
            // FEATURE COMPARISON TABLE
            const Text(
              'Feature Comparison',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Feature')),
                    DataColumn(label: Text('Solo')),
                    DataColumn(label: Text('Team')),
                    DataColumn(label: Text('Workshop')),
                  ],
                  rows: [
                    _buildFeatureRow('Jobs/Month', '30', '120', 'Unlimited'),
                    _buildFeatureRow('Team Members', '1', '3', '7'),
                    _buildFeatureRow('Advanced Invoicing', '✓', '✓', '✓'),
                    _buildFeatureRow('SMS Notifications', '✓', '✓', '✓'),
                    _buildFeatureRow('Job Management', '✓', '✓', '✓'),
                    _buildFeatureRow('Client Management', '✓', '✓', '✓'),
                    _buildFeatureRow('Inventory Tracking', '✓', '✓', '✓'),
                    _buildFeatureRow('Team Dispatch', '✓', '✓', '✓'),
                    _buildFeatureRow('Calendar Scheduling', '✓', '✓', '✓'),
                    _buildFeatureRow('HubSpot Integration', '✓', '✓', '✓'),
                    _buildFeatureRow('QuickBooks Integration', '✓', '✓', '✓'),
                    _buildFeatureRow('Advanced Analytics', '✓', '✓', '✓'),
                    _buildFeatureRow('AI CEO Agent', '✓', '✓', '✓'),
                    _buildFeatureRow('AI COO Agent', '✓', '✓', '✓'),
                    _buildFeatureRow('AI CFO Agent', '✓', '✓', '✓'),
                    _buildFeatureRow('Marketing Automation', '✓', '✓', '✓'),
                    _buildFeatureRow('Custom Domain', '✓', '✓', '✓'),
                  ],
                ),
              ),
            ),            
            const SizedBox(height: 16),
            
            // Enterprise
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, color: Colors.orange, size: 32),
                        const SizedBox(width: 12),
                        const Text(
                          'Enterprise',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Custom pricing for large teams (12+ users)',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    const Text('✓ Unlimited users'),
                    const Text('✓ Custom AI agent development'),
                    const Text('✓ Dedicated infrastructure'),
                    const Text('✓ 24/7 premium support'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _launchURL('mailto:hello@aura-sphere.app?subject=Enterprise%20Inquiry'),
                      icon: const Icon(Icons.email),
                      label: const Text('Contact Sales'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    String title,
    String price,
    String description,
    String stripeUrl,
    String planId,
    int maxUsers,
    Color accentColor,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Text(
                  '/month',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Divider(height: 24),
            const Text('✅ All Features Included:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('• AI Assistant • Multilingual PDFs • Receipt OCR', style: TextStyle(fontSize: 13)),
            const Text('• Inventory Tracking • Team Dispatch • Offline Mode', style: TextStyle(fontSize: 13)),
            const Text('• PKI Security • Technician Mobile App', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _handleSubscription(context, title, planId, maxUsers, stripeUrl),
                child: const Text('Subscribe Now', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscription(
    BuildContext context,
    String planName,
    String planId,
    int maxUsers,
    String stripeUrl,
  ) async {
    // Create organization first
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      // Create organization
      final orgData = await supabase.from('organizations').insert({
        'owner_id': userId,
        'name': 'My Workshop',
        'plan': planId,
        'max_users': maxUsers,
      }).select().single();

      // Add owner as first member
      await supabase.from('org_members').insert({
        'org_id': orgData['id'],
        'user_id': userId,
        'role': 'owner',
      });

      // Notify parent widget
      onOrganizationCreated?.call();

      // Open Stripe payment
      await _launchURL(stripeUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization created! Complete payment to activate.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating organization: $e')),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  static DataRow _buildFeatureRow(String feature, String solo, String team, String workshop) {
    return DataRow(cells: [
      DataCell(Text(feature, style: const TextStyle(fontWeight: FontWeight.w500))),
      DataCell(Text(solo, style: TextStyle(color: solo == '✗' ? Colors.red : Colors.green))),
      DataCell(Text(team, style: TextStyle(color: team == '✗' ? Colors.red : Colors.green))),
      DataCell(Text(workshop, style: TextStyle(color: workshop == '✗' ? Colors.red : Colors.green))),
    ]);
  }
}
