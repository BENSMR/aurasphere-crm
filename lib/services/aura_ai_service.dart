// lib/services/aura_ai_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuraAiService {
  static final supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>?> parseCommand(String input, String userLang) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {
              'role': 'system',
              'content': _getSystemPrompt(userLang),
            },
            {'role': 'user', 'content': input}
          ],
          'temperature': 0.1,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final content = json['choices'][0]['message']['content'];
        // Extract JSON block
        final jsonMatch = RegExp(r'\{[^}]*\}').firstMatch(content);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!);
          // Validate and normalize fields
          if (parsed['action'] != null) {
            // Normalize field names
            if (parsed['client'] != null && parsed['client_name'] == null) {
              parsed['client_name'] = parsed['client'];
            }
            return parsed;
          }
        }
      }
      return null;
    } catch (e) {
      print('Groq error: $e');
      return null;
    }
  }

  static String _getSystemPrompt(String userLang) {
    final languageExamples = {
      'en': 'Example: {"action":"create_invoice","client":"Ahmed","amount":300,"currency":"AED"}',
      'fr': 'Exemple : {"action":"create_invoice","client":"Ahmed","amount":300,"currency":"AED"}',
      'it': 'Esempio: {"action":"create_invoice","client":"Ahmed","amount":300,"currency":"AED"}',
      'de': 'Beispiel: {"action":"create_invoice","client":"Ahmed","amount":300,"currency":"AED"}',
      'es': 'Ejemplo: {"action":"create_invoice","client":"Ahmed","amount":300,"currency":"AED"}',
      'mt': 'Eżempju: {"action":"create_invoice","client":"Ahmed","amount":300,"currency":"AED"}',
      'ar': 'مثال: {"action":"create_invoice","client":"أحمد","amount":300,"currency":"AED"}',
    };

    return '''
You are Aura, the proactive CRM assistant for Aurasphere.
User language: $userLang
SUPPORTED ACTIONS:
- create_invoice: when user mentions billing, invoice, facture, fattura, rechnung, فاتورة
- create_expense: when user mentions expense, receipt, dépense, spesa, spiża, مصروف
- create_client: when user mentions new client, customer, cliente, klijent, عميل
- list_invoices: when user wants to see invoices
- list_clients: when user wants to see clients
- list_expenses: when user wants to see expenses

SUPPORTED CURRENCIES:
- EUR (€), USD (\$), AED (د.إ), TND (د.ت), MAD (د.م.م)

RULES:
1. Return ONLY valid JSON - no explanations
2. Always include "action" field
3. For create_invoice: include "client", "amount", "currency"
4. For create_expense: include "description", "amount", "currency"
5. For create_client: include "name" and optionally "email"
6. For list actions: just include "action"
7. Never invent data - if unsure, omit field

${languageExamples[userLang] ?? languageExamples['en']}
''';
  }

  static Future<Map<String, dynamic>> executeAction(Map<String, dynamic> action) async {
    try {
      switch (action['action']) {
        case 'create_invoice':
          return await _createInvoice(action);
        case 'create_client':
          return await _createClient(action);
        case 'create_expense':
          return await _createExpense(action);
        case 'list_invoices':
          return await _listInvoices();
        case 'list_clients':
          return await _listClients();
        case 'list_expenses':
          return await _listExpenses();
        default:
          return {'success': false, 'error': 'Unknown action'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _createInvoice(Map<String, dynamic> action) async {
    // Find or create client
    final clientName = action['client_name'];
    var clientData = await supabase
        .from('clients')
        .select()
        .ilike('name', '%$clientName%')
        .maybeSingle();

    clientData ??= await supabase.from('clients').insert({
        'name': clientName,
        'email': '',
      }).select().single();

    // Generate invoice number
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Create invoice
    await supabase.from('invoices').insert({
      'invoice_number': invoiceNumber,
      'client_id': clientData['id'],
      'amount': action['amount'],
      'currency': action['currency'] ?? 'EUR',
      'status': 'pending',
    });

    return {
      'success': true,
      'message': 'Invoice $invoiceNumber created for ${action['amount']} ${action['currency'] ?? 'EUR'}'
    };
  }

  static Future<Map<String, dynamic>> _createClient(Map<String, dynamic> action) async {
    await supabase.from('clients').insert({
      'name': action['name'],
      'email': action['email'] ?? '',
    });
    return {'success': true, 'message': 'Client ${action['name']} created'};
  }

  static Future<Map<String, dynamic>> _createExpense(Map<String, dynamic> action) async {
    await supabase.from('expenses').insert({
      'description': action['description'],
      'amount': action['amount'],
      'currency': action['currency'] ?? 'EUR',
    });
    return {'success': true, 'message': 'Expense ${action['description']} created for ${action['amount']} ${action['currency'] ?? 'EUR'}'};
  }

  static Future<Map<String, dynamic>> _listInvoices() async {
    final data = await supabase
        .from('invoices')
        .select('*, clients(name)')
        .order('created_at', ascending: false)
        .limit(10);
    return {'success': true, 'data': data};
  }

  static Future<Map<String, dynamic>> _listClients() async {
    final data = await supabase
        .from('clients')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    return {'success': true, 'data': data};
  }

  static Future<Map<String, dynamic>> _listExpenses() async {
    final data = await supabase
        .from('expenses')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
    return {'success': true, 'data': data};
  }
}
