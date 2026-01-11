// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'job_list_page.dart';
import 'pricing_page.dart';
import 'inventory_page.dart';
import 'team_page.dart';
import 'dispatch_page.dart';
import 'technician_dashboard_page.dart';
import 'client_list_page.dart';
import 'lead_import_page.dart';
import 'performance_page.dart';
import 'aura_chat_page.dart';
import 'ai_automation_settings_page.dart';
// import 'services/lead_agent_service.dart';
// import 'services/feature_personalization_helper.dart';

final _logger = Logger();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasActiveSubscription = false;
  bool _loading = true;
  String? _userPlan;
  bool _isOwner = false;
  String? _stripeStatus;
  String? _userType; // 'freelancer' or 'trades'

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _checkSubscription();
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;
    _logger.i('🔐 Auth check: User = ${user?.email ?? "DEMO MODE"}');
    
    if (user == null) {
      _logger.i('✅ Demo mode detected - allowing access without auth');
      // Demo mode - allow access anyway
      // Just continue loading
    }
  }

  Future<void> _checkSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      // If no user, use demo mode
      if (userId == null) {
        _logger.i('✅ Demo mode: Using demo subscription');
        if (mounted) {
          setState(() {
            _hasActiveSubscription = true;
            _userPlan = 'demo';
            _isOwner = true;
            _stripeStatus = 'active';
            _userType = 'trades';
            _loading = false;
          });
        }
        return;
      }

      // Fetch user type from preferences
      String? businessType;
      try {
        final userPrefs = await Supabase.instance.client
            .from('user_preferences')
            .select('business_type')
            .eq('user_id', userId)
            .maybeSingle();
        
        businessType = userPrefs?['business_type'];
      } catch (e) {
        // Column might not exist yet, default to null
        _logger.e('Could not fetch business_type: $e');
        businessType = null;
      }

      // Check if user has an organization (means they subscribed)
      final org = await Supabase.instance.client
          .from('organizations')
          .select('id, plan, owner_id, stripe_status')
          .eq('owner_id', userId)
          .maybeSingle();
      
      if (org == null) {
        // Not an owner, check if they're a team member
        final member = await Supabase.instance.client
            .from('org_members')
            .select('org_id')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (member != null) {
          // Team member - fetch org plan
          final memberOrg = await Supabase.instance.client
              .from('organizations')
              .select('id, plan, stripe_status')
              .eq('id', member['org_id'])
              .single();
          
          if (mounted) {
            setState(() {
              _hasActiveSubscription = true;
              _isOwner = false;
              _userPlan = memberOrg['plan'];
              _stripeStatus = memberOrg['stripe_status'];
              _userType = businessType;
            });
          }
        } else {
          // No subscription
          if (mounted) {
            setState(() {
              _hasActiveSubscription = false;
              _userType = businessType;
            });
          }
        }
      } else {
        // Is owner
        if (mounted) {
          setState(() {
            _hasActiveSubscription = true;
            _isOwner = true;
            _userPlan = org['plan'];
            _stripeStatus = org['stripe_status'];
            _userType = businessType;
          });
        }
      }
    } catch (e) {
      _logger.e('Subscription check error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _buildWorkshopView() {
    return DefaultTabController(
      length: 8, // Jobs, Leads, Inventory, Dispatch, Performance, Team, Suppliers, AI Chat
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('AuraSphere Workshop'),
              if (_stripeStatus == 'trialing') ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '✨ 7-day trial active',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'AI Automation Settings',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const AIAutomationSettingsPage(),
                ));
              },
            ),
            TextButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            isScrollable: false,
            tabs: [
              Tab(icon: Icon(Icons.work), text: 'Jobs'),
              Tab(icon: Icon(Icons.people), text: 'Leads'),
              Tab(icon: Icon(Icons.inventory_2), text: 'Inventory'),
              Tab(icon: Icon(Icons.local_shipping), text: 'Dispatch'),
              Tab(icon: Icon(Icons.analytics), text: 'Performance'),
              Tab(icon: Icon(Icons.group), text: 'Team'),
              Tab(icon: Icon(Icons.business), text: 'Suppliers'),
              Tab(icon: Icon(Icons.smart_toy), text: 'AI Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const JobListPage(),
            const LeadImportPage(),
            const InventoryPage(),
            const DispatchPage(),
            const PerformancePage(),
            const TeamPage(),
            _buildSupplierTab(),
            _buildAiChatTab(),
          ],
        ),
      ),
    );
  }

  // NEW SUPPLIER TAB
  Widget _buildSupplierTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Supplier Management Hub',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '🤖 AI-powered supplier control, pricing optimization & PO management',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/suppliers');
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Open Supplier Hub'),
          ),
        ],
      ),
    );
  }
  // AI CHAT TAB - 5 AI Agents
  Widget _buildAiChatTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.smart_toy, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'AuraSphere AI Agents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your personal team of AI specialists. Choose an agent to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // CFO Agent
            _buildAiAgentCard(
              title: '💰 CFO Agent',
              description: 'Financial analysis, invoicing, tax compliance & budgeting',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuraChatPage(selectedAgent: 'cfo'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // CEO Agent
            _buildAiAgentCard(
              title: '🎯 CEO Agent',
              description: 'Business strategy, KPI analysis, growth recommendations',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuraChatPage(selectedAgent: 'ceo'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Marketing Agent
            _buildAiAgentCard(
              title: '📢 Marketing Agent',
              description: 'Campaign automation, lead generation, brand messaging',
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuraChatPage(selectedAgent: 'marketing'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sales Agent
            _buildAiAgentCard(
              title: '💼 Sales Agent',
              description: 'Lead qualification, pipeline management, deal tracking',
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuraChatPage(selectedAgent: 'sales'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Admin Agent
            _buildAiAgentCard(
              title: '⚙️ Admin Agent',
              description: 'Team management, permissions, system configuration',
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuraChatPage(selectedAgent: 'admin'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper widget for AI agent cards
  Widget _buildAiAgentCard({
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(width: 4, color: color),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Open'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    // Auth guard - redirect if not authenticated
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please sign in to continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show pricing if no subscription
    if (!_hasActiveSubscription) {
      return const PricingPage();
    }

    // Technician view (non-owners)
    if (!_isOwner) {
      return const TechnicianDashboardPage();
    }

    // Owner views
    // Show tabbed workshop view for workshop plan
    if (_userPlan == 'workshop') {
      return _buildWorkshopView();
    }

    // Route based on user type
    // Freelancers see client-centric view, trades see job-centric view
    if (_userType == 'freelancer') {
      return const ClientListPage();
    } else {
      return const JobListPage();
    }
  }
}
