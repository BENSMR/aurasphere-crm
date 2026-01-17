import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPageSimple extends StatefulWidget {
  const DashboardPageSimple({super.key});

  @override
  State<DashboardPageSimple> createState() => _DashboardPageSimpleState();
}

class _DashboardPageSimpleState extends State<DashboardPageSimple> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text('Unauthorized')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AuraSphere'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Text(
              'Welcome, ${user.email}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Basic menu cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                // Jobs
                _MenuCard(
                  icon: Icons.work,
                  title: 'Jobs',
                  onTap: () => print('Jobs page'),
                ),
                // Invoices
                _MenuCard(
                  icon: Icons.receipt,
                  title: 'Invoices',
                  onTap: () => print('Invoices page'),
                ),
                // Clients
                _MenuCard(
                  icon: Icons.people,
                  title: 'Clients',
                  onTap: () => print('Clients page'),
                ),
                // Profile
                _MenuCard(
                  icon: Icons.account_circle,
                  title: 'Profile',
                  onTap: () => print('Profile page'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Simple info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Getting Started',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text('• View and manage your jobs'),
                  const Text('• Track your invoices'),
                  const Text('• Manage your clients'),
                  const Text('• Update your profile'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue.shade600),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
