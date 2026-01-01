import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final _logger = Logger();

/// SMS Notifications Service
/// Integrates with Twilio for SMS job updates, invoice reminders, and team alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  // Replace with your actual Twilio credentials
  static const String TWILIO_ACCOUNT_SID = 'YOUR_TWILIO_ACCOUNT_SID';
  static const String TWILIO_AUTH_TOKEN = 'YOUR_TWILIO_AUTH_TOKEN';
  static const String TWILIO_PHONE_NUMBER = '+1234567890'; // Your Twilio phone
  static const String TWILIO_API_URL = 'https://api.twilio.com/2010-04-01';

  final supabase = Supabase.instance.client;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  /// Send SMS notification
  Future<bool> sendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      _logger.i('📱 Sending SMS to $phoneNumber: $message');

      final auth = base64Encode(
        utf8.encode('$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN'),
      );

      final response = await http.post(
        Uri.parse('$TWILIO_API_URL/Accounts/$TWILIO_ACCOUNT_SID/Messages.json'),
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': TWILIO_PHONE_NUMBER,
          'To': phoneNumber,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        _logger.i('✅ SMS sent successfully');
        return true;
      } else {
        _logger.e('❌ Failed to send SMS: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Notify job update to technician
  Future<void> notifyJobUpdate({
    required String jobId,
    required String jobTitle,
    required String technicianPhone,
    required String updateType, // 'assigned', 'started', 'completed', 'rescheduled'
  }) async {
    try {
      String message = '';
      switch (updateType) {
        case 'assigned':
          message = 'AuraCRM: New job assigned - $jobTitle. Check the app for details.';
          break;
        case 'started':
          message = 'AuraCRM: Job $jobTitle has been started. Log your time in the app.';
          break;
        case 'completed':
          message = 'AuraCRM: Job $jobTitle marked as complete. Great work!';
          break;
        case 'rescheduled':
          message = 'AuraCRM: Job $jobTitle has been rescheduled. Check your calendar.';
          break;
        default:
          message = 'AuraCRM: Update on job $jobTitle.';
      }

      await sendSMS(phoneNumber: technicianPhone, message: message);

      // Log notification
      await supabase.from('notification_logs').insert({
        'job_id': jobId,
        'type': 'sms',
        'recipient': technicianPhone,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('❌ Error notifying job update: $e');
    }
  }

  /// Notify invoice payment reminder
  Future<void> notifyInvoiceReminder({
    required String invoiceId,
    required String clientPhone,
    required double amount,
    required DateTime dueDate,
    required String businessName,
  }) async {
    try {
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      final message = businessName.isNotEmpty
          ? '$businessName: Invoice reminder - \$$amount due in $daysUntilDue days.'
          : 'Invoice reminder - \$$amount due in $daysUntilDue days.';

      await sendSMS(phoneNumber: clientPhone, message: message);

      await supabase.from('notification_logs').insert({
        'invoice_id': invoiceId,
        'type': 'sms_reminder',
        'recipient': clientPhone,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('❌ Error sending invoice reminder: $e');
    }
  }

  /// Notify payment received
  Future<void> notifyPaymentReceived({
    required String invoiceId,
    required String clientPhone,
    required double amount,
    required String businessName,
  }) async {
    try {
      final message = businessName.isNotEmpty
          ? '$businessName: Thank you! Payment of \$$amount received. Receipt sent to email.'
          : 'Thank you! Payment of \$$amount received. Receipt sent to email.';

      await sendSMS(phoneNumber: clientPhone, message: message);

      await supabase.from('notification_logs').insert({
        'invoice_id': invoiceId,
        'type': 'sms_payment',
        'recipient': clientPhone,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('❌ Error sending payment confirmation: $e');
    }
  }

  /// Notify team members of job assignment
  Future<void> notifyTeamAssignment({
    required String jobId,
    required String jobTitle,
    required List<String> teamMemberPhones,
    required String assignedTo,
  }) async {
    try {
      final message = 'AuraCRM: $assignedTo has been assigned to $jobTitle.';

      for (final phone in teamMemberPhones) {
        await sendSMS(phoneNumber: phone, message: message);
      }

      await supabase.from('notification_logs').insert({
        'job_id': jobId,
        'type': 'sms_team',
        'recipients': teamMemberPhones.length,
        'message': message,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('❌ Error notifying team: $e');
    }
  }

  /// Get user notification preferences
  Future<Map<String, dynamic>> getUserPreferences(String userId) async {
    try {
      final prefs = await supabase
          .from('user_preferences')
          .select('notification_settings')
          .eq('user_id', userId)
          .maybeSingle();

      return prefs?['notification_settings'] ?? {
        'job_updates': true,
        'invoice_reminders': true,
        'payment_notifications': true,
        'team_alerts': true,
      };
    } catch (e) {
      _logger.e('❌ Error getting notification preferences: $e');
      return {};
    }
  }

  /// Update user notification preferences
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final currentPrefs = await supabase
          .from('user_preferences')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (currentPrefs == null) {
        // Create new preferences
        await supabase.from('user_preferences').insert({
          'user_id': userId,
          'notification_settings': preferences,
        });
      } else {
        // Update existing preferences
        await supabase
            .from('user_preferences')
            .update({'notification_settings': preferences})
            .eq('user_id', userId);
      }

      _logger.i('✅ Notification preferences updated');
    } catch (e) {
      _logger.e('❌ Error updating notification preferences: $e');
      rethrow;
    }
  }

  /// Schedule recurring reminder for unpaid invoices
  Future<void> scheduleUnpaidInvoiceReminders({
    required String orgId,
    required int daysBeforeDue,
  }) async {
    try {
      _logger.i('📅 Scheduling invoice reminders for org: $orgId');

      // Get all unpaid invoices due soon
      final invoices = await supabase
          .from('invoices')
          .select('id, client_id, amount, due_date, clients(phone)')
          .eq('org_id', orgId)
          .eq('status', 'pending')
          .filter('due_date', 'lte',
              DateTime.now().add(Duration(days: daysBeforeDue)).toIso8601String());

      for (final invoice in invoices) {
        final clientPhone = invoice['clients']['phone'];
        if (clientPhone != null) {
          await notifyInvoiceReminder(
            invoiceId: invoice['id'],
            clientPhone: clientPhone,
            amount: (invoice['amount'] as num).toDouble(),
            dueDate: DateTime.parse(invoice['due_date']),
            businessName: '', // Get from org if needed
          );
        }
      }

      _logger.i('✅ Invoice reminders scheduled');
    } catch (e) {
      _logger.e('❌ Error scheduling reminders: $e');
    }
  }

  /// Get notification history
  Future<List<Map<String, dynamic>>> getNotificationHistory({
    required String orgId,
    int limit = 50,
  }) async {
    try {
      final logs = await supabase
          .from('notification_logs')
          .select('*')
          .eq('org_id', orgId)
          .order('sent_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      _logger.e('❌ Error getting notification history: $e');
      return [];
    }
  }
}
