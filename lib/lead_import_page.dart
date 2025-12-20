// lib/lead_import_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'performance_invoice_page.dart';

class LeadImportPage extends StatefulWidget {
  const LeadImportPage({super.key});

  @override
  State<LeadImportPage> createState() => _LeadImportPageState();
}

class _LeadImportPageState extends State<LeadImportPage> {
  final supabase = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _source = 'manual';
  List<Map<String, dynamic>> leads = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() => loading = true);
    try {
      final org = await supabase.from('organizations').select('id').single();
      final data = await supabase
          .from('leads')
          .select()
          .eq('org_id', org['id'])
          .order('created_at', ascending: false)
          .limit(20);
      if (mounted) setState(() => leads = data as List<Map<String, dynamic>>);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _importLead() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    
    final org = await supabase.from('organizations').select('id').single();
    await supabase.from('leads').insert({
      'org_id': org['id'],
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'source': _source,
      'status': 'new',
    });
    
    // Clear form
    _nameCtrl.clear(); _emailCtrl.clear(); _phoneCtrl.clear();
    
    // Reload leads
    _loadLeads();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead imported!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Leads')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Import form
                  TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
                  TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                  TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                  
                  // Source picker
                  DropdownButtonFormField<String>(
                    value: _source,
                    items: const [
                      DropdownMenuItem(value: 'facebook', child: Text('Facebook')),
                      DropdownMenuItem(value: 'instagram', child: Text('Instagram')),
                      DropdownMenuItem(value: 'linkedin', child: Text('LinkedIn')),
                      DropdownMenuItem(value: 'email', child: Text('Email Campaign')),
                      DropdownMenuItem(value: 'manual', child: Text('Manual Entry')),
                    ],
                    onChanged: (val) => setState(() => _source = val!),
                    decoration: const InputDecoration(labelText: 'Lead Source'),
                  ),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _importLead,
                    child: const Text('Import Lead'),
                  ),
                  
                  // Bulk import hint
                  const SizedBox(height: 24),
                  const Text('💡 Tip: Copy-paste from Facebook Leads, email lists, or WhatsApp'),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Recent leads list
                  const Text('Recent Leads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  if (leads.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No leads yet. Import your first lead above!'),
                      ),
                    )
                  else
                    ...leads.map((lead) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(lead['name']?[0]?.toUpperCase() ?? '?'),
                        ),
                        title: Text(lead['name'] ?? 'Unnamed'),
                        subtitle: Text('${lead['source']} • ${lead['status']}'),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.receipt_long, size: 16),
                          label: const Text('Invoice'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PerformanceInvoicePage(
                                  leadId: lead['id'],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )),
                ],
              ),
            ),
    );
  }
}
