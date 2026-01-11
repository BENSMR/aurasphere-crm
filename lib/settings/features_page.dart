// lib/settings/features_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  late Map<String, dynamic> features;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    final supabase = Supabase.instance.client;
    try {
      final prefs = await supabase
          .from('user_preferences')
          .select('features')
          .eq('user_id', supabase.auth.currentUser!.id)
          .single();
      setState(() {
        features = Map<String, dynamic>.from(prefs['features'] as Map);
        _loading = false;
      });
    } catch (e) {
      // Default features
      setState(() {
        features = {
          "pki_mode": false,
          "client_memory": true,
          "ai_invoices": true,
          "financial_clarity": true,
          "auto_invoicing": false,
          "business_autopilot": true,
          "do_nothing_mode": false,
          "human_explanations": true,
          "client_health": true,
          "ocr_expenses": true,
          "pdf_invoices": true,
          "teams": true,
          "usage_limits": true,
          "dark_mode": true,
          "auto_tax": true,
          "data_export": true,
          "privacy_mode": true,
          "behavioral_onboarding": true
        };
        _loading = false;
      });
    }
  }

  Future<void> _toggleFeature(String key) async {
    final newValue = !(features[key] as bool);
    features[key] = newValue;
    
    final supabase = Supabase.instance.client;
    await supabase.from('user_preferences').upsert({
      'user_id': supabase.auth.currentUser?.id,
      'features': features,
    });
    
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Customize Aura')),
      body: ListView(
        children: [
          _buildSection('Security & Privacy'),
          _buildFeature('pki_mode', 'PKI-Grade Encryption', 'Client-side encryption keys'),
          _buildFeature('privacy_mode', 'Zero-Tracking Mode', 'Disable all analytics'),
          _buildFeature('data_export', 'GDPR Data Export', 'One-tap JSON backup'),
          
          _buildSection('AI Assistant'),
          _buildFeature('ai_invoices', 'AI Invoice Generator', 'Natural language → invoice'),
          _buildFeature('client_memory', 'Client Memory', 'Remembers client requests'),
          _buildFeature('human_explanations', 'Human Explanations', 'Tap "Why?" for plain-language insights'),
          _buildFeature('do_nothing_mode', 'Do Nothing Mode', 'Aura handles everything automatically'),
          _buildFeature('business_autopilot', 'Business Health Autopilot', 'Weekly performance reports'),
          
          _buildSection('Automation'),
          _buildFeature('auto_invoicing', 'Auto-Invoice & Payment', 'Send invoice + Stripe link automatically'),
          _buildFeature('ocr_expenses', 'Smart Receipt OCR', 'Scan receipts → log expenses'),
          _buildFeature('auto_tax', 'Auto Tax & Currency', 'Apply VAT/tax by client country'),
          
          _buildSection('Analytics'),
          _buildFeature('financial_clarity', 'Financial Clarity', 'Real-time P&L, cash flow, tax liability'),
          _buildFeature('client_health', 'Client Health Scoring', 'Predictive risk scoring'),
          _buildFeature('pdf_invoices', 'Multilingual PDFs', 'Auto-localized invoices'),
          
          _buildSection('Collaboration'),
          _buildFeature('teams', 'Team Collaboration', 'Invite members, assign roles'),
          _buildFeature('usage_limits', 'Usage-Based Pricing', 'Enforce plan limits'),
          _buildFeature('behavioral_onboarding', 'Behavioral Onboarding', 'UI adapts to your goals'),
          
          _buildSection('User Experience'),
          _buildFeature('dark_mode', 'Dark Mode', 'Eye-friendly interface'),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildFeature(String key, String title, String subtitle) {
    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: features[key] as bool,
      onChanged: (_) => _toggleFeature(key),
      activeThumbColor: Colors.indigo,
    );
  }
}
