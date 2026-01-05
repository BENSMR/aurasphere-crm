import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;
  bool _loading = true;
  String _totalRevenue = '\$0';
  String _activeJobs = '0';
  String _pendingInvoices = '0';
  String _teamMembers = '0';
  String _completionRate = '0%';
  String _avgInvoice = '\$0';
  String _newClients = '0';
  String _upcomingJobs = '0';
  String _expenses = '\$0';
  String _profitMargin = '0%';
  String _customerRating = '0/5';
  String _repeatRate = '0%';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for auth to be ready (important for web sessions)
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;
    
    print('🔍 Dashboard Auth Check - User: ${user?.email}, Session: ${session != null}');
    
    if (user == null || session == null) {
      print('❌ No auth found, redirecting to sign-in');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/sign-in');
      }
      return;
    }
    
    print('✅ Auth verified, loading dashboard data');
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get user's organization
      final orgData = await supabase
          .from('organizations')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();

      if (orgData == null) {
        setState(() => _loading = false);
        return;
      }

      final orgId = orgData['id'];

      // Fetch all required data in parallel
      final results = await Future.wait([
        _fetchTotalRevenue(orgId),
        _fetchActiveJobs(orgId),
        _fetchPendingInvoices(orgId),
        _fetchTeamMembers(orgId),
        _fetchCompletionRate(orgId),
        _fetchExpenses(orgId),
        _fetchNewClients(orgId),
        _fetchUpcomingJobs(orgId),
      ]);

      if (mounted) {
        setState(() {
          _totalRevenue = results[0];
          _activeJobs = results[1];
          _pendingInvoices = results[2];
          _teamMembers = results[3];
          _completionRate = results[4];
          _expenses = results[5];
          _newClients = results[6];
          _upcomingJobs = results[7];

          // Calculate derived metrics
          _avgInvoice = _calculateAvgInvoice(_totalRevenue, _pendingInvoices);
          _profitMargin = _calculateProfitMargin(_totalRevenue, _expenses);
          _customerRating = '4.8/5'; // Placeholder
          _repeatRate = '70%'; // Placeholder

          _loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String> _fetchTotalRevenue(String orgId) async {
    try {
      final result = await supabase
          .from('invoices')
          .select('amount')
          .eq('org_id', orgId)
          .eq('status', 'paid');

      final total = (result as List).fold<double>(
        0,
        (sum, invoice) => sum + (invoice['amount'] as num).toDouble(),
      );

      return '\$${total.toStringAsFixed(2)}';
    } catch (e) {
      print('❌ Error fetching total revenue: $e');
      return '\$0';
    }
  }

  Future<String> _fetchActiveJobs(String orgId) async {
    try {
      final result = await supabase
          .from('jobs')
          .select('id')
          .eq('org_id', orgId)
          .eq('status', 'in_progress');

      return result.length.toString();
    } catch (e) {
      print('❌ Error fetching active jobs: $e');
      return '0';
    }
  }

  Future<String> _fetchPendingInvoices(String orgId) async {
    try {
      final result = await supabase
          .from('invoices')
          .select('id')
          .eq('org_id', orgId)
          .eq('status', 'pending');

      return result.length.toString();
    } catch (e) {
      print('❌ Error fetching pending invoices: $e');
      return '0';
    }
  }

  Future<String> _fetchTeamMembers(String orgId) async {
    try {
      final result = await supabase
          .from('users')
          .select('id')
          .eq('org_id', orgId);

      return result.length.toString();
    } catch (e) {
      print('❌ Error fetching team members: $e');
      return '0';
    }
  }

  Future<String> _fetchCompletionRate(String orgId) async {
    try {
      final totalResult = await supabase
          .from('jobs')
          .select('id')
          .eq('org_id', orgId);

      final completedResult = await supabase
          .from('jobs')
          .select('id')
          .eq('org_id', orgId)
          .eq('status', 'completed');

      final total = totalResult.length;
      final completed = completedResult.length;

      final rate = total == 0 ? 0 : ((completed / total) * 100).toStringAsFixed(0);
      return '$rate%';
    } catch (e) {
      print('❌ Error fetching completion rate: $e');
      return '0%';
    }
  }

  Future<String> _fetchExpenses(String orgId) async {
    try {
      final result = await supabase
          .from('expenses')
          .select('amount')
          .eq('org_id', orgId);

      final total = (result as List).fold<double>(
        0,
        (sum, expense) => sum + (expense['amount'] as num).toDouble(),
      );

      return '\$${total.toStringAsFixed(2)}';
    } catch (e) {
      print('❌ Error fetching expenses: $e');
      return '\$0';
    }
  }

  Future<String> _fetchNewClients(String orgId) async {
    try {
      // Get new clients from the last 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final result = await supabase
          .from('clients')
          .select('id')
          .eq('org_id', orgId)
          .gte('created_at', thirtyDaysAgo.toIso8601String());

      return result.length.toString();
    } catch (e) {
      print('❌ Error fetching new clients: $e');
      return '0';
    }
  }

  Future<String> _fetchUpcomingJobs(String orgId) async {
    try {
      // Get jobs scheduled for the next 7 days
      final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));
      final result = await supabase
          .from('jobs')
          .select('id')
          .eq('org_id', orgId)
          .lte('scheduled_date', sevenDaysFromNow.toIso8601String())
          .gte('scheduled_date', DateTime.now().toIso8601String());

      return result.length.toString();
    } catch (e) {
      print('❌ Error fetching upcoming jobs: $e');
      return '0';
    }
  }

  String _calculateAvgInvoice(String revenue, String invoiceCount) {
    try {
      final revAmount = double.parse(revenue.replaceAll('\$', '').replaceAll(',', ''));
      final count = int.parse(invoiceCount);
      if (count == 0) return '\$0';
      return '\$${(revAmount / count).toStringAsFixed(2)}';
    } catch (e) {
      return '\$0';
    }
  }

  String _calculateProfitMargin(String revenue, String expenses) {
    try {
      final revAmount = double.parse(revenue.replaceAll('\$', '').replaceAll(',', ''));
      final expAmount = double.parse(expenses.replaceAll('\$', '').replaceAll(',', ''));
      if (revAmount == 0) return '0%';
      final margin = ((revAmount - expAmount) / revAmount) * 100;
      return '${margin.toStringAsFixed(0)}%';
    } catch (e) {
      return '0%';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final screenWidth = MediaQuery.of(context).size.width;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to view dashboard'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/sign-in'),
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0099FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Text(
                'Welcome back! 👋',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Here\'s a complete overview of your business metrics',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Key Metrics Grid
              _buildMetricsGrid(screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(double screenWidth) {
    int crossAxisCount = 1;
    if (screenWidth >= 600 && screenWidth < 1000) {
      crossAxisCount = 2;
    } else if (screenWidth >= 1000) {
      crossAxisCount = 4;
    }

    final metrics = [
      MetricData('Total Revenue', _totalRevenue, 'This month', Icons.trending_up, const Color(0xFF4CAF50)),
      MetricData('Active Jobs', _activeJobs, 'In progress', Icons.work_outline, const Color(0xFF2196F3)),
      MetricData('Pending Invoices', _pendingInvoices, 'Worth $_pendingInvoices items', Icons.receipt_long, const Color(0xFFFF9800)),
      MetricData('Team Members', _teamMembers, 'All active', Icons.people_outline, const Color(0xFF9C27B0)),
      MetricData('Completion Rate', _completionRate, 'This month', Icons.check_circle_outline, const Color(0xFF009688)),
      MetricData('Avg Invoice', _avgInvoice, 'Per invoice', Icons.payments_outlined, const Color(0xFF3F51B5)),
      MetricData('New Clients', _newClients, 'Last 30 days', Icons.person_add_outlined, const Color(0xFFE91E63)),
      MetricData('Upcoming Jobs', _upcomingJobs, 'Next 7 days', Icons.calendar_today_outlined, const Color(0xFF00BCD4)),
      MetricData('Expenses', _expenses, 'This month', Icons.receipt_outlined, const Color(0xFFFF5722)),
      MetricData('Profit Margin', _profitMargin, 'Revenue minus expenses', Icons.show_chart_outlined, const Color(0xFF8BC34A)),
      MetricData('Customer Rating', _customerRating, '25 reviews', Icons.star_outline, const Color(0xFFFFC107)),
      MetricData('Repeat Rate', _repeatRate, 'Strong loyalty', Icons.handshake_outlined, const Color(0xFF795548)),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 1.1,
      children: metrics.map((metric) => _buildMetricCard(metric)).toList(),
    );
  }

  Widget _buildMetricCard(MetricData metric) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metric.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  metric.icon,
                  color: metric.color,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  MetricData(this.title, this.value, this.subtitle, this.icon, this.color);
}
