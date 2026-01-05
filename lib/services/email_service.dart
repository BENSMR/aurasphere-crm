// lib/services/email_service.dart
/// 🔐 SECURE: All email sending goes through Supabase Edge Function
/// This service never exposes API keys - they're stored securely in Supabase Secrets
/// See: supabase/functions/send-email/index.ts
library;


import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

class EmailService {
  static final supabase = Supabase.instance.client;

  /// Send payment reminder email via secure Edge Function
  /// 🔒 API key stored in Supabase Secrets (RESEND_API_KEY), never exposed on frontend
  static Future<bool> sendPaymentReminder({
    required String toEmail,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required String dueDate,
    String language = 'en',
  }) async {
    try {
      _logger.i('📧 Sending payment reminder via Edge Function...');
      
      // Call Supabase Edge Function instead of direct Resend API
      final response = await supabase.functions.invoke(
        'send-email',
        body: {
          'to': toEmail,
          'subject': _getSubject(language, invoiceNumber),
          'html': _getHtmlBody(language, invoiceNumber, amount, currency, dueDate),
          'replyTo': 'support@aura-sphere.app',
        },
      );

      // Response from Supabase Edge Functions is returned as dynamic
      final success = response != null;
      
      if (success) {
        _logger.i('✅ Email sent successfully');
      } else {
        _logger.w('⚠️ Email send failed');
      }
      
      return success;
    } catch (e) {
      _logger.e('❌ Email service error: $e');
      return false;
    }
  }

  static String _getSubject(String language, String invoiceNumber) {
    switch (language) {
      case 'fr':
        return 'Rappel : La facture $invoiceNumber est en retard';
      case 'ar':
        return 'تذكير: الفاتورة $invoiceNumber متأخرة';
      default:
        return 'Reminder: Invoice $invoiceNumber is overdue';
    }
  }

  static String _getHtmlBody(String language, String invoiceNumber, double amount, String currency, String dueDate) {
    switch (language) {
      case 'fr':
        return '''
          <h2>Rappel de paiement</h2>
          <p>Bonjour,</p>
          <p>Votre facture <strong>$invoiceNumber</strong> d'un montant de 
          <strong>$currency$amount</strong> était due le <strong>$dueDate</strong>.</p>
          <p>Veuillez effectuer le paiement dès que possible :</p>
          <a href="https://crm.aura-sphere.app/pay/$invoiceNumber" 
             style="background: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 6px; display: inline-block;">
            Payer maintenant
          </a>
          <p>Merci pour votre confiance !</p>
          <hr>
          <p><small>Envoyé par Aurasphere CRM — votre partenaire commercial souverain</small></p>
        ''';
      case 'ar':
        return '''
          <h2 dir="rtl">تذكير بالدفع</h2>
          <p dir="rtl">مرحبا،</p>
          <p dir="rtl">فاتورتك <strong>$invoiceNumber</strong> بمبلغ 
          <strong>$currency$amount</strong> كان موعد استحقاقها في <strong>$dueDate</strong>.</p>
          <p dir="rtl">يرجى إتمام الدفع في أقرب وقت ممكن:</p>
          <a href="https://crm.aura-sphere.app/pay/$invoiceNumber" 
             style="background: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 6px; display: inline-block;">
            ادفع الآن
          </a>
          <p dir="rtl">شكراً لك على تعاملك معنا!</p>
          <hr>
          <p dir="rtl"><small>أرسلت من Aurasphere CRM — شريكك التجاري المستقل</small></p>
        ''';
      default:
        return '''
          <h2>Payment Reminder</h2>
          <p>Hi there,</p>
          <p>Your invoice <strong>$invoiceNumber</strong> for 
          <strong>$currency$amount</strong> was due on <strong>$dueDate</strong>.</p>
          <p>Please complete payment at your earliest convenience:</p>
          <a href="https://crm.aura-sphere.app/pay/$invoiceNumber" 
             style="background: #4F46E5; color: white; padding: 10px 20px; text-decoration: none; border-radius: 6px; display: inline-block;">
            Pay Now
          </a>
          <p>Thank you for your business!</p>
          <hr>
          <p><small>Sent by Aurasphere CRM — your sovereign business partner</small></p>
        ''';
    }
  }
}
