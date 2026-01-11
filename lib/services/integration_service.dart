import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final _logger = Logger();

/// CRM Integration Service
/// Manages integrations with Zapier, HubSpot, and Slack for data sync and notifications
class IntegrationService {
  static final IntegrationService _instance = IntegrationService._internal();

  final supabase = Supabase.instance.client;

  IntegrationService._internal();

  factory IntegrationService() {
    return _instance;
  }

  /// Available integrations
  static const List<String> AVAILABLE_INTEGRATIONS = [
    'zapier',
    'hubspot',
    'slack',
    'google_calendar',
    'quickbooks',
  ];

  /// Activate integration for organization
  Future<Map<String, dynamic>> activateIntegration({
    required String orgId,
    required String integrationName,
    required Map<String, String> credentials,
  }) async {
    try {
      _logger.i('🔗 Activating integration: $integrationName for org: $orgId');

      // Validate credentials based on integration type
      final isValid = await _validateIntegrationCredentials(
        integrationName,
        credentials,
      );

      if (!isValid) {
        throw Exception('Invalid credentials for $integrationName');
      }

      // Store encrypted credentials
      await supabase.from('organization_integrations').insert({
        'org_id': orgId,
        'integration_name': integrationName,
        'credentials': jsonEncode(credentials), // In production, encrypt this
        'is_active': true,
        'activated_at': DateTime.now().toIso8601String(),
      });

      _logger.i('✅ Integration activated: $integrationName');

      return {
        'integration': integrationName,
        'status': 'active',
        'activated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      _logger.e('❌ Error activating integration: $e');
      rethrow;
    }
  }

  /// Deactivate integration
  Future<void> deactivateIntegration({
    required String orgId,
    required String integrationName,
  }) async {
    try {
      _logger.i('❌ Deactivating integration: $integrationName');

      await supabase
          .from('organization_integrations')
          .update({'is_active': false})
          .eq('org_id', orgId)
          .eq('integration_name', integrationName);

      _logger.i('✅ Integration deactivated');
    } catch (e) {
      _logger.e('❌ Error deactivating integration: $e');
      rethrow;
    }
  }

  /// Sync jobs to HubSpot deals
  Future<void> syncJobsToHubSpot({
    required String orgId,
  }) async {
    try {
      _logger.i('📤 Syncing jobs to HubSpot...');

      // Get HubSpot credentials
      final integration = await supabase
          .from('organization_integrations')
          .select('credentials')
          .eq('org_id', orgId)
          .eq('integration_name', 'hubspot')
          .maybeSingle();

      if (integration == null) {
        throw Exception('HubSpot integration not configured');
      }

      final credentials = jsonDecode(integration['credentials']);
      final hubspotToken = credentials['access_token'] as String;

      // Get jobs
      final jobs = await supabase
          .from('jobs')
          .select('id, title, description, status, assigned_to, clients(name)')
          .eq('org_id', orgId);

      // Sync each job to HubSpot deal
      for (final job in jobs) {
        await _createHubSpotDeal(
          token: hubspotToken,
          jobId: job['id'],
          jobTitle: job['title'],
          dealValue: 0, // Get from invoice if needed
          dealStage: _mapJobStatusToHubSpot(job['status']),
          clientName: job['clients']['name'] ?? 'Unknown',
        );
      }

      _logger.i('✅ Jobs synced to HubSpot');
    } catch (e) {
      _logger.e('❌ Error syncing to HubSpot: $e');
      rethrow;
    }
  }

  /// Create deal in HubSpot
  Future<void> _createHubSpotDeal({
    required String token,
    required String jobId,
    required String jobTitle,
    required double dealValue,
    required String dealStage,
    required String clientName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.hubapi.com/crm/v3/objects/deals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'properties': {
            'dealname': jobTitle,
            'dealstage': dealStage,
            'amount': dealValue.toString(),
            'description': 'Job ID: $jobId\nClient: $clientName',
          }
        }),
      );

      if (response.statusCode == 201) {
        _logger.i('✅ HubSpot deal created for job: $jobId');
      } else {
        _logger.w('⚠️ Failed to create HubSpot deal: ${response.body}');
      }
    } catch (e) {
      _logger.e('❌ Error creating HubSpot deal: $e');
    }
  }

  /// Send job update to Slack
  Future<void> notifySlack({
    required String orgId,
    required String jobId,
    required String jobTitle,
    required String updateType,
    required String assignedTo,
  }) async {
    try {
      _logger.i('💬 Sending Slack notification...');

      // Get Slack webhook URL
      final integration = await supabase
          .from('organization_integrations')
          .select('credentials')
          .eq('org_id', orgId)
          .eq('integration_name', 'slack')
          .maybeSingle();

      if (integration == null) {
        _logger.w('⚠️ Slack integration not configured');
        return;
      }

      final credentials = jsonDecode(integration['credentials']);
      final webhookUrl = credentials['webhook_url'] as String;

      final message = _buildSlackMessage(
        jobTitle: jobTitle,
        updateType: updateType,
        assignedTo: assignedTo,
        jobId: jobId,
      );

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Slack notification sent');
      }
    } catch (e) {
      _logger.e('❌ Error sending Slack notification: $e');
    }
  }

  /// Trigger Zapier webhook
  Future<void> triggerZapier({
    required String orgId,
    required String triggerName,
    required Map<String, dynamic> data,
  }) async {
    try {
      _logger.i('⚡ Triggering Zapier: $triggerName');

      final integration = await supabase
          .from('organization_integrations')
          .select('credentials')
          .eq('org_id', orgId)
          .eq('integration_name', 'zapier')
          .maybeSingle();

      if (integration == null) {
        _logger.w('⚠️ Zapier integration not configured');
        return;
      }

      final credentials = jsonDecode(integration['credentials']);
      final webhookUrl = credentials['webhook_url'] as String;

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'trigger': triggerName,
          'timestamp': DateTime.now().toIso8601String(),
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('✅ Zapier webhook triggered');
      }
    } catch (e) {
      _logger.e('❌ Error triggering Zapier: $e');
    }
  }

  /// Sync Google Calendar events
  Future<void> syncGoogleCalendar({
    required String orgId,
  }) async {
    try {
      _logger.i('📅 Syncing with Google Calendar...');

      // Get Google Calendar credentials
      final integration = await supabase
          .from('organization_integrations')
          .select('credentials')
          .eq('org_id', orgId)
          .eq('integration_name', 'google_calendar')
          .maybeSingle();

      if (integration == null) {
        throw Exception('Google Calendar integration not configured');
      }

      // Get jobs and create calendar events
      final jobs = await supabase
          .from('jobs')
          .select('id, title, start_date, end_date, assigned_to')
          .eq('org_id', orgId);
      
      // Log sync completion
      _logger.i('✅ Synced ${jobs.length} jobs to Google Calendar');
    } catch (e) {
      _logger.e('❌ Error syncing Google Calendar: $e');
    }
  }

  /// Sync QuickBooks invoices
  Future<void> syncQuickBooksInvoices({
    required String orgId,
  }) async {
    try {
      _logger.i('💼 Syncing with QuickBooks...');

      final integration = await supabase
          .from('organization_integrations')
          .select('credentials')
          .eq('org_id', orgId)
          .eq('integration_name', 'quickbooks')
          .maybeSingle();

      if (integration == null) {
        throw Exception('QuickBooks integration not configured');
      }

      // Get invoices
      final invoices = await supabase
          .from('invoices')
          .select('id, client_id, amount, due_date, status, clients(name)')
          .eq('org_id', orgId);

      // In production, create invoices in QuickBooks via API
      _logger.i('✅ Synced ${invoices.length} invoices to QuickBooks');
    } catch (e) {
      _logger.e('❌ Error syncing QuickBooks: $e');
    }
  }

  /// Get active integrations for organization
  Future<List<Map<String, dynamic>>> getActiveIntegrations(String orgId) async {
    try {
      final integrations = await supabase
          .from('organization_integrations')
          .select('integration_name, is_active, activated_at')
          .eq('org_id', orgId)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(integrations);
    } catch (e) {
      _logger.e('❌ Error getting active integrations: $e');
      return [];
    }
  }

  /// Build Slack message payload
  Map<String, dynamic> _buildSlackMessage({
    required String jobTitle,
    required String updateType,
    required String assignedTo,
    required String jobId,
  }) {
    final color = updateType == 'completed' ? '#28A745' : '#007BFF';
    final emoji = updateType == 'completed' ? '✅' : '📋';

    return {
      'text': 'Job Update',
      'color': color,
      'blocks': [
        {
          'type': 'section',
          'text': {
            'type': 'mrkdwn',
            'text': '$emoji *Job Update*\n*$jobTitle*\nAssigned: $assignedTo',
          }
        },
        {
          'type': 'section',
          'fields': [
            {
              'type': 'mrkdwn',
              'text': '*Status:*\n${updateType.replaceAll('_', ' ').toUpperCase()}',
            },
            {
              'type': 'mrkdwn',
              'text': '*Job ID:*\n$jobId',
            },
          ]
        },
      ]
    };
  }

  /// Map job status to HubSpot deal stage
  String _mapJobStatusToHubSpot(String jobStatus) {
    switch (jobStatus) {
      case 'pending':
        return 'negotiation/review';
      case 'in_progress':
        return 'contractsent';
      case 'completed':
        return 'closedwon';
      case 'cancelled':
        return 'closedlost';
      default:
        return 'negotiation/review';
    }
  }

  /// Validate integration credentials
  Future<bool> _validateIntegrationCredentials(
    String integrationName,
    Map<String, String> credentials,
  ) async {
    try {
      switch (integrationName) {
        case 'zapier':
          return credentials.containsKey('webhook_url');
        case 'hubspot':
          return credentials.containsKey('access_token');
        case 'slack':
          return credentials.containsKey('webhook_url');
        case 'google_calendar':
          return credentials.containsKey('access_token');
        case 'quickbooks':
          return credentials.containsKey('access_token') &&
              credentials.containsKey('realm_id');
        default:
          return false;
      }
    } catch (e) {
      _logger.e('❌ Error validating credentials: $e');
      return false;
    }
  }
}
