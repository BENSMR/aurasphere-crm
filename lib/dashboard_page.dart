import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/sign-in');
      }
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
      MetricData('Total Revenue', '\$12,450', 'This month', Icons.trending_up, const Color(0xFF4CAF50)),
      MetricData('Active Jobs', '8', 'In progress', Icons.work_outline, const Color(0xFF2196F3)),
      MetricData('Pending Invoices', '5', 'Worth \$3,200', Icons.receipt_long, const Color(0xFFFF9800)),
      MetricData('Team Members', '4', 'All active', Icons.people_outline, const Color(0xFF9C27B0)),
      MetricData('Completion Rate', '94%', 'This month', Icons.check_circle_outline, const Color(0xFF009688)),
      MetricData('Avg Invoice', '\$640', 'Up 12% MoM', Icons.payments_outlined, const Color(0xFF3F51B5)),
      MetricData('New Clients', '3', 'This month', Icons.person_add_outlined, const Color(0xFFE91E63)),
      MetricData('Upcoming Jobs', '12', 'Next 7 days', Icons.calendar_today_outlined, const Color(0xFF00BCD4)),
      MetricData('Expenses', '\$2,340', 'This month', Icons.receipt_outlined, const Color(0xFFFF5722)),
      MetricData('Profit Margin', '68%', 'Excellent', Icons.show_chart_outlined, const Color(0xFF8BC34A)),
      MetricData('Customer Rating', '4.8/5', '25 reviews', Icons.star_outline, const Color(0xFFFFC107)),
      MetricData('Repeat Rate', '70%', 'Strong loyalty', Icons.handshake_outlined, const Color(0xFF795548)),
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
