// lib/services/lead_agent_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'invoice_service.dart';

final _logger = Logger();

class LeadAgentService {
  final supabase = Supabase.instance.client;

  /// Creates follow-up reminders for leads not contacted in 3 days
  Future<void> createFollowUpReminders() async {
    try {
      // Find leads not contacted in 3 days
      final leads = await supabase
          .from('leads')
          .select()
          .eq('status', 'new')
          .lt('created_at', DateTime.now().subtract(const Duration(days: 3)).toIso8601String());
      
      for (final lead in leads) {
        // Create reminder activity
        await supabase.from('lead_activities').insert({
          'lead_id': lead['id'],
          'activity_type': 'whatsapp',
          'notes': 'Follow up: ${lead['name']} (lead from ${lead['source']})',
          'scheduled_at': DateTime.now().add(const Duration(hours: 9)), // Tomorrow 9 AM
        });
      }

      _logger.i('✅ Created ${leads.length} follow-up reminders');
    } catch (e) {
      _logger.e('❌ Error creating follow-up reminders: $e');
    }
  }

  /// Auto-qualify leads based on engagement
  Future<void> autoQualifyLeads() async {
    try {
      // Find leads with multiple interactions
      final activeLeads = await supabase
          .from('leads')
          .select('id, (lead_activities!inner(count))')
          .eq('status', 'new');
      
      for (final lead in activeLeads) {
        final activityCount = lead['lead_activities']?['count'] ?? 0;
        
        // If lead has 3+ interactions, mark as qualified
        if (activityCount >= 3) {
          await supabase
              .from('leads')
              .update({'status': 'qualified'})
              .eq('id', lead['id']);
        }
      }
    } catch (e) {
      print('❌ Error auto-qualifying leads: $e');
    }
  }

  /// Detect and flag cold leads (no activity in 7 days)
  Future<void> flagColdLeads() async {
    try {
      final oldDate = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      await supabase
          .from('leads')
          .update({'status': 'cold'})
          .eq('status', 'new')
          .lt('updated_at', oldDate);
      
      print('✅ Flagged cold leads');
    } catch (e) {
      print('❌ Error flagging cold leads: $e');
    }
  }

  /// Run all automation tasks (leads + invoices)
  Future<void> runDailyTasks() async {
    print('🤖 Running daily automation tasks...');
    await createFollowUpReminders();
    await autoQualifyLeads();
    await flagColdLeads();
    
    // Get current org for invoice reminders
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      final org = await supabase
          .from('organizations')
          .select('id')
          .eq('owner_id', currentUser.id)
          .maybeSingle();
      if (org != null) {
        await InvoiceService().sendOverdueReminders(org['id'] as String);
      }
    }
    
    print('✅ Daily automation complete');
  }
}
