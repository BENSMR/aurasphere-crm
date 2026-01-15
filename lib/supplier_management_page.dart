import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/supplier_ai_agent.dart';

/// 🏢 Supplier Management Hub
/// Unified interface for supplier control, pricing, and PO management
class SupplierManagementPage extends StatefulWidget {
  const SupplierManagementPage({super.key});

  @override
  State<SupplierManagementPage> createState() => _SupplierManagementPageState();
}

class _SupplierManagementPageState extends State<SupplierManagementPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  final supplierAiAgent = SupplierAiAgent();

  Map<String, dynamic> dashboard = {};
  bool loading = true;
  String? orgId;
  bool _isRefreshing = false; // ✅ Rate limiting guard

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return; // ✅ RATE LIMITING
    _isRefreshing = true;
    
    try {
      setState(() => loading = true);

      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        return;
      }

      // Get org_id
      final org = await supabase
          .from('organizations')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (org == null) {
        throw Exception('Organization not found');
      }

      orgId = org['id'] as String;

      // Load AI dashboard
      dashboard =
          await supplierAiAgent.getSupplierDashboard(orgId ?? '');

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() => loading = false);
      }
    } finally {
      _isRefreshing = false; // ✅ Always reset
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('🏢 Supplier Management')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'AI analyzing your suppliers...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'First analysis may take 10 seconds',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏢 Supplier Management Hub'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📊 Dashboard'),
            Tab(text: '🏢 Suppliers'),
            Tab(text: '💰 Pricing'),
            Tab(text: '📦 Purchase Orders'),
            Tab(text: '🤖 AI Agent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(colorScheme),
          _buildSuppliersTab(colorScheme),
          _buildPricingTab(colorScheme),
          _buildPurchaseOrdersTab(colorScheme),
          _buildAiAgentTab(colorScheme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loading || _isRefreshing ? null : _loadData,
        tooltip: 'Refresh AI Analysis',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // 📊 DASHBOARD TAB
  Widget _buildDashboard(ColorScheme colorScheme) {
    // ✅ SAFE NULL HANDLING
    final health = (dashboard['overall_health'] as Map?)?.cast<String, dynamic>() ?? {};
    final performance =
        (dashboard['supplier_performance'] as Map?)?.cast<String, dynamic>() ?? {};
    final deliveries =
        (dashboard['delivery_tracking'] as Map?)?.cast<String, dynamic>() ?? {};
    final reorders = (dashboard['reorder_suggestions'] as Map?)?.cast<String, dynamic>() ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Card
          _buildHealthCard(health, colorScheme),
          const SizedBox(height: 16),

          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.warning,
                  title: 'Delivery Alerts',
                  value:
                      '${deliveries['alerts']?.length ?? 0}',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.shopping_cart,
                  title: 'Urgent Reorders',
                  value:
                      '${reorders['urgent_count'] ?? 0}',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.trending_down,
                  title: 'Cost Savings',
                  value: 'Available',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delivery Alerts Section
          if ((deliveries['alerts'] as List?)?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ Delivery Alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...(deliveries['alerts'] as List).map((alert) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['supplier_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert['recommendation'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Due: ${alert['due_date']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),

          // Reorder Suggestions
          if ((reorders['suggestions'] as List?)?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📦 Reorder Suggestions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...(reorders['suggestions'] as List).take(5).map((suggestion) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion['product_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ${suggestion['recommended_order_quantity']} units',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(suggestion['urgency'] ?? 'Normal'),
                            backgroundColor: suggestion['urgency'] == 'URGENT'
                                ? Colors.red[100]
                                : Colors.orange[100],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // 🏢 SUPPLIERS TAB
  Widget _buildSuppliersTab(ColorScheme colorScheme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('suppliers')
          .select()
          .eq('org_id', orgId ?? '')
          .order('is_preferred', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final suppliers = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            FloatingActionButton.extended(
              onPressed: () => _showAddSupplierDialog(),
              label: const Text('Add Supplier'),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(height: 16),
            ...suppliers.map((supplier) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: supplier['is_preferred']
                      ? const Icon(Icons.star, color: Colors.amber)
                      : const Icon(Icons.business),
                  title: Text(supplier['name'] ?? 'Unknown'),
                  subtitle: Text(
                    'Rating: ${supplier['reliability_rating']}/5.0 • Lead: ${supplier['lead_time_days']} days',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditSupplierDialog(supplier),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // 💰 PRICING TAB
  Widget _buildPricingTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 Price Comparison Tool',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showPriceComparisonDialog,
            icon: const Icon(Icons.analytics),
            label: const Text('Compare Supplier Prices'),
          ),
          const SizedBox(height: 20),
          Text(
            'Price History & Trends',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase
                .from('supplier_price_history')
                .select()
                .eq('org_id', orgId ?? '')
                .order('created_at', ascending: false)
                .limit(10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return const Text('No price history available');
              }

              return Column(
                children: history
                    .map((entry) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['change_reason'] ?? 'Price Update',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Old: \$${entry['old_price']} → New: \$${entry['new_price']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(DateTime.parse(entry['created_at'])),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // 📦 PURCHASE ORDERS TAB
  Widget _buildPurchaseOrdersTab(ColorScheme colorScheme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase
          .from('purchase_orders')
          .select('*, suppliers(*)')
          .eq('org_id', orgId ?? '')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ElevatedButton.icon(
              onPressed: _showCreatePoDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Purchase Order'),
            ),
            const SizedBox(height: 16),
            ...orders.map((order) {
              final supplier = order['suppliers'] as Map<String, dynamic>?;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    'PO #${order['po_number']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplier?['name'] ?? 'Unknown Supplier'),
                      Text('\$${order['total_amount']}'),
                      Chip(
                        label: Text(order['status'] ?? 'pending'),
                        backgroundColor: _getStatusColor(order['status']),
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _showPoDetails(order),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  // 🤖 AI AGENT TAB
  Widget _buildAiAgentTab(ColorScheme colorScheme) {
    final insights = dashboard['ai_supplier_insights'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: colorScheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🤖 AI Agent Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The AI agent is actively monitoring your supplier ecosystem and generating proactive recommendations.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('✅ Performance Analysis'),
                        avatar: Icon(Icons.assessment),
                      ),
                      Chip(
                        label: Text('📦 Delivery Tracking'),
                        avatar: Icon(Icons.local_shipping),
                      ),
                      Chip(
                        label: Text('💰 Price Optimization'),
                        avatar: Icon(Icons.trending_down),
                      ),
                      Chip(
                        label: Text('🔔 Reorder Alerts'),
                        avatar: Icon(Icons.notifications_active),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '📋 AI-Generated Insights',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (insights.isEmpty)
            const Text('No insights available yet. Run AI analysis to generate recommendations.')
          else
            ...insights.take(5).map((insight) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              insight['title'] ?? 'Insight',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(insight['urgency'] ?? 'normal'),
                            backgroundColor:
                                _getUrgencyColor(insight['urgency']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insight['description'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (insight['action_recommended'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '💡 ${insight['action_recommended']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // HELPER METHODS

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final termsCtrl = TextEditingController(text: '30 days');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Supplier Name'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: termsCtrl,
                decoration: const InputDecoration(labelText: 'Payment Terms'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveSupplier(
              nameCtrl.text,
              emailCtrl.text,
              phoneCtrl.text,
              termsCtrl.text,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSupplier(
    String name,
    String email,
    String phone,
    String terms,
  ) async {
    try {
      await supabase.from('suppliers').insert({
        'org_id': orgId,
        'name': name,
        'email': email,
        'phone': phone,
        'payment_terms': terms,
      });

      if (mounted) {
        Navigator.pop(context);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Supplier added successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showEditSupplierDialog(Map<String, dynamic> supplier) {
    // Similar to _showAddSupplierDialog but with edit logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality - under development')),
    );
  }

  void _showPriceComparisonDialog() {
    // Price comparison dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compare Supplier Prices'),
        content: const Text(
          'Select a product to compare prices across all suppliers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCreatePoDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create PO dialog - under development')),
    );
  }

  void _showPoDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PO #${order['po_number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${order['status']}'),
            Text('Amount: \$${order['total_amount']}'),
            Text('Due: ${order['due_date']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'normal':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHealthCard(
    Map<String, dynamic> health,
    ColorScheme colorScheme,
  ) {
    final score = health['score'] as int? ?? 100;
    final status = health['status'] as String? ?? 'HEALTHY';

    return Card(
      color: _getHealthCardColor(score),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏥 Supplier Ecosystem Health',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $score/100',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthCardColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
