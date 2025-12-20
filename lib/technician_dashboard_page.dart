// lib/technician_dashboard_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_detail_page.dart';

class TechnicianDashboardPage extends StatefulWidget {
  const TechnicianDashboardPage({super.key});

  @override
  State<TechnicianDashboardPage> createState() => _TechnicianDashboardPageState();
}

class _TechnicianDashboardPageState extends State<TechnicianDashboardPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> myJobs = [];
  bool loading = true;

  Future<void> _loadMyJobs() async {
    setState(() => loading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('jobs')
          .select('*, clients(name)')
          .eq('assigned_to', userId)
          .inFilter('status', ['in_progress', 'pending'])
          .order('created_at', ascending: false);
      if (mounted) setState(() => myJobs = data as List<Map<String, dynamic>>);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      // Try online update
      await supabase
          .from('jobs')
          .update({'status': newStatus})
          .eq('id', jobId);
      _loadMyJobs(); // Refresh
    } catch (e) {
      // Queue for later sync
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_updates') ?? [];
      pending.add(jsonEncode({'job_id': jobId, 'status': newStatus, 'timestamp': DateTime.now().toIso8601String()}));
      await prefs.setStringList('pending_updates', pending);
      
      // Update local state optimistically
      setState(() {
        final jobIndex = myJobs.indexWhere((job) => job['id'] == jobId);
        if (jobIndex != -1) {
          myJobs[jobIndex]['status'] = newStatus;
        }
      });
      
      // Show offline message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline - will sync when connection restored'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMyJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyJobs,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : myJobs.isEmpty
              ? const Center(child: Text('No active jobs'))
              : ListView.builder(
                  itemCount: myJobs.length,
                  itemBuilder: (context, index) {
                    final job = myJobs[index];
                    final client = job['clients'] as Map<String, dynamic>?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Job header
                          ListTile(
                            title: Text(job['title']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job['address'] ?? 'No address'),
                                if (client != null) Text('Client: ${client['name']}'),
                              ],
                            ),
                            trailing: _buildStatusBadge(job['status']),
                          ),
                          
                          // Action buttons
                          if (job['status'] != 'completed') ...[
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (job['status'] == 'pending')
                                    ElevatedButton(
                                      onPressed: () => _updateJobStatus(job['id'], 'in_progress'),
                                      child: const Text('Start Job'),
                                    ),
                                  if (job['status'] == 'in_progress')
                                    ElevatedButton(
                                      onPressed: () => _showCompleteJobDialog(job),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Complete Job'),
                                    ),
                                  OutlinedButton(
                                    onPressed: () => _logMaterials(job),
                                    child: const Text('Log Materials'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'completed' ? Colors.green : 
                 status == 'in_progress' ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showCompleteJobDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job'),
        content: const Text('Mark this job as completed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateJobStatus(job['id'], 'completed');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _logMaterials(Map<String, dynamic> job) {
    // Navigate to material logging screen (reusing JobDetailPage)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailPage(
          jobId: job['id'],
          jobTitle: job['title'],
        ),
      ),
    );
  }
}
