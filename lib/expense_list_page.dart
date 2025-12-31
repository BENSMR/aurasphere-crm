// lib/expense_list_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/ocr_service.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> expenses = [];
  bool loading = true;
  final picker = ImagePicker();

  Future<void> _loadExpenses() async {
    setState(() => loading = true);
    try {
      final response = await supabase
          .from('expenses')
          .select()
          .order('created_at', ascending: false);
      if (mounted) {
        expenses = response;
        setState(() => loading = false);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _addExpense() async {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final currencyCtrl = TextEditingController(text: 'EUR');
    XFile? receiptImage;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
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
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final img = await picker.pickImage(source: ImageSource.camera);
                  if (img != null) {
                    if (mounted) setState(() => receiptImage = img);
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              if (receiptImage != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('✓ Receipt attached', style: TextStyle(color: Colors.green)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (descCtrl.text.trim().isEmpty || amountCtrl.text.isEmpty) return;
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;

              String? receiptPath;
              Map<String, dynamic>? ocrData;

              if (receiptImage != null) {
                try {
                  // Get user language preference
                  final prefs = await supabase
                      .from('user_preferences')
                      .select('language')
                      .eq('user_id', supabase.auth.currentUser!.id)
                      .maybeSingle();
                  final userLang = prefs?['language'] ?? 'en';

                  // Upload image
                  final bytes = await File(receiptImage!.path).readAsBytes();
                  final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  await supabase.storage.from('receipts').uploadBinary(fileName, bytes);
                  receiptPath = 'receipts/$fileName';

                  // Run OCR with user's language
                  ocrData = await OcrService.parseReceipt(bytes, userLang);
                  if (ocrData != null && ocrData['total'] != null) {
                    // Auto-fill amount from OCR if user left it empty
                    if (amountCtrl.text.isEmpty) {
                      amountCtrl.text = ocrData['total'].toString();
                    }
                    // Auto-fill description
                    if (descCtrl.text.trim().isEmpty && ocrData['vendor'] != null) {
                      descCtrl.text = 'Purchase at ${ocrData['vendor']}';
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Upload/OCR failed: $e')),
                    );
                  }
                  return;
                }
              }

              await supabase.from('expenses').insert({
                'description': descCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0,
                'currency': currencyCtrl.text,
                'receipt_url': receiptPath,
                'ocr_data': ocrData,
              });
              Navigator.pop(context);
              _loadExpenses();
            },
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
              ? const Center(child: Text('No expenses yet'))
              : ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return ListTile(
                      title: Text(exp['description']),
                      subtitle: Text('${exp['amount']} ${exp['currency']}'),
                      trailing: exp['receipt_url'] != null
                          ? const Icon(Icons.image, color: Colors.green)
                          : null,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}
