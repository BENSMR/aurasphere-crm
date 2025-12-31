// lib/dispatch_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> unassignedJobs = [];
  List<Map<String, dynamic>> teamMembers = [];
  bool loading = true;

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final org = await supabase.from('organizations').select('id').single();
      
      // Get unassigned jobs
      final jobs = await supabase
          .from('jobs')
          .select('*, clients(name)')
          .eq('org_id', org['id'])
          .isFilter('assigned_to', null)
          .eq('status', 'pending');
      
      // Get team members (excluding owner)
      final members = await supabase
          .from('org_members')
          .select('user_id, users(email)')
          .eq('org_id', org['id'])
          .neq('role', 'owner');
      
      if (mounted) {
        setState(() {
          unassignedJobs = jobs;
          teamMembers = members;
          loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _assignJob(String jobId, String userId) async {
    await supabase
        .from('jobs')
        .update({'assigned_to': userId, 'status': 'in_progress'})
        .eq('id', jobId);
    _loadData(); // Refresh list
  }

  Future<void> _autoAssignJob(String jobId) async {
    try {
      final org = await supabase.from('organizations').select('id').single();
      
      // Get all active jobs per technician
      final allJobs = await supabase
          .from('jobs')
          .select('assigned_to')
          .eq('org_id', org['id'])
          .inFilter('status', ['pending', 'in_progress']);
      
      // Count jobs per technician
      final workload = <String, int>{};
      for (final member in teamMembers) {
        workload[member['user_id']] = 0;
      }
      
      for (final job in allJobs) {
        final assignedTo = job['assigned_to'];
        if (assignedTo != null && workload.containsKey(assignedTo)) {
          workload[assignedTo] = (workload[assignedTo] ?? 0) + 1;
        }
      }
      
      // Find technician with fewest jobs
      String? leastBusyTechnician;
      int minJobs = 999999;
      workload.forEach((userId, count) {
        if (count < minJobs) {
          minJobs = count;
          leastBusyTechnician = userId;
        }
      });
      
      if (leastBusyTechnician != null) {
        await _assignJob(jobId, leastBusyTechnician!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job auto-assigned to least busy technician')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to auto-assign: $e')),
        );
      }
    }
  }

  String _getTechnicianEmail(String userId) {
    // Simple email from user ID (in real app, fetch from auth.users)
    return 'technician@workshop.com'; // TODO: Fetch real email
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispatch Jobs')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : unassignedJobs.isEmpty
              ? const Center(child: Text('No jobs to dispatch'))
              : ListView.builder(
                  itemCount: unassignedJobs.length,
                  itemBuilder: (context, jobIndex) {
                    final job = unassignedJobs[jobIndex];
                    final client = job['clients'] as Map<String, dynamic>?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text(job['title']),
                        subtitle: Text(client?['name'] ?? 'No client'),
                        children: [
                          // Auto-assign button
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton.icon(
                              onPressed: () => _autoAssignJob(job['id']),
                              icon: const Icon(Icons.auto_fix_high),
                              label: const Text('Auto-Assign to Least Busy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const Divider(),
                          // Team member list
                          ...teamMembers.map((member) {
                            final user = member['users'] as Map<String, dynamic>?;
                            return ListTile(
                              title: Text(user?['email'] ?? 'Team Member'),
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              onTap: () => _assignJob(job['id'], member['user_id']),
                              trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
