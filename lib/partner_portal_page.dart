// lib/partner_portal_page.dart
/// Partner Sales Enablement Portal
/// Certification, commissions, and sales resources for resellers/affiliates

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerPortalPage extends StatefulWidget {
  const PartnerPortalPage({super.key});

  @override
  State<PartnerPortalPage> createState() => _PartnerPortalPageState();
}

class _PartnerPortalPageState extends State<PartnerPortalPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late String partnerId;
  late String orgId;
  bool _loading = true;
  late TabController _tabController;
  String certLevel = 'none';  // Track certification level

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuth();
  }

  void _checkAuth() {
    if (supabase.auth.currentUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = supabase.auth.currentUser!;

      // Get org ID
      final orgData = await supabase
          .from('organizations')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (orgData != null) {
        orgId = orgData['id'] as String;
      }

      // Get partner account
      final partnerData = await supabase
          .from('partner_accounts')
          .select('id, company_name, certification_level, commission_rate')
          .eq('user_id', user.id)
          .maybeSingle();

      if (partnerData != null) {
        partnerId = partnerData['id'] as String;
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Unauthorized')),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🤝 Partner Portal'),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Certification'),
              Tab(text: 'Resources'),
              Tab(text: 'Commission'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDashboard(),
            _buildCertification(),
            _buildResources(),
            _buildCommission(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('partner_accounts')
          .select(
              'id, company_name, status, certification_level, prospects_count, closed_deals_count, commission_rate')
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final partner = snapshot.data;

        if (partner == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Partner Account Not Found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showPartnerOnboarding,
                  child: const Text('Create Partner Account'),
                ),
              ],
            ),
          );
        }

        final certLevel = partner['certification_level'] as String? ?? 'base';
        final prospectCount = partner['prospects_count'] as int? ?? 0;
        final dealsCount = partner['closed_deals_count'] as int? ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Card(
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.blue[700]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner['company_name'] as String? ?? 'Partner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getCertificationBadge(certLevel),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            partner['status'] == 'active'
                                ? '✅ Active'
                                : '⏳ Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Prospects', prospectCount.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Closed Deals', dealsCount.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Commission',
                    '${(partner['commission_rate'] as int? ?? 20)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              '📊 Generate Prospect Demo',
              'Create interactive savings demo for your client',
              () => _showDemoGenerator(),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              '🎓 Advance Certification',
              'Upgrade to Certified or Elite tier',
              () => _showCertificationUpgrade(),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              '📈 View Commission Report',
              'See YTD and monthly earnings',
              () => _tabController.animateTo(3),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCertification() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: supabase
          .from('partner_accounts')
          .select('certification_level, certification_progress, created_at')
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final partner = snapshot.data;
        final certLevel = partner?['certification_level'] as String? ?? 'base';
        final progress = partner?['certification_progress'] as int? ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Certification Levels',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Base Certification
            _buildCertLevelCard(
              level: 'Base Partner',
              icon: '🌟',
              description: 'Entry-level partnership',
              requirements: [
                'Sign partnership agreement',
                'Complete product training',
                'Min. 1 closed deal',
              ],
              commission: '15%',
              isActive: certLevel == 'base',
              onTap: () => _enrollCertification('base'),
            ),
            const SizedBox(height: 12),

            // Certified Partner
            _buildCertLevelCard(
              level: 'Certified Partner',
              icon: '⭐',
              description: 'Verified sales capability',
              requirements: [
                'Base certification',
                'Min. 5 closed deals/year',
                'Customer satisfaction score >4.5/5',
                'Attend annual summit',
              ],
              commission: '20%',
              isActive: certLevel == 'certified',
              onTap: () => _enrollCertification('certified'),
            ),
            const SizedBox(height: 12),

            // Elite Partner
            _buildCertLevelCard(
              level: 'Elite Partner',
              icon: '👑',
              description: 'Strategic partnership',
              requirements: [
                'Certified partner status',
                'Min. 20 closed deals/year',
                'Customer satisfaction score >4.8/5',
                'Dedicated account manager',
                'Custom integrations',
              ],
              commission: '25%',
              isActive: certLevel == 'elite',
              onTap: () => _enrollCertification('elite'),
            ),
            const SizedBox(height: 24),

            // Progress Tracker
            if (certLevel == 'base' || certLevel == 'certified') ...[
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress to Next Level',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(Colors.blue[400]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$progress% complete',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _enrollCertification(String level) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enrolling in $level certification...')),
    );
    setState(() => certLevel = level);
  }

  Widget _buildCertLevelCard({
    required String level,
    required String icon,
    required String description,
    required List<String> requirements,
    required String commission,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isActive ? Border.all(color: Colors.blue, width: 2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Card(
        elevation: isActive ? 4 : 1,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$icon $level',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$commission commission',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Requirements:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            for (final req in requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(req, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (!isActive)
              ElevatedButton(
                onPressed: onTap,
                child: Text('Upgrade to $level'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✅ Current Level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildResources() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Sales Resources',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),

        // Training Videos
        _buildResourceSection(
          title: '🎥 Training Videos',
          items: [
            ('CloudGuard Introduction', 'Learn the basics in 5 minutes'),
            ('Sales Demo Walkthrough', 'See the complete product tour'),
            ('ROI Calculator Training', 'Master the savings calculator'),
            ('Client Objection Handling', 'Overcome common sales challenges'),
          ],
        ),
        const SizedBox(height: 24),

        // Sales Materials
        _buildResourceSection(
          title: '📄 Sales Materials',
          items: [
            ('One-Page Pitch Deck', 'Quick overview for decision makers'),
            ('ROI Calculator Spreadsheet', 'Customize for your clients'),
            ('Case Study Library', '12 real-world success stories'),
            ('Email Templates', 'Pre-written outreach sequences'),
          ],
        ),
        const SizedBox(height: 24),

        // Technical Docs
        _buildResourceSection(
          title: '📚 Technical Documentation',
          items: [
            ('API Integration Guide', 'Connect CloudGuard to your platform'),
            ('Webhooks Reference', 'Real-time event notifications'),
            ('White-label Branding', 'Customize for your brand'),
            ('Data Privacy & Compliance', 'GDPR, SOC2, ISO27001'),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceSection({
    required String title,
    required List<(String, String)> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        for (final (name, desc) in items)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(name),
              subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.download),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('📥 Downloading $name...')),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCommission() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('partner_commissions')
          .select('month, commission_amount, status, payment_date')
          .eq('partner_id', partnerId.isEmpty ? '' : partnerId)
          .order('month', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final commissions = snapshot.data ?? [];

        if (commissions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No commissions yet'),
                const SizedBox(height: 8),
                const Text(
                  'Your earnings will appear here when deals close',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final totalYtd = commissions.fold<double>(0, (sum, item) {
          return sum + ((item['commission_amount'] as num?)?.toDouble() ?? 0);
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card
            Card(
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[700]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Total YTD Commission',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalYtd.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Commission History
            const Text(
              'Commission History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            for (final commission in commissions)
              _buildCommissionCard(commission),
          ],
        );
      },
    );
  }

  Widget _buildCommissionCard(Map<String, dynamic> commission) {
    final amount = commission['commission_amount'] as double? ?? 0;
    final status = commission['status'] as String? ?? 'pending';
    final month = commission['month'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(month),
        subtitle: Text(
          status == 'paid' ? '✅ Paid' : '⏳ Pending',
          style: TextStyle(
            color: status == 'paid' ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '+\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  String _getCertificationBadge(String level) {
    switch (level) {
      case 'elite':
        return '👑 Elite Partner';
      case 'certified':
        return '⭐ Certified Partner';
      default:
        return '🌟 Base Partner';
    }
  }

  void _showPartnerOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Partner Account'),
        content: const Text(
            'Partner onboarding wizard coming soon. Contact support to get started.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDemoGenerator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Prospect Demo Generator'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: r'Monthly Cloud Spend ($)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(r'Demo will show potential savings of 28% ($$$)',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Demo generated!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Generate Demo'),
          ),
        ],
      ),
    );
  }

  void _showCertificationUpgrade() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Certification'),
        content: const Text('Contact your account manager to discuss certification upgrade options.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
