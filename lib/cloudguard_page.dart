// lib/cloudguard_page.dart
/// CloudGuard FinOps Dashboard
/// Tracks cloud waste, savings, and partner sales enablement
/// 28% → <10% waste reduction target
library;


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/cloud_expense_service.dart';
import 'services/waste_detection_service.dart';

class CloudGuardPage extends StatefulWidget {
  const CloudGuardPage({super.key});

  @override
  State<CloudGuardPage> createState() => _CloudGuardPageState();
}

class _CloudGuardPageState extends State<CloudGuardPage> {
  final supabase = Supabase.instance.client;
  final _cloudService = CloudExpenseService();
  final _wasteService = WasteDetectionService();

  late String orgId;
  bool _loading = true;
  bool _showConnectForm = false;

  // Form state
  final _providerController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    // Get org ID from user's organization
    try {
      final orgData = await supabase
          .from('organizations')
          .select('id')
          .eq('owner_id', supabase.auth.currentUser!.id)
          .single();

      orgId = orgData['id'] as String;

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('❌ Error loading org: $e');
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('☁️ CloudGuard'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Expenses'),
              Tab(text: 'Opportunities'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboard(),
            _buildExpenses(),
            _buildOpportunities(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Cards
        FutureBuilder<Map<String, dynamic>>(
          future: _wasteService.getWasteSummary(orgId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final summary = snapshot.data!;
            final monthlySavings = summary['total_monthly_savings'] as double? ?? 0;
            final annualSavings = summary['total_annual_savings'] as double? ?? 0;

            return Column(
              children: [
                // Waste Percentage Card
                Card(
                  elevation: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Cloud Waste',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              '28%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Target: <10%',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 200,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    widthFactor: 0.28,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Savings Cards Row
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Monthly Savings',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${monthlySavings.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Annual Savings',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${(annualSavings).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Critical Issues
                Card(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Critical Findings',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${summary['critical_findings']} issues',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((summary['critical_findings'] as int? ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '🚨 ${summary['critical_findings']} critical waste issues found. Review Opportunities tab.',
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '✅ No critical issues',
                            style: TextStyle(color: Colors.green[700]),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Connect Cloud Account
        const Text(
          'Cloud Accounts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _cloudService.getCloudConnections(orgId),
          builder: (context, snapshot) {
            final connections = snapshot.data ?? [];

            if (connections.isEmpty) {
              return Column(
                children: [
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_upload, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text('No cloud accounts connected'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _showConnectForm = true);
                            },
                            child: const Text('+ Connect AWS/Azure/GCP'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                for (final conn in connections)
                  _buildConnectionCard(conn),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _showConnectForm = true);
                  },
                  child: const Text('+ Add Another Account'),
                ),
              ],
            );
          },
        ),

        if (_showConnectForm) ...[
          const SizedBox(height: 24),
          _buildConnectForm(),
        ],
      ],
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          connection['provider'] == 'aws'
              ? Icons.cloud
              : Icons.cloud_circle,
          color: Colors.blue,
        ),
        title: Text(connection['account_name'] as String? ?? 'Unknown'),
        subtitle: Text('${connection['account_id']} • ${connection['provider']?.toUpperCase()}'),
        trailing: Icon(
          connection['sync_status'] == 'success' ? Icons.check_circle : Icons.sync,
          color: connection['sync_status'] == 'success' ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildConnectForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect Cloud Provider',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _providerController.text.isEmpty ? null : _providerController.text,
              items: const [
                DropdownMenuItem(value: 'aws', child: Text('AWS')),
                DropdownMenuItem(value: 'azure', child: Text('Microsoft Azure')),
                DropdownMenuItem(value: 'gcp', child: Text('Google Cloud')),
              ],
              onChanged: (value) {
                if (value != null) {
                  _providerController.text = value;
                }
              },
              decoration: InputDecoration(
                labelText: 'Cloud Provider',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNameController,
              decoration: InputDecoration(
                labelText: 'Account Name (e.g., "Production")',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountIdController,
              decoration: InputDecoration(
                labelText: 'Account ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiSecretController,
              decoration: InputDecoration(
                labelText: 'API Secret',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await _cloudService.connectCloudAccount(
                        orgId: orgId,
                        provider: _providerController.text,
                        accountName: _accountNameController.text,
                        accountId: _accountIdController.text,
                        apiKey: _apiKeyController.text,
                        apiSecret: _apiSecretController.text,
                      );

                      if (result['success'] == true) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✅ Account connected!')),
                          );
                          setState(() {
                            _showConnectForm = false;
                            _accountNameController.clear();
                            _accountIdController.clear();
                            _apiKeyController.clear();
                            _apiSecretController.clear();
                          });
                        }
                      }
                    },
                    child: const Text('Connect Account'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() => _showConnectForm = false);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenses() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _cloudService.getMonthlyExpenses(orgId: orgId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenses = snapshot.data!;

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No expenses yet. Connect a cloud account to start.'),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final expense in expenses)
              _buildExpenseCard(expense),
          ],
        );
      },
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final total = expense['total_cost'] as double? ?? 0;
    final waste = expense['estimated_waste_cost'] as double? ?? 0;
    final wastePercent = expense['waste_percentage'] as double? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(expense['month'] ?? 'Unknown'),
        subtitle: Text('\$${total.toStringAsFixed(2)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${wastePercent.toStringAsFixed(1)}% waste',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Cost:'),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Potential Waste:'),
                    Text(
                      '\$${waste.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunities() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _wasteService.getWasteFindingsByOrg(orgId: orgId, status: 'open'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final findings = snapshot.data!;

        if (findings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                const SizedBox(height: 16),
                const Text('✅ No waste opportunities found!'),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final finding in findings)
              _buildFindingCard(finding),
          ],
        );
      },
    );
  }

  Widget _buildFindingCard(Map<String, dynamic> finding) {
    final severity = finding['severity'] as String? ?? 'medium';
    final severityColor = severity == 'critical'
        ? Colors.red
        : severity == 'high'
            ? Colors.orange
            : Colors.yellow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: severityColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(finding['resource_name'] as String? ?? 'Unknown'),
        subtitle: Text(
          'Save \$${(finding['potential_monthly_savings'] as num? ?? 0).toStringAsFixed(0)}/month',
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  finding['description'] as String? ?? 'No description',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recommendation:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        finding['recommendation'] as String? ?? 'No recommendation',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _wasteService.markAsFixed(finding['id'] as String);
                          if (mounted) setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Mark as Fixed'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _wasteService.dismissFinding(
                            findingId: finding['id'] as String,
                            reason: 'Not applicable',
                          );
                          if (mounted) setState(() {});
                        },
                        child: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _providerController.dispose();
    _accountNameController.dispose();
    _accountIdController.dispose();
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }
}
