// lib/services/realtime_service.dart
/// Real-time Collaboration Service
/// Manages Supabase subscriptions for live job, invoice, and team updates
library;

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  final supabase = Supabase.instance.client;
  
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeService._internal();

  factory RealtimeService() {
    return _instance;
  }

  /// Listen to real-time job updates for current organization
  Stream<List<Map<String, dynamic>>> listenToJobs(
    String orgId,
    void Function(Map<String, dynamic> data, String action) onJobChange,
  ) {
    try {
      _logger.i('🔄 Subscribing to real-time job updates for org: $orgId');
      
      final channel = supabase.channel('jobs:$orgId');
      _channels['jobs:$orgId'] = channel;
      
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'jobs',
            callback: (payload) {
              _logger.i('✅ Job update received: ${payload.eventType}');
              final data = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
              onJobChange(data, payload.eventType.toString());
            },
          )
          .subscribe();
      
      _logger.i('✅ Job real-time subscription active');
      
      return Stream.empty();
    } catch (e) {
      _logger.e('❌ Error subscribing to jobs: $e');
      return Stream.empty();
    }
  }

  /// Listen to real-time invoice updates
  Stream<List<Map<String, dynamic>>> listenToInvoices(
    String orgId,
    void Function(Map<String, dynamic> data, String action) onInvoiceChange,
  ) {
    try {
      _logger.i('🔄 Subscribing to real-time invoice updates for org: $orgId');
      
      final channel = supabase.channel('invoices:$orgId');
      _channels['invoices:$orgId'] = channel;
      
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'invoices',
            callback: (payload) {
              _logger.i('✅ Invoice update received: ${payload.eventType}');
              final data = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
              onInvoiceChange(data, payload.eventType.toString());
            },
          )
          .subscribe();
      
      _logger.i('✅ Invoice real-time subscription active');
      
      return Stream.empty();
    } catch (e) {
      _logger.e('❌ Error subscribing to invoices: $e');
      return Stream.empty();
    }
  }

  /// Listen to team activity (users online, team member actions)
  Stream<List<Map<String, dynamic>>> listenToTeamActivity(
    String orgId,
    void Function(Map<String, dynamic> presence) onPresenceChange,
  ) {
    try {
      _logger.i('🔄 Subscribing to team activity for org: $orgId');
      
      final channel = supabase.channel('team:$orgId');
      _channels['team:$orgId'] = channel;
      
      channel
          .onPresenceSync((payload) {
            _logger.i('✅ Team presence synced');
            try {
              final state = channel.presenceState();
              for (var _ in state) {
                // Convert presence to a simple presence data map
                final presenceData = <String, dynamic>{
                  'status': 'online',
                  'timestamp': DateTime.now().toIso8601String(),
                };
                onPresenceChange(presenceData);
              }
            } catch (e) {
              _logger.w('⚠️ Error processing presence state: $e');
            }
          })
          .subscribe();
      
      _logger.i('✅ Team activity subscription active');
      
      return Stream.empty();
    } catch (e) {
      _logger.e('❌ Error subscribing to team activity: $e');
      return Stream.empty();
    }
  }

  /// Broadcast user presence (online status, current page)
  Future<void> broadcastPresence(String orgId, {
    required String page,
    required String status,
  }) async {
    try {
      final channel = _channels['team:$orgId'] ?? supabase.channel('team:$orgId');
      
      await channel.track({
        'user_id': supabase.auth.currentUser?.id,
        'email': supabase.auth.currentUser?.email,
        'page': page,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logger.i('✅ Presence broadcasted: $page - $status');
    } catch (e) {
      _logger.e('❌ Error broadcasting presence: $e');
    }
  }

  /// Unsubscribe from all real-time channels
  Future<void> unsubscribeAll() async {
    try {
      _logger.i('🔄 Unsubscribing from all real-time channels');
      
      for (var channel in _channels.values) {
        await supabase.removeChannel(channel);
      }
      
      _channels.clear();
      _logger.i('✅ All real-time subscriptions closed');
    } catch (e) {
      _logger.e('❌ Error unsubscribing: $e');
    }
  }
}
