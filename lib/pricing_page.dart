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
      'name': 'Solo Tradesperson',
      'discounted_price': '\$4.99',
      'full_price': '\$9.99',
      'description': '1 user • 20 jobs/month',
      'plan_id': 'solo_trades',
      'max_users': 1,
      'stripe_url': 'https://buy.stripe.com/abc123', // ← Replace with your SOLO link
      'color': 0xFF2196F3, // Blue
    },
    {
      'name': 'Small Team',
      'discounted_price': '\$7.50',
      'full_price': '\$15',
      'description': '3 users • Unlimited jobs',
      'plan_id': 'small_team',
      'max_users': 3,
      'stripe_url': 'https://buy.stripe.com/def456', // ← Replace with your TEAM link
      'color': 0xFF3F51B5, // Indigo
    },
    {
      'name': 'Workshop',
      'discounted_price': '\$14.50',
      'full_price': '\$29',
      'description': '7 users • Stock tracking • Team dispatch',
      'plan_id': 'workshop',
      'max_users': 7,
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
                plan['discounted_price'] as String,
                plan['full_price'] as String,
                plan['description'] as String,
                plan['stripe_url'] as String,
                plan['plan_id'] as String,
                plan['max_users'] as int,
                Color(plan['color'] as int),
              ),
            )),
            
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
    String discountedPrice,
    String fullPrice,
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
            const SizedBox(height: 8),
            const Text(
              '✨ 7-day free trial',
              style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  discountedPrice,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Text(
                  '/mo for 2 months',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            Text(
              'Then $fullPrice/mo',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
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
}
