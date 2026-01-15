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
      'period': '/month',
      'description': '1 user • 25 jobs/month • Advanced invoicing (recurring, deposits, milestones) • Custom logo & colors • SMS notifications • HubSpot & QuickBooks integrations • Autonomous AI agents (CEO, COO, CFO) • All features',
      'plan_id': 'solo_trades',
      'max_users': 1,
      'max_jobs': 25,
      'mobile_devices': 2,
      'tablet_devices': 1,
      'total_features': 6,
      'stripe_url': 'https://buy.stripe.com/abc123', // ← Replace with your SOLO link
      'color': 0xFF2196F3, // Blue
    },
    {
      'name': 'Team',
      'price': '\$15',
      'period': '/month',
      'description': '3 users • 60 jobs/month • Advanced invoicing (recurring, deposits, milestones) • Custom logo, colors & watermark • SMS notifications • HubSpot & QuickBooks integrations • Autonomous AI agents (CEO, COO, CFO) • Marketing automation • All features',
      'plan_id': 'small_team',
      'max_users': 3,
      'max_jobs': 60,
      'mobile_devices': 3,
      'tablet_devices': 2,
      'total_features': 8,
      'stripe_url': 'https://buy.stripe.com/def456', // ← Replace with your TEAM link
      'color': 0xFF3F51B5, // Indigo
    },
    {
      'name': 'Workshop',
      'price': '\$29',
      'period': '/month',
      'description': '7 users • 120 jobs/month • Advanced invoicing (recurring, deposits, milestones) • Full white-label (custom logo, colors, watermark) • SMS notifications • HubSpot & QuickBooks integrations • Autonomous AI agents (CEO, COO, CFO) • Marketing automation • Dedicated support • API access • All features',
      'plan_id': 'workshop',
      'max_users': 7,
      'max_jobs': 120,
      'mobile_devices': 5,
      'tablet_devices': 3,
      'total_features': 13,
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
            const SizedBox(height: 20),
            
            // ✨ Trial & Discount Banners
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✨ FREE TRIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '50% OFF 2 MONTHS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🎉 Start with 7 days FREE • No credit card required!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'After trial ends, save 20% with annual billing on any plan',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Start Free Trial Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/sign-up');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Start Free Trial (7 Days)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Domain & Email Included Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Color(0xFF10B981), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎁 Custom Domain Name & Email Included',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get a professional business domain and email with every plan—no extra cost!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                plan['mobile_devices'] as int,
                plan['tablet_devices'] as int,
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
                    _buildFeatureRow('Jobs/Month', '25', '60', 'Unlimited'),
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
                    const Row(
                      children: [
                        Icon(Icons.business, color: Colors.orange, size: 32),
                        SizedBox(width: 12),
                        Text(
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
    int mobileDevices,
    int tabletDevices,
    Color accentColor,
  ) {
    // Calculate annual price with 20% discount
    final basePriceNum = double.parse(price.replaceAll('\$', '').replaceAll(',', ''));
    final annualPrice = (basePriceNum * 12 * 0.8).toStringAsFixed(2);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                // Popular badge for Team plan
                if (title == 'Team')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 4),
                // Show annual pricing discount
                Row(
                  children: [
                    const Text(
                      '💰 Annual billing: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '\$$annualPrice/year',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                    const Text(
                      ' (20% off)',
                      style: TextStyle(fontSize: 12, color: Color(0xFFFF9800)),
                    ),
                  ],
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
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('📱 Mobile & Tablet Access:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text('• $mobileDevices mobile devices (6 customizable features per device)', 
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text('• $tabletDevices tablet device${tabletDevices > 1 ? 's' : ''} (8 customizable features per device)', 
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                child: const Text('Start 3-Day Free Trial', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '✓ No credit card required',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
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
    // Start trial instead of requiring payment
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
        return;
      }

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Create organization
      final orgData = await supabase.from('organizations').insert({
        'owner_id': userId,
        'name': 'My Workshop',
        'plan': planId,
        'max_users': maxUsers,
        'is_trial_active': true,
        'trial_ends_at': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'discount_percentage': 50.0,
        'discount_ends_at': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
      }).select().single();

      // Add owner as first member
      await supabase.from('org_members').insert({
        'org_id': orgData['id'],
        'user_id': userId,
        'role': 'owner',
      });

      // Create subscription record
      await supabase.from('subscriptions').insert({
        'org_id': orgData['id'],
        'user_id': userId,
        'plan': planId,
        'status': 'trial',
        'trial_started_at': DateTime.now().toIso8601String(),
        'trial_ends_at': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'trial_used': false,
        'discount_percentage': 50.0,
        'discount_months_remaining': 2,
        'discount_applied_at': DateTime.now().toIso8601String(),
        'discount_ends_at': DateTime.now().add(const Duration(days: 60)).toIso8601String(),
      });

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success message
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Trial Started!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your 3-day free trial has been activated.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  '✨ What you get:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Text(
                  '• Full access to all features',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• No credit card required',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '• 50% off for the first 2 months after trial',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Trial expires: ${DateTime.now().add(const Duration(days: 3)).toLocal().toString().split('.')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                child: const Text('Start Using AuraSphere'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if shown
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting trial: $e')),
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
