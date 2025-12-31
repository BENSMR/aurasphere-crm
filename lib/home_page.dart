// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_list_page.dart';
import 'pricing_page.dart';
import 'inventory_page.dart';
import 'team_page.dart';
import 'dispatch_page.dart';
import 'technician_dashboard_page.dart';
import 'client_list_page.dart';
import 'lead_import_page.dart';
import 'performance_page.dart';
import 'services/lead_agent_service.dart';

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
    _checkSubscription();
    _runDailyAutomation();
  }

  Future<void> _runDailyAutomation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRun = prefs.getString('last_automation_run');
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      
      // Run once per day at 9 AM or later
      if (lastRun != todayKey && today.hour >= 9) {
        _logger.d('🤖 Running daily automation tasks...');
        await LeadAgentService().runDailyTasks();
        await prefs.setString('last_automation_run', todayKey);
        _logger.i('✅ Automation complete');
      }
    } catch (e) {
      _logger.e('❌ Automation error: $e');
    }
  }

  Future<void> _checkSubscription() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
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
      length: 6, // Jobs, Leads, Inventory, Dispatch, Performance, Team
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Aurasphere Workshop'),
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Jobs'),
              Tab(text: 'Leads'),
              Tab(text: 'Inventory'),
              Tab(text: 'Dispatch'),
              Tab(text: 'Performance'),
              Tab(text: 'Team'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            JobListPage(),
            LeadImportPage(),
            InventoryPage(),
            DispatchPage(),
            PerformancePage(),
            TeamPage(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
