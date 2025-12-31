// lib/job_list_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'job_detail_page.dart';
import 'inventory_page.dart';

class JobListPage extends StatefulWidget {
  const JobListPage({super.key});

  @override
  State<JobListPage> createState() => _JobListPageState();
}

class _JobListPageState extends State<JobListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> jobs = [];
  List<Map<String, dynamic>> lowStockItems = [];
  bool loading = true;
  String? userType; // 'freelancer' or 'trades'

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => loading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      // Fetch user type from preferences
      try {
        final userPrefs = await supabase
            .from('user_preferences')
            .select('business_type')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (mounted) {
          setState(() => userType = userPrefs?['business_type']);
        }
      } catch (e) {
        // Column might not exist yet, default to null
        print('Could not fetch business_type: $e');
        if (mounted) {
          setState(() => userType = null);
        }
      }
      
      // Check if user is an organization owner or team member
      final org = await supabase
          .from('organizations')
          .select('id, owner_id')
          .eq('owner_id', userId)
          .maybeSingle();
      
      final isOwner = org != null;
      
      // Load jobs based on role
      final dynamic data;
      if (isOwner) {
        // Owner sees all organization jobs
        data = await supabase
            .from('jobs')
            .select('*, clients(name)')
            .eq('org_id', org['id'])
            .order('created_at', ascending: false);
      } else {
        // Team member sees only their assigned jobs
        data = await supabase
            .from('jobs')
            .select('*, clients(name)')
            .eq('assigned_to', userId)
            .order('created_at', ascending: false);
      }
      
      if (mounted) setState(() => jobs = data as List<Map<String, dynamic>>);
      
      // Also load low stock items (only for owners)
      if (isOwner) {
        await _getLowStockItems();
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _getLowStockItems() async {
    try {
      final org = await supabase.from('organizations').select('id').single();
      final allInventory = await supabase
          .from('inventory')
          .select()
          .eq('org_id', org['id']);
      
      // Filter items where quantity < min_stock
      final lowStock = (allInventory)
          .where((item) => (item['quantity'] as num) < (item['min_stock'] as num))
          .toList();
      
      if (mounted) {
        setState(() => lowStockItems = lowStock);
      }
    } catch (e) {
      // Silently fail if inventory table doesn't exist or user doesn't have access
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.blue;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }
  
  // Helper to get correct label based on user type
  String _getLabel(BuildContext context, String key) {
    // For freelancers, use 'project' variants, otherwise 'job'
    if (userType == 'freelancer') {
      if (key == 'jobs') return 'Projects'; // Fallback if no localization
      if (key == 'job') return 'Project';
      if (key == 'new_job') return 'New Project';
      if (key == 'job_detail') return 'Project Details';
    }
    // Default to job labels for trades
    if (key == 'jobs') return 'Jobs';
    if (key == 'job') return 'Job';
    if (key == 'new_job') return 'New Job';
    if (key == 'job_detail') return 'Job Details';
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getLabel(context, 'jobs')),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Low stock alert banner
                if (lowStockItems.isNotEmpty)
                  Container(
                    color: Colors.red.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${lowStockItems.length} item${lowStockItems.length > 1 ? 's' : ''} below min stock!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InventoryPage()),
                          ),
                          child: const Text('View Inventory'),
                        ),
                      ],
                    ),
                  ),
                // Jobs list
                Expanded(
                  child: jobs.isEmpty
                      ? Center(
                          child: Text('No ${_getLabel(context, 'jobs').toLowerCase()} yet'),
                        )
                      : ListView.builder(
                          itemCount: jobs.length,
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            final client = job['clients'] as Map<String, dynamic>?;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(job['status']),
                                  child: Icon(
                                    job['status'] == 'completed' 
                                        ? Icons.check 
                                        : Icons.work,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(job['title']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(job['address'] ?? 'No address'),
                                    if (client != null) Text('Client: ${client['name']}'),
                                    const SizedBox(height: 8),
                                    // Status dropdown
                                    DropdownButton<String>(
                                      value: job['status'],
                                      isExpanded: true,
                                      isDense: true,
                                      items: const [
                                        DropdownMenuItem(value: 'pending', child: Text('⏳ Pending')),
                                        DropdownMenuItem(value: 'in_progress', child: Text('🔨 In Progress')),
                                        DropdownMenuItem(value: 'completed', child: Text('✅ Completed')),
                                        DropdownMenuItem(value: 'cancelled', child: Text('❌ Cancelled')),
                                      ],
                                      onChanged: (status) async {
                                        if (status == null) return;
                                        try {
                                          await supabase
                                              .from('jobs')
                                              .update({'status': status})
                                              .eq('id', job['id']);
                                          _loadJobs(); // Reload to update UI
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Status updated to ${status.replaceAll('_', ' ')}'),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to update status: $e')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => JobDetailPage(
                                        jobId: job['id'],
                                        jobTitle: job['title'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddJobDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddJobDialog() {
    final titleCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final clientCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getLabel(context, 'new_job')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Job Title')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: clientCtrl, decoration: const InputDecoration(labelText: 'Client Name')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              
              // Get org_id from user's org
              final org = await supabase.from('organizations').select('id').single();
              
              // Create client if needed
              Map<String, dynamic>? client;
              if (clientCtrl.text.trim().isNotEmpty) {
                final clientResp = await supabase.from('clients').insert({
                  'org_id': org['id'],
                  'name': clientCtrl.text.trim(),
                }).select().single();
                client = clientResp;
              }

              await supabase.from('jobs').insert({
                'org_id': org['id'],
                'client_id': client?['id'],
                'title': titleCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'status': 'pending',
              });
              Navigator.pop(context);
              _loadJobs();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
