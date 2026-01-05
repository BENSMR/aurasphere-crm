// lib/invoice_list_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/pdf_service.dart';
import 'package:printing/printing.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> clients = [];
  bool loading = true;
  bool showExplanations = true; // Feature flag

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      final invResponse = await supabase
          .from('invoices')
          .select('*, clients(name)')
          .order('created_at', ascending: false);
      final clientResponse = await supabase.from('clients').select();
      
      // Check feature preferences
      bool explanationsEnabled = true;
      try {
        final prefs = await supabase
            .from('user_preferences')
            .select('features')
            .eq('user_id', supabase.auth.currentUser!.id)
            .single();
        final features = prefs['features'] as Map<String, dynamic>?;
        explanationsEnabled = features?['human_explanations'] == true;
      } catch (e) {
        // Use default
      }
      
      if (mounted) {
        invoices = invResponse;
        clients = clientResponse;
        showExplanations = explanationsEnabled;
        setState(() => loading = false);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _downloadInvoicePdf(Map<String, dynamic> invoice) async {
    try {
      // Get user language
      final prefs = await supabase
          .from('user_preferences')
          .select('language')
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();
      final userLang = prefs?['language'] ?? 'en';

      // Get client details
      final client = invoice['clients'] as Map<String, dynamic>?;
      final clientName = client?['name'] ?? 'Unknown Client';

      // Generate PDF file
      final pdfFile = await PdfService.generateInvoice(
        invoiceNumber: invoice['invoice_number'] ?? invoice['number'] ?? 'N/A',
        clientName: clientName,
        amount: (invoice['amount'] as num).toDouble(),
        currency: invoice['currency'] ?? 'EUR',
        language: userLang,
        dueDate: invoice['due_date'] != null ? DateTime.parse(invoice['due_date']) : null,
      );

      // Share/Print PDF (works on web and mobile)
      await Printing.sharePdf(
        bytes: await pdfFile.readAsBytes(),
        filename: 'invoice_${invoice['invoice_number'] ?? invoice['number']}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ready to download')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF generation failed: $e')),
        );
      }
    }
  }

  Future<void> _createInvoice() async {
    final amountCtrl = TextEditingController();
    final currencyCtrl = TextEditingController(text: 'EUR');
    String? selectedClientId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Invoice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Client picker
              DropdownButtonFormField<String>(
                hint: const Text('Select client'),
                initialValue: selectedClientId,
                items: clients.map((c) => DropdownMenuItem<String>(
                  value: c['id'].toString(),
                  child: Text(c['name'] ?? 'Unnamed'),
                )).toList(),
                onChanged: (val) => setState(() => selectedClientId = val),
              ),
              // Amount
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              // Currency
              DropdownButtonFormField<String>(
                initialValue: currencyCtrl.text,
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                  DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                  DropdownMenuItem(value: 'AED', child: Text('د.إ AED')),
                  DropdownMenuItem(value: 'TND', child: Text('د.ت TND')),
                  DropdownMenuItem(value: 'MAD', child: Text('د.م. MAD')),
                ],
                onChanged: (val) => currencyCtrl.text = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedClientId == null || amountCtrl.text.isEmpty) return;
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;

              try {
                // Get user language
                final prefs = await supabase
                    .from('user_preferences')
                    .select('language')
                    .eq('user_id', supabase.auth.currentUser!.id)
                    .maybeSingle();
                final userLang = prefs?['language'] ?? 'en';

                // Get client name
                final selectedClient = clients.firstWhere((c) => c['id'].toString() == selectedClientId);
                final clientName = selectedClient['name'] ?? 'Unknown';

                // Generate invoice number
                final now = DateTime.now();
                final number = 'INV-${now.year}-${(invoices.length + 1).toString().padLeft(3, '0')}';
                final dueDate = DateTime(now.year, now.month + 1, 1);

                // Create invoice in DB
                final newInvoice = await supabase.from('invoices').insert({
                  'client_id': selectedClientId,
                  'invoice_number': number,
                  'amount': amount,
                  'currency': currencyCtrl.text,
                  'due_date': dueDate.toIso8601String(),
                  'status': 'pending',
                }).select().single();

                // Generate PDF
                final pdfFile = await PdfService.generateInvoice(
                  invoiceNumber: number,
                  clientName: clientName,
                  amount: amount,
                  currency: currencyCtrl.text,
                  language: userLang,
                  dueDate: dueDate,
                );

                // Upload PDF to Supabase Storage
                final pdfBytes = await pdfFile.readAsBytes();
                await supabase.storage
                    .from('invoices')
                    .uploadBinary('invoice_.pdf', pdfBytes);

                // Update invoice with PDF URL
                await supabase.from('invoices').update({
                  'pdf_url': 'invoices/invoice_${newInvoice['id']}.pdf',
                }).eq('id', newInvoice['id']);

                Navigator.pop(context);
                _loadData();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invoice created with PDF')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating invoice: $e')),
                  );
                }
              }
            },
            child: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }

  void _showExplanation(String metric, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Why $metric?'),
          ],
        ),
        content: Text(
          explanation,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    final totalAmount = invoices.fold<double>(0, (sum, inv) => sum + (inv['amount'] as num).toDouble());
    final paidAmount = invoices
        .where((inv) => inv['status'] == 'paid')
        .fold<double>(0, (sum, inv) => sum + (inv['amount'] as num).toDouble());
    final pendingAmount = totalAmount - paidAmount;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Metrics section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric(
                            'Total',
                            '€${totalAmount.toStringAsFixed(2)}',
                            'Total represents all invoices created, both paid and pending. This is your gross revenue.',
                          ),
                          _buildMetric(
                            'Paid',
                            '€${paidAmount.toStringAsFixed(2)}',
                            'Paid shows confirmed revenue. Money that\'s already in your account.',
                          ),
                          _buildMetric(
                            'Pending',
                            '€${pendingAmount.toStringAsFixed(2)}',
                            'Pending represents invoices awaiting payment. Track these closely to maintain cash flow.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Invoice list
                Expanded(
                  child: invoices.isEmpty
                      ? const Center(child: Text('No invoices yet'))
                      : ListView.builder(
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                    final inv = invoices[index];
                    final client = inv['clients'] as Map<String, dynamic>?;
                    return ListTile(
                      title: Text(inv['invoice_number'] ?? inv['number'] ?? 'N/A'),
                      subtitle: Text(
                        '${inv['amount']} ${inv['currency']} • ${client?['name'] ?? '—'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (inv['pdf_url'] != null)
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                              tooltip: 'View PDF',
                              onPressed: () async {
                                try {
                                  // Download PDF from storage
                                  final pdfPath = inv['pdf_url'] as String;
                                  final fileName = pdfPath.split('/').last;
                                  final bytes = await supabase.storage
                                      .from('invoices')
                                      .download(fileName);
                                  
                                  // Open PDF using printing package
                                  await Printing.layoutPdf(
                                    onLayout: (_) async => bytes,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to open PDF: $e')),
                                    );
                                  }
                                }
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.grey),
                              tooltip: 'Generate PDF',
                              onPressed: () => _downloadInvoicePdf(inv),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: inv['status'] == 'paid' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              (inv['status'] ?? 'pending').toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createInvoice,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMetric(String label, String value, String explanation) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (showExplanations)
              IconButton(
                icon: const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showExplanation(label, explanation),
              ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }
}
