import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Real-time Collaboration Service
/// Manages Supabase subscriptions for live job, invoice, and team updates
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  final supabase = Supabase.instance.client;

  RealtimeService._internal();

  factory RealtimeService() {
    return _instance;
  }

  // Subscription references
  RealtimeChannel? _jobsChannel;
  RealtimeChannel? _invoicesChannel;
  RealtimeChannel? _teamActivityChannel;

  /// Listen to real-time job updates for current organization
  /// Calls [onJobChange] whenever a job is created, updated, or deleted
  Stream<List<Map<String, dynamic>>> listenToJobs(
    String orgId,
    void Function(Map<String, dynamic> data, String action) onJobChange,
  ) {
    _jobsChannel = supabase
        .channel('public:jobs')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
        )
        .listen((payload) {
          _logger.i('📢 Job update: ${payload.eventType}');
          final data = payload.newRecord;
          onJobChange(data, payload.eventType.toString());
        });

    _logger.i('✅ Jobs real-time listener activated for org: $orgId');
    return const Stream.empty();
  }

  /// Listen to real-time invoice updates
  Stream<List<Map<String, dynamic>>> listenToInvoices(
    String orgId,
    void Function(Map<String, dynamic> data, String action) onInvoiceChange,
  ) {
    _invoicesChannel = supabase
        .channel('public:invoices')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'org_id',
            value: orgId,
          ),
        )
        .listen((payload) {
          _logger.i('📢 Invoice update: ${payload.eventType}');
          final data = payload.newRecord;
          onInvoiceChange(data, payload.eventType.toString());
        });

    _logger.i('✅ Invoices real-time listener activated for org: $orgId');
    return const Stream.empty();
  }

  /// Listen to team activity (users online, team member actions)
  Stream<List<Map<String, dynamic>>> listenToTeamActivity(
    String orgId,
    void Function(Map<String, dynamic> presence) onPresenceChange,
  ) {
    _teamActivityChannel = supabase.channel('team-presence-$orgId');

    _teamActivityChannel!
        .onPresenceSync((_) {
          _logger.i('🔄 Team presence synced');
          final presenceState = _teamActivityChannel!.presenceState();
          for (var item in presenceState) {
            onPresenceChange(item.presence.first as Map<String, dynamic>);
          }
        })
        .onPresenceJoin((payload) {
          _logger.i('👤 User joined: ${payload.key}');
          onPresenceChange(payload.presence as Map<String, dynamic>);
        })
        .onPresenceLeave((payload) {
          _logger.i('👤 User left: ${payload.key}');
        })
        .subscribe(((status, err) {
          if (status == RealtimeSubscriptionStatus.subscribed) {
            _logger.i('✅ Team activity subscribed');
            // Broadcast current user presence
            final userId = supabase.auth.currentUser?.id;
            if (userId != null) {
              _teamActivityChannel!.track({
                'user_id': userId,
                'online_at': DateTime.now().toIso8601String(),
                'status': 'online',
              });
            }
          }
        }));

    return const Stream.empty();
  }

  /// Broadcast user presence (online status, current page)
  Future<void> broadcastPresence(String orgId, {
    required String page,
    required String status,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (_teamActivityChannel == null) {
        _teamActivityChannel = supabase.channel('team-presence-$orgId');
        await _teamActivityChannel!.subscribe();
      }

      await _teamActivityChannel!.track({
        'user_id': userId,
        'current_page': page,
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });

      _logger.i('📡 Presence broadcasted: $page ($status)');
    } catch (e) {
      _logger.e('❌ Error broadcasting presence: $e');
    }
  }

  /// Unsubscribe from all real-time channels
  Future<void> unsubscribeAll() async {
    try {
      if (_jobsChannel != null) {
        await _jobsChannel!.unsubscribe();
      }
      if (_invoicesChannel != null) {
        await _invoicesChannel!.unsubscribe();
      }
      if (_teamActivityChannel != null) {
        await _teamActivityChannel!.unsubscribe();
      }
      _logger.i('✅ All real-time subscriptions closed');
    } catch (e) {
      _logger.e('❌ Error unsubscribing: $e');
    }
  }
}
