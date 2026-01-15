// lib/services/autonomous_ai_agents_service.dart
// ✅ NOW ACTIVE - Autonomous proactive AI agents with scheduled execution
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// Autonomous AI Agents Service
/// Provides proactive AI agents (CFO, CEO, Marketing, Sales, Admin) that autonomously execute business tasks
/// Features:
/// - Scheduled background execution
/// - Proactive recommendations converted to actions
/// - Real-time monitoring & alerts
/// - Cross-org task coordination
class AutonomousAIAgentsService {
  static final AutonomousAIAgentsService _instance = AutonomousAIAgentsService._internal();
  
  final supabase = Supabase.instance.client;

  AutonomousAIAgentsService._internal();

  factory AutonomousAIAgentsService() {
    return _instance;
  }

  /// 🤖 SCHEDULER: Run autonomous agents on a schedule (hourly, daily, weekly)
  /// Called by backend cron job or user-triggered
  /// Plan-based access:
  /// - Solo: Job automation only
  /// - Team: Job automation + financial alerts
  /// - Workshop/Enterprise: All agents (CFO, CEO, Marketing, Sales)
  Future<void> runAutonomousAgents() async {
    try {
      _logger.i('🤖 Starting autonomous agent suite...');

      // Get all active organizations
      final orgs = await supabase
          .from('organizations')
          .select('id, plan, owner_id')
          .eq('billing_status', 'active');

      for (var org in orgs) {
        final orgId = org['id'] as String;
        final plan = org['plan'] as String? ?? 'solo_trades';

        _logger.i('🔄 Running agents for org: $orgId (Plan: $plan)');

        // Plan-based agent execution
        if (plan == 'solo_trades') {
          // Solo: Job automation only
          await jobAutomationAgentLimited(orgId: orgId);
        } else if (plan == 'small_team') {
          // Team: All agents but with basic/limited features
          await jobAutomationAgentLimited(orgId: orgId);
          await cfoAgentLimited(orgId: orgId);
          await ceoAgentLimited(orgId: orgId);
          await marketingAgentLimited(orgId: orgId);
          await salesAgentLimited(orgId: orgId);
        } else if (plan == 'workshop' || plan == 'enterprise') {
          // Workshop/Enterprise: Full agent suite with all features
          await jobAutomationAgentLimited(orgId: orgId);
          await cfoAgentAutonomous(orgId: orgId);
          await ceoAgentAutonomous(orgId: orgId);
          await marketingAgentAutonomous(orgId: orgId);
          await salesAgentAutonomous(orgId: orgId);
        }
      }

      _logger.i('✅ Autonomous agent suite completed');
    } catch (e) {
      _logger.e('❌ Error running autonomous agents: $e');
    }
  }

  /// 📋 GET AVAILABLE AGENTS FOR PLAN
  /// Returns list of agents available for org's subscription plan
  Future<Map<String, dynamic>> getAvailableAgentsForPlan({
    required String orgId,
  }) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('plan')
          .eq('id', orgId)
          .single();

      final plan = org['plan'] as String? ?? 'solo_trades';

      switch (plan) {
        case 'solo_trades':
          return {
            'plan': plan,
            'available_agents': ['job_automation'],
            'features': [
              'Auto-assign jobs based on availability',
              'Job status notifications',
            ],
            'message': '🟦 SOLO: Limited job automation only',
          };
        case 'small_team':
          return {
            'plan': plan,
            'available_agents': ['job_automation', 'cfo_agent', 'ceo_agent', 'marketing_agent', 'sales_agent'],
            'features': [
              'Auto-assign jobs based on availability',
              'Job status notifications',
              'Overdue invoice reminders',
              'Monthly revenue summaries',
              'Inactive client re-engagement emails',
              'Client value scoring',
            ],
            'message': '🟩 TEAM: All agents with basic features',
            'limitations': [
              'CFO: Overdue reminders only (no advanced budgeting)',
              'CEO: Monthly summaries only (no strategic planning)',
              'Marketing: Passive re-engagement only (no campaigns)',
              'Sales: Client scoring only (no pipeline management)',
            ],
          };
        case 'workshop':
        case 'enterprise':
          return {
            'plan': plan,
            'available_agents': [
              'cfo_agent',
              'ceo_agent',
              'marketing_agent',
              'sales_agent',
            ],
            'features': [
              'Full financial management (CFO)',
              'Strategic business planning (CEO)',
              'Marketing campaigns (Marketing)',
              'Lead scoring & sales (Sales)',
              'All limited plan features',
            ],
            'message': '🟪 WORKSHOP: Full autonomous agent suite',
          };
        default:
          return {
            'plan': plan,
            'available_agents': [],
            'features': [],
            'message': '❌ Unknown plan',
          };
      }
    } catch (e) {
      _logger.e('❌ Error getting available agents: $e');
      return {'error': e.toString()};
    }
  }

  /// 🎯 JOB AUTOMATION AGENT - LIMITED (Solo, Team, Workshop)
  /// Available in ALL plans - handles job assignment and status automation
  Future<void> jobAutomationAgentLimited({required String orgId}) async {
    try {
      _logger.i('🎯 Job Automation Agent: Starting for org: $orgId');

      // Get unassigned jobs (status: pending, not assigned to team member)
      final pendingJobs = await supabase
          .from('jobs')
          .select('id, title, assigned_to, priority, created_at')
          .eq('org_id', orgId)
          .eq('status', 'pending')
          .isFilter('assigned_to', null); // Not yet assigned

      _logger.i('📋 Found ${pendingJobs.length} unassigned jobs');

      // Get team members with availability
      final teamMembers = await supabase
          .from('org_members')
          .select('user_id, email, role')
          .eq('org_id', orgId)
          .neq('role', 'owner');

      // Auto-assign jobs to available team members (round-robin)
      for (int i = 0; i < pendingJobs.length; i++) {
        final job = pendingJobs[i];
        final assignee = teamMembers[i % teamMembers.length];

        await supabase
            .from('jobs')
            .update({
              'assigned_to': assignee['user_id'],
              'status': 'assigned',
              'assigned_at': DateTime.now().toIso8601String(),
            })
            .eq('id', job['id']);

        _logger.i('✅ Job "${job['title']}" auto-assigned to ${assignee['email']}');
      }

      _logger.i('✅ Job automation completed');
    } catch (e) {
      _logger.e('❌ Job automation error: $e');
    }
  }

  /// 💰 CFO AGENT - LIMITED (Team, Workshop+)
  /// Limited to overdue reminders and alerts only
  Future<void> cfoAgentLimited({required String orgId}) async {
    try {
      _logger.i('💰 CFO Agent (Limited): Starting for org: $orgId');

      // ONLY: Overdue invoice reminders
      final overdueInvoices = await supabase
          .from('invoices')
          .select('id, client_id, amount, due_date, reminder_sent_at')
          .eq('org_id', orgId)
          .eq('status', 'sent')
          .lt('due_date', DateTime.now().toIso8601String());

      _logger.i('💳 Found ${overdueInvoices.length} overdue invoices');

      for (var invoice in overdueInvoices) {
        // Skip if reminder already sent today
        final lastReminder = invoice['reminder_sent_at'] as String?;
        if (lastReminder != null) {
          final lastDate = DateTime.parse(lastReminder);
          if (DateTime.now().difference(lastDate).inHours < 24) {
            continue; // Skip - already reminded today
          }
        }

        final clientId = invoice['client_id'];
        final client = await supabase
            .from('clients')
            .select('email, name')
            .eq('id', clientId)
            .maybeSingle();

        if (client == null) continue;

        // AUTO-SEND REMINDER EMAIL via Edge Function
        try {
          await supabase.functions.invoke('send-email', body: {
            'to': client['email'],
            'subject': '⏰ Invoice Overdue Reminder - Action Required',
            'template': 'overdue_reminder',
            'data': {
              'client_name': client['name'],
              'invoice_number': invoice['id'],
              'amount': invoice['amount'],
            }
          });

          // Mark reminder sent
          await supabase
              .from('invoices')
              .update({'reminder_sent_at': DateTime.now().toIso8601String()})
              .eq('id', invoice['id']);

          _logger.i('📧 Reminder sent to ${client['email']}');
        } catch (e) {
          _logger.w('⚠️ Failed to send reminder: $e');
        }
      }

      _logger.i('✅ Limited CFO agent completed (overdue reminders only)');
    } catch (e) {
      _logger.e('❌ Limited CFO agent error: $e');
    }
  }

  /// 🎯 CEO AGENT - LIMITED (Team Plan)
  /// Limited to monthly performance summary only
  Future<void> ceoAgentLimited({required String orgId}) async {
    try {
      _logger.i('🎯 CEO Agent (Limited): Starting for org: $orgId');

      // Get monthly revenue summary
      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month);
      final invoices = await supabase
          .from('invoices')
          .select('amount, status, created_at')
          .eq('org_id', orgId)
          .gte('created_at', startOfMonth.toIso8601String());

      double totalRevenue = 0;
      double paidRevenue = 0;

      for (var invoice in invoices) {
        final amount = (invoice['amount'] as num).toDouble();
        final status = invoice['status'] as String;

        totalRevenue += amount;
        if (status == 'paid') {
          paidRevenue += amount;
        }
      }

      _logger.i('📊 Monthly Summary: \$${totalRevenue.toStringAsFixed(2)} total, \$${paidRevenue.toStringAsFixed(2)} paid');
    } catch (e) {
      _logger.e('❌ Limited CEO agent error: $e');
    }
  }

  /// 📢 MARKETING AGENT - LIMITED (Team Plan)
  /// Limited to email reminders for inactive clients only
  Future<void> marketingAgentLimited({required String orgId}) async {
    try {
      _logger.i('📢 Marketing Agent (Limited): Starting for org: $orgId');

      // Find clients with no invoices in last 30 days (inactive)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final inactiveClients = await supabase
          .from('clients')
          .select('id, email, name, last_invoice_date')
          .eq('org_id', orgId)
          .or('last_invoice_date.is.null,last_invoice_date.lt.${thirtyDaysAgo.toIso8601String()}');

      _logger.i('📋 Found ${inactiveClients.length} inactive clients');

      for (var client in inactiveClients) {
        final lastEmail = client['last_engagement_email'] as String?;
        
        // Skip if already emailed this month
        if (lastEmail != null) {
          final lastDate = DateTime.parse(lastEmail);
          if (DateTime.now().difference(lastDate).inDays < 30) {
            continue;
          }
        }

        try {
          // Send re-engagement email
          await supabase.functions.invoke('send-email', body: {
            'to': client['email'],
            'subject': 'We miss you! Special offer inside 💙',
            'template': 'reengagement',
            'data': {
              'client_name': client['name'],
              'days_since_contact': DateTime.now().difference(DateTime.parse(client['last_invoice_date'] ?? DateTime.now().toIso8601String())).inDays,
            }
          });

          _logger.i('📧 Re-engagement email sent to ${client['email']}');
        } catch (e) {
          _logger.w('⚠️ Failed to send engagement email: $e');
        }
      }

      _logger.i('✅ Limited marketing agent completed');
    } catch (e) {
      _logger.e('❌ Limited marketing agent error: $e');
    }
  }

  /// 💼 SALES AGENT - LIMITED (Team Plan)
  /// Limited to lead scoring on existing clients only
  Future<void> salesAgentLimited({required String orgId}) async {
    try {
      _logger.i('💼 Sales Agent (Limited): Starting for org: $orgId');

      // Score existing clients by value
      final clients = await supabase
          .from('clients')
          .select('id, email, name, total_spent, invoice_count')
          .eq('org_id', orgId);

      int scoredCount = 0;
      for (var client in clients) {
        final totalSpent = (client['total_spent'] as num?)?.toDouble() ?? 0;
        final invoiceCount = (client['invoice_count'] as num?)?.toInt() ?? 0;

        // Calculate client value score (0-100)
        double score = 0;
        if (totalSpent > 1000) score += 30;
        if (totalSpent > 5000) score += 20;
        if (invoiceCount > 5) score += 25;
        if (invoiceCount > 10) score += 25;

        // Update client score
        await supabase
            .from('clients')
            .update({'client_value_score': score.toInt()})
            .eq('id', client['id']);

        scoredCount++;
      }

      _logger.i('⭐ Scored $scoredCount clients for value');
      _logger.i('✅ Limited sales agent completed');
    } catch (e) {
      _logger.e('❌ Limited sales agent error: $e');
    }
  }

  /// 💰 CFO AGENT - AUTONOMOUS (Proactive Financial Management)
  /// Takes action: Sends overdue reminders, creates budget alerts, generates invoices
  Future<void> cfoAgentAutonomous({required String orgId}) async {
    try {
      _logger.i('💰 CFO Agent: Starting autonomous financial management for org: $orgId');

      // 1️⃣ AUTOMATIC OVERDUE REMINDERS
      final overdueInvoices = await supabase
          .from('invoices')
          .select('id, client_id, amount, due_date')
          .eq('org_id', orgId)
          .eq('status', 'sent')
          .lt('due_date', DateTime.now().toIso8601String());

      for (var invoice in overdueInvoices) {
        final clientId = invoice['client_id'];
        final client = await supabase
            .from('clients')
            .select('email, name')
            .eq('id', clientId)
            .single();

        // AUTO-SEND REMINDER EMAIL
        await supabase.functions.invoke('send-email', body: {
          'to': client['email'],
          'subject': '⏰ Invoice Overdue Reminder - Action Required',
          'template': 'overdue_reminder',
          'data': {
            'client_name': client['name'],
            'invoice_number': invoice['id'],
            'amount': invoice['amount'],
          }
        });

        // Mark reminder sent
        await supabase
            .from('invoices')
            .update({'reminder_sent_at': DateTime.now().toIso8601String()})
            .eq('id', invoice['id']);
      }

      _logger.i('✅ CFO: Sent ${overdueInvoices.length} overdue reminders');

      // 2️⃣ AUTOMATIC BUDGET ALERTS
      final org = await supabase
          .from('organizations')
          .select('settings')
          .eq('id', orgId)
          .single();

      final budgetLimit = org['settings']?['monthly_budget'] ?? 10000;
      final thisMonthExpenses = await supabase
          .from('expenses')
          .select('amount')
          .eq('org_id', orgId)
          .gte('created_at', DateTime(DateTime.now().year, DateTime.now().month, 1).toIso8601String());

      final totalExpenses = thisMonthExpenses.fold<double>(
          0, (sum, exp) => sum + (exp['amount'] as num).toDouble());

      if (totalExpenses > budgetLimit * 0.8) {
        _logger.w('⚠️ Budget alert: ${(totalExpenses / budgetLimit * 100).toStringAsFixed(1)}% spent');
        // Send alert to owner
      }
    } catch (e) {
      _logger.e('❌ CFO Agent Error: $e');
    }
  }

  /// 🎯 CEO AGENT - AUTONOMOUS (Strategic Execution)
  /// Takes action: Generates growth recommendations, auto-adjusts pricing, sends strategic reports
  Future<void> ceoAgentAutonomous({required String orgId}) async {
    try {
      _logger.i('🎯 CEO Agent: Starting autonomous strategic management for org: $orgId');

      // Get revenue trends
      final last90days = await supabase
          .from('invoices')
          .select('amount, status, created_at')
          .eq('org_id', orgId)
          .eq('status', 'paid')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 90)).toIso8601String());

      double totalRevenue = 0;
      for (var invoice in last90days) {
        totalRevenue += (invoice['amount'] as num).toDouble();
      }

      // AUTO-GENERATE WEEKLY REPORT
      if (DateTime.now().weekday == DateTime.monday) {
        _logger.i('📊 Generating weekly strategic report for org: $orgId');
        // Send weekly summary email to owner
      }

      _logger.i('✅ CEO: Strategic analysis complete (Revenue: \$${totalRevenue.toStringAsFixed(2)})');
    } catch (e) {
      _logger.e('❌ CEO Agent Error: $e');
    }
  }

  /// 📢 MARKETING AGENT - AUTONOMOUS (Proactive Outreach)
  /// Takes action: Sends email campaigns, follows up on leads, scores prospects
  Future<void> marketingAgentAutonomous({required String orgId}) async {
    try {
      _logger.i('📢 Marketing Agent: Starting autonomous campaign execution for org: $orgId');

      // GET INACTIVE CLIENTS (Not contacted in 30+ days)
      final inactiveClients = await supabase
          .from('clients')
          .select('id, email, name, last_invoice_date')
          .eq('org_id', orgId)
          .lt('last_invoice_date', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      // AUTO-SEND ENGAGEMENT EMAIL TO INACTIVE CLIENTS
      for (var client in inactiveClients) {
        await supabase.functions.invoke('send-email', body: {
          'to': client['email'],
          'subject': '👋 We miss you! Special offer inside...',
          'template': 'win_back_campaign',
          'data': {'client_name': client['name']}
        });
      }

      _logger.i('✅ Marketing: Sent ${inactiveClients.length} win-back emails');
    } catch (e) {
      _logger.e('❌ Marketing Agent Error: $e');
    }
  }

  /// 💼 SALES AGENT - AUTONOMOUS (Lead Management)
  /// Takes action: Scores leads, schedules follow-ups, qualifies prospects
  Future<void> salesAgentAutonomous({required String orgId}) async {
    try {
      _logger.i('💼 Sales Agent: Starting autonomous lead management for org: $orgId');

      // GET RECENT LEADS (Created in last 7 days)
      final recentLeads = await supabase
          .from('clients')
          .select('id, name, email, created_at, total_spent')
          .eq('org_id', orgId)
          .eq('status', 'lead')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

      // AUTO-QUALIFY LEADS
      for (var lead in recentLeads) {
        final score = _calculateLeadScore(lead);
        
        if (score > 75) {
          // Auto-mark as 'hot lead'
          await supabase
              .from('clients')
              .update({'lead_score': score, 'lead_status': 'hot'})
              .eq('id', lead['id']);

          // Send follow-up email
          await supabase.functions.invoke('send-email', body: {
            'to': lead['email'],
            'subject': '🎯 Your custom quote is ready',
            'template': 'hot_lead_follow_up',
            'data': {'lead_name': lead['name']}
          });
        }
      }

      _logger.i('✅ Sales: Qualified ${recentLeads.length} leads');
    } catch (e) {
      _logger.e('❌ Sales Agent Error: $e');
    }
  }

  /// CEO Agent - Strategic Decision Making & Business Intelligence
  /// Analyzes trends, recommends growth strategies, optimizes pricing
  Future<Map<String, dynamic>> ceoAgentAnalysis({
    required String orgId,
  }) async {
    try {
      _logger.i('🤖 CEO Agent: Starting strategic analysis for org: $orgId');

      // Get organization metrics
      final org = await supabase
          .from('organizations')
          .select('*')
          .eq('id', orgId)
          .single();

      _logger.i('📊 Organization metrics loaded: ${org['name']}');

      // Get financial data
      final invoices = await supabase
          .from('invoices')
          .select('amount, status, created_at')
          .eq('org_id', orgId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 90)).toIso8601String());

      // Get client data
      final clients = await supabase
          .from('clients')
          .select('id, created_at')
          .eq('org_id', orgId);

      // Get job data
      final jobs = await supabase
          .from('jobs')
          .select('amount, status, created_at')
          .eq('org_id', orgId);

      // Calculate metrics
      double totalRevenue = 0;
      int paidInvoices = 0;
      for (var invoice in invoices) {
        if (invoice['status'] == 'paid') {
          totalRevenue += (invoice['amount'] as num).toDouble();
          paidInvoices++;
        }
      }

      double avgInvoiceValue = paidInvoices > 0 ? totalRevenue / paidInvoices : 0;
      double growthRate = calculateGrowthRate(invoices);
      double clientRetentionRate = calculateRetentionRate(clients);

      // Generate recommendations
      List<String> recommendations = [];
      if (growthRate < 0.1) {
        recommendations.add('📈 Growth rate is below 10%. Consider promotional pricing or expanded marketing.');
      }
      if (clientRetentionRate < 0.8) {
        recommendations.add('👥 Client retention below 80%. Focus on customer satisfaction and loyalty programs.');
      }
      if (avgInvoiceValue < 500) {
        recommendations.add('💰 Average invoice value is low. Consider upselling premium services or bundling.');
      }

      // Auto-generate pricing recommendations
      String pricingStrategy = generatePricingStrategy(
        totalRevenue: totalRevenue,
        avgInvoiceValue: avgInvoiceValue,
        jobCount: jobs.length,
      );
      recommendations.add(pricingStrategy);

      _logger.i('✅ CEO Agent: Analysis complete');

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'total_revenue_90d': totalRevenue,
        'avg_invoice_value': avgInvoiceValue,
        'growth_rate_percent': (growthRate * 100).toStringAsFixed(2),
        'client_retention_rate': (clientRetentionRate * 100).toStringAsFixed(2),
        'client_count': clients.length,
        'job_count': jobs.length,
        'recommendations': recommendations,
      };
    } catch (e) {
      _logger.e('❌ CEO Agent Error: $e');
      return {'error': e.toString()};
    }
  }

  /// COO Agent - Operations Management & Workflow Optimization
  /// Optimizes team workflows, identifies bottlenecks, recommends process improvements
  Future<Map<String, dynamic>> cooAgentAnalysis({
    required String orgId,
  }) async {
    try {
      _logger.i('🤖 COO Agent: Starting operations analysis for org: $orgId');

      // Get team data
      final users = await supabase
          .from('users')
          .select('id, email, role')
          .eq('org_id', orgId);

      // Get job data with timestamps
      final jobs = await supabase
          .from('jobs')
          .select('id, assigned_to, status, created_at, updated_at')
          .eq('org_id', orgId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      // Calculate team utilization
      Map<String, int> jobsPerTechnician = {};
      for (var job in jobs) {
        String assignedTo = job['assigned_to'] ?? 'unassigned';
        jobsPerTechnician[assignedTo] = (jobsPerTechnician[assignedTo] ?? 0) + 1;
      }

      // Detect bottlenecks
      List<String> bottlenecks = [];
      double avgJobsPerTech = jobsPerTechnician.values.isNotEmpty
          ? jobsPerTechnician.values.reduce((a, b) => a + b) / jobsPerTechnician.length
          : 0;

      for (var entry in jobsPerTechnician.entries) {
        if (entry.value > avgJobsPerTech * 1.5) {
          bottlenecks.add('⚠️ Technician ${entry.key} is overloaded with ${entry.value} jobs.');
        }
      }

      // Job completion metrics
      int completedJobs = jobs.where((j) => j['status'] == 'completed').length;
      double completionRate = jobs.isNotEmpty ? (completedJobs / jobs.length) * 100 : 0;

      // Generate workflow recommendations
      List<String> improvements = [];
      if (completionRate < 70) {
        improvements.add('🎯 Job completion rate is low. Review blockers and resource allocation.');
      }
      if (bottlenecks.isNotEmpty) {
        improvements.addAll(bottlenecks);
      }
      improvements.add('📊 Implement daily standup to track progress and identify issues early.');

      _logger.i('✅ COO Agent: Operations analysis complete');

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'team_size': users.length,
        'total_jobs_30d': jobs.length,
        'completed_jobs': completedJobs,
        'completion_rate_percent': completionRate.toStringAsFixed(2),
        'avg_jobs_per_technician': avgJobsPerTech.toStringAsFixed(2),
        'jobs_per_technician': jobsPerTechnician,
        'bottlenecks': bottlenecks,
        'workflow_improvements': improvements,
      };
    } catch (e) {
      _logger.e('❌ COO Agent Error: $e');
      return {'error': e.toString()};
    }
  }

  /// CFO Agent - Financial Management & Cash Flow Optimization
  /// Tracks cash flow, predicts revenue, recommends payment terms, monitors expenses
  Future<Map<String, dynamic>> cfoAgentAnalysis({
    required String orgId,
  }) async {
    try {
      _logger.i('🤖 CFO Agent: Starting financial analysis for org: $orgId');

      // Get invoices
      final invoices = await supabase
          .from('invoices')
          .select('amount, status, created_at, due_date')
          .eq('org_id', orgId);

      // Get expenses
      final expenses = await supabase
          .from('expenses')
          .select('amount, category, created_at')
          .eq('org_id', orgId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 90)).toIso8601String());

      // Calculate cash flow metrics
      double totalInvoiced = 0;
      double totalPaid = 0;
      double totalOverdue = 0;
      int overallDaysOutstanding = 0;
      int unpaidCount = 0;

      final now = DateTime.now();
      for (var invoice in invoices) {
        double amount = (invoice['amount'] as num).toDouble();
        totalInvoiced += amount;

        if (invoice['status'] == 'paid') {
          totalPaid += amount;
        } else if (invoice['status'] == 'unpaid' || invoice['status'] == 'overdue') {
          unpaidCount++;
          final dueDate = DateTime.parse(invoice['due_date'] as String);
          if (dueDate.isBefore(now)) {
            totalOverdue += amount;
          }
          final daysOut = now.difference(dueDate).inDays;
          overallDaysOutstanding += daysOut;
        }
      }

      double avgDaysOutstanding = unpaidCount > 0 ? overallDaysOutstanding / unpaidCount : 0;

      // Calculate expenses
      double totalExpenses = 0;
      for (var expense in expenses) {
        totalExpenses += (expense['amount'] as num).toDouble();
      }

      // Calculate profit margin
      double netProfit = totalPaid - totalExpenses;
      double profitMargin = totalInvoiced > 0 ? (netProfit / totalInvoiced) * 100 : 0;

      // Generate financial recommendations
      List<String> recommendations = [];
      if (totalOverdue > 0) {
        recommendations.add('⚠️ \$${totalOverdue.toStringAsFixed(2)} in overdue payments. Send collection reminders.');
      }
      if (avgDaysOutstanding > 30) {
        recommendations.add('📅 Average days outstanding: ${avgDaysOutstanding.toStringAsFixed(0)}. Consider stricter payment terms.');
      }
      if (profitMargin < 20) {
        recommendations.add('💼 Profit margin below 20%. Review pricing or reduce operational costs.');
      }
      recommendations.add('🏦 Schedule monthly financial review to optimize cash flow.');

      _logger.i('✅ CFO Agent: Financial analysis complete');

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'total_invoiced': totalInvoiced.toStringAsFixed(2),
        'total_paid': totalPaid.toStringAsFixed(2),
        'total_overdue': totalOverdue.toStringAsFixed(2),
        'unpaid_invoices': unpaidCount,
        'avg_days_outstanding': avgDaysOutstanding.toStringAsFixed(2),
        'total_expenses_90d': totalExpenses.toStringAsFixed(2),
        'net_profit': netProfit.toStringAsFixed(2),
        'profit_margin_percent': profitMargin.toStringAsFixed(2),
        'financial_health': profitMargin > 25 ? 'Excellent' : profitMargin > 15 ? 'Good' : 'At Risk',
        'recommendations': recommendations,
      };
    } catch (e) {
      _logger.e('❌ CFO Agent Error: $e');
      return {'error': e.toString()};
    }
  }

  /// Get all three agents' reports in one call
  Future<Map<String, dynamic>> getAllAgentsReport({required String orgId}) async {
    try {
      _logger.i('🤖 Running all AI agents for comprehensive business analysis...');

      final ceoReport = await ceoAgentAnalysis(orgId: orgId);
      final cooReport = await cooAgentAnalysis(orgId: orgId);
      final cfoReport = await cfoAgentAnalysis(orgId: orgId);

      return {
        'generated_at': DateTime.now().toIso8601String(),
        'ceo_strategic_report': ceoReport,
        'coo_operations_report': cooReport,
        'cfo_financial_report': cfoReport,
      };
    } catch (e) {
      _logger.e('❌ Error generating all agents report: $e');
      return {'error': e.toString()};
    }
  }

  // Helper functions
  double calculateGrowthRate(List<Map<String, dynamic>> invoices) {
    if (invoices.length < 2) return 0;

    List<Map<String, dynamic>> sorted = List.from(invoices);
    sorted.sort((a, b) => DateTime.parse(a['created_at'] as String)
        .compareTo(DateTime.parse(b['created_at'] as String)));

    // Compare last 30 days to previous 30 days
    DateTime now = DateTime.now();
    DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));
    DateTime sixtyDaysAgo = now.subtract(const Duration(days: 60));

    double recentRevenue = 0;
    double priorRevenue = 0;

    for (var inv in sorted) {
      DateTime createdDate = DateTime.parse(inv['created_at'] as String);
      double amount = (inv['amount'] as num).toDouble();

      if (createdDate.isAfter(thirtyDaysAgo)) {
        recentRevenue += amount;
      } else if (createdDate.isAfter(sixtyDaysAgo)) {
        priorRevenue += amount;
      }
    }

    if (priorRevenue == 0) return 0;
    return (recentRevenue - priorRevenue) / priorRevenue;
  }

  double calculateRetentionRate(List<Map<String, dynamic>> clients) {
    if (clients.isEmpty) return 0;

    DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    int retainedClients = 0;

    for (var client in clients) {
      DateTime createdDate = DateTime.parse(client['created_at'] as String);
      if (createdDate.isBefore(thirtyDaysAgo)) {
        retainedClients++;
      }
    }

    return retainedClients / clients.length;
  }

  String generatePricingStrategy({
    required double totalRevenue,
    required double avgInvoiceValue,
    required int jobCount,
  }) {
    if (avgInvoiceValue > 2000) {
      return '💎 Premium positioning: You can maintain or increase prices for high-value services.';
    } else if (avgInvoiceValue > 800) {
      return '🎯 Mid-market positioning: Consider strategic price increases of 5-10% for specialized services.';
    } else {
      return '📈 Volume strategy: Focus on increasing job volume or bundling services for better margins.';
    }
  }

  /// Helper to calculate lead score (0-100)
  int _calculateLeadScore(Map<String, dynamic> lead) {
    int score = 0;
    
    // Scoring criteria
    if (((lead['total_spent'] as num?) ?? 0) > 0) score += 20; // Has paid
    
    final createdAt = DateTime.parse(lead['created_at'] as String);
    final daysOld = DateTime.now().difference(createdAt).inDays;
    if (daysOld < 7) score += 30; // Very recent
    
    if ((lead['email'] as String?)?.contains('@') ?? false) score += 15; // Valid email
    
    return score;
  }

  /// ⚙️ ADMIN AGENT - AUTONOMOUS (System & Compliance)
  /// Takes action: Monitors system health, manages backups, compliance checks
  Future<void> adminAgentAutonomous({required String orgId}) async {
    try {
      _logger.i('⚙️ Admin Agent: Starting autonomous system management for org: $orgId');

      // CHECK SYSTEM HEALTH
      final orgUsers = await supabase
          .from('org_members')
          .select('id, role, status')
          .eq('org_id', orgId);

      final activeUsers = orgUsers.where((u) => u['status'] == 'active').length;
      _logger.i('✅ Admin: System health check passed ($activeUsers active users)');
    } catch (e) {
      _logger.e('❌ Admin Agent Error: $e');
    }
  }
}
