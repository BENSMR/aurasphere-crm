// services/recurring_invoice_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'pdf_service.dart';

final _logger = Logger();

class RecurringInvoiceService {
  // Lazy load Supabase only when needed
  static SupabaseClient get supabase => Supabase.instance.client;
  
  /// Create a recurring invoice schedule
  static Future<void> createRecurringSchedule({
    required String clientId,
    required double amount,
    required String currency,
    required String frequency, // 'daily', 'weekly', 'monthly', 'yearly'
    required DateTime startDate,
    DateTime? endDate,
    String? description,
  }) async {
    final org = await supabase.from('organizations').select('id').single();
    
    await supabase.from('recurring_invoices').insert({
      'org_id': org['id'],
      'client_id': clientId,
      'amount': amount,
      'currency': currency,
      'frequency': frequency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'description': description,
      'status': 'active',
      'next_run_date': startDate.toIso8601String(),
    });
  }
  
  /// Process all due recurring invoices
  static Future<void> processDueInvoices() async {
    _logger.d('Processing recurring invoices...');
    
    final org = await supabase.from('organizations').select('id').maybeSingle();
    if (org == null) return;
    
    // Get all active recurring invoices where next_run_date <= now
    final dueInvoices = await supabase
        .from('recurring_invoices')
        .select('*, clients(name, email)')
        .eq('org_id', org['id'])
        .eq('status', 'active')
        .lte('next_run_date', DateTime.now().toIso8601String());
    
    for (final recurring in dueInvoices) {
      try {
        await _generateInvoice(recurring);
        await _updateNextRunDate(recurring);
      } catch (e) {
        _logger.e('Failed to process recurring invoice ${recurring['id']}: $e');
      }
    }
    
    _logger.i('Recurring invoices processed');
  }
  
  /// Generate a single invoice from recurring schedule
  static Future<void> _generateInvoice(Map<String, dynamic> recurring) async {
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.year}-${now.millisecondsSinceEpoch % 10000}';
    final dueDate = DateTime(now.year, now.month + 1, 1);
    
    // Get client info
    final client = recurring['clients'];
    final clientName = client['name'] ?? 'Unknown';
    
    // Get user language
    final userId = supabase.auth.currentUser?.id;
    String userLang = 'en';
    if (userId != null) {
      try {
        final prefs = await supabase
            .from('user_preferences')
            .select('language')
            .eq('user_id', userId)
            .maybeSingle();
        userLang = prefs?['language'] ?? 'en';
      } catch (e) {
        // Use default
      }
    }
    
    // Create invoice in database
    final newInvoice = await supabase.from('invoices').insert({
      'client_id': recurring['client_id'],
      'invoice_number': invoiceNumber,
      'amount': recurring['amount'],
      'currency': recurring['currency'],
      'due_date': dueDate.toIso8601String(),
      'status': 'pending',
      'description': recurring['description'] ?? 'Recurring invoice',
      'recurring_invoice_id': recurring['id'],
    }).select().single();
    
    // Generate PDF
    final subtotal = (recurring['subtotal'] as num?)?.toDouble() ?? (recurring['amount'] as num?)?.toDouble() ?? 0.0;
    final taxAmount = (recurring['tax_amount'] as num?)?.toDouble() ?? 0.0;
    final total = (recurring['total'] as num?)?.toDouble() ?? subtotal + taxAmount;

    final pdfFile = await PdfService.generateInvoice(
      invoiceNumber: invoiceNumber,
      clientName: clientName,
      amount: total,
      currency: recurring['currency'],
      language: userLang,
      dueDate: dueDate,
    );
    
    // Upload PDF to Supabase Storage
    final pdfBytes = await pdfFile.readAsBytes();
    await supabase.storage
        .from('invoices')
        .uploadBinary('invoice_${newInvoice['id']}.pdf', pdfBytes);
    
    // Update invoice with PDF URL
    await supabase.from('invoices').update({
      'pdf_url': 'invoices/invoice_${newInvoice['id']}.pdf',
    }).eq('id', newInvoice['id']);
    
    _logger.i('Generated recurring invoice: $invoiceNumber');
  }
  
  /// Calculate next run date based on frequency
  static Future<void> _updateNextRunDate(Map<String, dynamic> recurring) async {
    final currentDate = DateTime.parse(recurring['next_run_date']);
    final frequency = recurring['frequency'] as String;
    
    DateTime nextDate;
    switch (frequency) {
      case 'daily':
        nextDate = currentDate.add(const Duration(days: 1));
        break;
      case 'weekly':
        nextDate = currentDate.add(const Duration(days: 7));
        break;
      case 'monthly':
        nextDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
        break;
      case 'yearly':
        nextDate = DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
        break;
      default:
        nextDate = currentDate.add(const Duration(days: 30));
    }
    
    // Check if end date is reached
    final endDate = recurring['end_date'] != null 
        ? DateTime.parse(recurring['end_date']) 
        : null;
    
    if (endDate != null && nextDate.isAfter(endDate)) {
      // Mark as completed
      await supabase.from('recurring_invoices')
          .update({'status': 'completed'})
          .eq('id', recurring['id']);
    } else {
      // Update next run date
      await supabase.from('recurring_invoices')
          .update({'next_run_date': nextDate.toIso8601String()})
          .eq('id', recurring['id']);
    }
  }
  
  /// Cancel recurring invoice schedule
  static Future<void> cancelSchedule(String scheduleId) async {
    await supabase.from('recurring_invoices')
        .update({'status': 'cancelled'})
        .eq('id', scheduleId);
  }
  
  /// Get all recurring invoice schedules
  static Future<List<Map<String, dynamic>>> getSchedules() async {
    final org = await supabase.from('organizations').select('id').single();
    
    return await supabase
        .from('recurring_invoices')
        .select('*, clients(name)')
        .eq('org_id', org['id'])
        .order('created_at', ascending: false);
  }
}
