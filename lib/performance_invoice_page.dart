// lib/performance_invoice_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceInvoicePage extends StatefulWidget {
  final String? clientId;
  final String? jobId;
  final String? leadId;

  const PerformanceInvoicePage({
    super.key,
    this.clientId,
    this.jobId,
    this.leadId,
  });

  @override
  State<PerformanceInvoicePage> createState() => _PerformanceInvoicePageState();
}

class _PerformanceInvoicePageState extends State<PerformanceInvoicePage> {
  final supabase = Supabase.instance.client;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _currency = 'USD';
  String? _selectedClientId;
  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> jobs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final org = await supabase.from('organizations').select('id').single();
    
    // Load clients
    final clientData = await supabase
        .from('clients')
        .select()
        .eq('org_id', org['id']);
    setState(() => clients = clientData as List<Map<String, dynamic>>);
    
    // Load jobs (for line item suggestions)
    if (widget.jobId != null) {
      final jobData = await supabase
          .from('jobs')
          .select()
          .eq('id', widget.jobId!);
      if (jobData.isNotEmpty) {
        setState(() => jobs = [jobData.first]);
        _descCtrl.text = 'Service for ${jobData.first['title']}';
      }
    }
    
    // Pre-populate description from lead source
    if (widget.leadId != null) {
      final lead = await supabase.from('leads').select().eq('id', widget.leadId!).single();
      final source = lead['source'] as String?;
      if (source == 'facebook') {
        _descCtrl.text = 'Service inquiry from Facebook';
      } else if (source == 'instagram') {
        _descCtrl.text = 'Service inquiry from Instagram';
      } else if (source == 'linkedin') {
        _descCtrl.text = 'Service inquiry from LinkedIn';
      } else if (source == 'email_campaign') {
        _descCtrl.text = 'Service inquiry from Email Campaign';
      } else if (source == 'manual') {
        _descCtrl.text = 'Manual lead conversion';
      }
    }
    
    // Pre-select client if provided
    if (widget.clientId != null) {
      setState(() => _selectedClientId = widget.clientId);
    }
  }

  Future<void> _createInvoice() async {
    if (_selectedClientId == null || _amountCtrl.text.isEmpty) return;
    
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    
    // Generate payment link (Stripe)
    final paymentLink = 'https://buy.stripe.com/invoice_${DateTime.now().millisecondsSinceEpoch}';
    
    // Auto-generate invoice number
    final now = DateTime.now();
    final number = 'INV-${now.year}-${DateTime.now().millisecondsSinceEpoch}';
    
    final org = await supabase.from('organizations').select('id').single();
    await supabase.from('invoices').insert({
      'org_id': org['id'],
      'client_id': _selectedClientId,
      'lead_id': widget.leadId,
      'job_id': widget.jobId,
      'number': number,
      'amount': amount,
      'currency': _currency,
      'status': 'sent',
      'due_date': DateTime(now.year, now.month + 1, 1).toIso8601String(),
      'sent_at': DateTime.now().toIso8601String(),
      'payment_link': paymentLink,
      'line_items': [
        {
          'desc': _descCtrl.text.isEmpty ? 'Service' : _descCtrl.text,
          'amount': amount,
          'qty': 1,
        }
      ],
    });
    
    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Client picker
            DropdownButtonFormField<String>(
              value: _selectedClientId,
              items: clients.map((c) => DropdownMenuItem<String>(
                value: c['id'] as String,
                child: Text(c['name'] ?? 'Unnamed'),
              )).toList(),
              onChanged: (val) => setState(() => _selectedClientId = val),
              decoration: const InputDecoration(labelText: 'Client *'),
            ),
            
            // Description
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            
            // Amount
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            
            // Currency
            DropdownButtonFormField<String>(
              value: _currency,
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                DropdownMenuItem(value: 'AED', child: Text('AED')),
                DropdownMenuItem(value: 'TND', child: Text('TND')),
                DropdownMenuItem(value: 'MAD', child: Text('MAD')),
              ],
              onChanged: (val) => setState(() => _currency = val!),
              decoration: const InputDecoration(labelText: 'Currency'),
            ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createInvoice,
              child: const Text('Send Performance Invoice'),
            ),
            
            // Performance tips
            const SizedBox(height: 24),
            const Card(
              child: ListTile(
                leading: Icon(Icons.analytics, color: Colors.blue),
                title: Text('💡 Performance Tip'),
                subtitle: Text('Link to a job or lead to track ROI and client behavior.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
