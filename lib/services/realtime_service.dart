// lib/services/realtime_service.dart
// Stub - disabled in current version
// Real-time updates will be added in future releases
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

/// Real-time Collaboration Service (STUB - DISABLED)
/// Manages Supabase subscriptions for live job, invoice, and team updates
/// This is a placeholder for future real-time features
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  final supabase = Supabase.instance.client;

  RealtimeService._internal();

  factory RealtimeService() {
    return _instance;
  }

  /// Listen to real-time job updates for current organization
  /// Currently returns empty stream - will be implemented in future
  Stream<List<Map<String, dynamic>>> listenToJobs(
    String orgId,
    void Function(Map<String, dynamic> data, String action) onJobChange,
  ) {
    _logger.i('ℹ️ Jobs real-time listener is disabled');
    return const Stream.empty();
  }

  /// Listen to real-time invoice updates
  /// Currently returns empty stream - will be implemented in future
  Stream<List<Map<String, dynamic>>> listenToInvoices(
    String orgId,
    void Function(Map<String, dynamic> data, String action) onInvoiceChange,
  ) {
    _logger.i('ℹ️ Invoices real-time listener is disabled');
    return const Stream.empty();
  }

  /// Listen to team activity (users online, team member actions)
  /// Currently returns empty stream - will be implemented in future
  Stream<List<Map<String, dynamic>>> listenToTeamActivity(
    String orgId,
    void Function(Map<String, dynamic> presence) onPresenceChange,
  ) {
    _logger.i('ℹ️ Team activity listener is disabled');
    return const Stream.empty();
  }

  /// Broadcast user presence (online status, current page)
  /// Currently does nothing - will be implemented in future
  Future<void> broadcastPresence(String orgId, {
    required String page,
    required String status,
  }) async {
    _logger.i('ℹ️ Presence broadcast is disabled');
    return;
  }

  /// Unsubscribe from all real-time channels
  /// Currently does nothing - will be implemented in future
  Future<void> unsubscribeAll() async {
    _logger.i('ℹ️ Unsubscribe all is disabled');
    return;
  }
}
