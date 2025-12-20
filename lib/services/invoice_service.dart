// lib/services/invoice_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'email_service.dart';

class InvoiceService {
  final supabase = Supabase.instance.client;

  /// Send reminders for overdue invoices (3+ days past due)
  Future<void> sendOverdueReminders() async {
    final today = DateTime.now();
    
    // Find unpaid invoices 3+ days overdue
    final overdueInvoices = await supabase
        .from('invoices')
        .select('id, number, amount, currency, due_date, payment_link, clients(email)')
        .eq('status', 'sent')
        .lt('due_date', today.subtract(const Duration(days: 3)).toIso8601String())
        .isFilter('reminder_sent_at', null);
    
    int remindersSent = 0;
    for (final invoice in overdueInvoices) {
      final client = invoice['clients'] as Map<String, dynamic>?;
      final email = client?['email'];
      
      if (email != null) {
        // Send email
        final success = await EmailService.sendPaymentReminder(
          toEmail: email,
          invoiceNumber: invoice['number'],
          amount: (invoice['amount'] as num).toDouble(),
          currency: invoice['currency'] ?? 'EUR',
          dueDate: (invoice['due_date'] as String).split('T')[0],
        );
        
        if (success) {
          // Mark as reminded
          await supabase
              .from('invoices')
              .update({'reminder_sent_at': DateTime.now().toIso8601String()})
              .eq('id', invoice['id']);
          
          remindersSent++;
        }
      }
    }
    
    print('✅ Sent $remindersSent overdue invoice reminders');
  }

  /// Send welcome email with payment link after invoice creation
  Future<bool> sendInvoiceEmail({
    required String toEmail,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required String paymentLink,
  }) async {
    // TODO: Create sendInvoiceEmail method in EmailService
    print('📧 Sending invoice $invoiceNumber to $toEmail');
    return true;
  }

  /// Mark invoice as paid
  Future<void> markAsPaid(String invoiceId) async {
    await supabase
        .from('invoices')
        .update({
          'status': 'paid',
          'paid_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invoiceId);
  }

  /// Get overdue invoice count for a specific organization
  Future<int> getOverdueCount(String orgId) async {
    final response = await supabase
        .from('invoices')
        .select('id')
        .eq('org_id', orgId)
        .eq('status', 'sent')
        .lt('due_date', DateTime.now().toIso8601String())
        .count(CountOption.exact);
    
    return response.count;
  }
}
