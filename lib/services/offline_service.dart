import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

final _logger = Logger();

/// Offline Service
/// Manages local data syncing with Hive database, offline queue, and background sync
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();

  final supabase = Supabase.instance.client;
  late Box<Map<String, dynamic>> _jobsBox;
  late Box<Map<String, dynamic>> _invoicesBox;
  late Box<Map<String, dynamic>> _clientsBox;
  late Box<Map<String, dynamic>> _syncQueueBox;
  late Box<Map<String, dynamic>> _conflictsBox;

  bool _isOnline = true;
  Timer? _syncTimer;

  OfflineService._internal();

  factory OfflineService() {
    return _instance;
  }

  /// Initialize offline database
  Future<void> initialize() async {
    try {
      _logger.i('📦 Initializing offline database...');

      // Register Hive adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(_MapAdapter());
      }

      // Open boxes
      _jobsBox = await Hive.openBox('jobs');
      _invoicesBox = await Hive.openBox('invoices');
      _clientsBox = await Hive.openBox('clients');
      _syncQueueBox = await Hive.openBox('sync_queue');
      _conflictsBox = await Hive.openBox('conflicts');

      _logger.i('✅ Offline database initialized');

      // Start sync timer (every 5 seconds when online)
      _startSyncTimer();
    } catch (e) {
      _logger.e('❌ Error initializing offline database: $e');
      rethrow;
    }
  }

  /// Check if device is online
  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (online) {
      _logger.i('🟢 Device is online - syncing...');
      _syncAll();
    } else {
      _logger.i('🔴 Device is offline - using local cache');
    }
  }

  /// Save job to local database
  Future<void> saveJob(Map<String, dynamic> job) async {
    try {
      final jobId = job['id'] as String;
      await _jobsBox.put(jobId, job);
      _logger.i('💾 Job saved locally: $jobId');
    } catch (e) {
      _logger.e('❌ Error saving job locally: $e');
    }
  }

  /// Save invoice to local database
  Future<void> saveInvoice(Map<String, dynamic> invoice) async {
    try {
      final invoiceId = invoice['id'] as String;
      await _invoicesBox.put(invoiceId, invoice);
      _logger.i('💾 Invoice saved locally: $invoiceId');
    } catch (e) {
      _logger.e('❌ Error saving invoice locally: $e');
    }
  }

  /// Save client to local database
  Future<void> saveClient(Map<String, dynamic> client) async {
    try {
      final clientId = client['id'] as String;
      await _clientsBox.put(clientId, client);
      _logger.i('💾 Client saved locally: $clientId');
    } catch (e) {
      _logger.e('❌ Error saving client locally: $e');
    }
  }

  /// Queue an operation for sync
  Future<void> queueOperation({
    required String table,
    required String operation, // 'insert', 'update', 'delete'
    required Map<String, dynamic> data,
  }) async {
    try {
      final operationId = '${DateTime.now().millisecondsSinceEpoch}_${table}_${operation}';
      final queueItem = {
        'id': operationId,
        'table': table,
        'operation': operation,
        'data': data,
        'queued_at': DateTime.now().toIso8601String(),
        'synced': false,
      };

      await _syncQueueBox.put(operationId, queueItem);
      _logger.i('📋 Operation queued: $operation on $table');

      if (_isOnline) {
        await _syncQueue();
      }
    } catch (e) {
      _logger.e('❌ Error queuing operation: $e');
    }
  }

  /// Get all jobs from local cache
  Future<List<Map<String, dynamic>>> getOfflineJobs(String orgId) async {
    try {
      final jobs = _jobsBox.values
          .where((job) => job['org_id'] == orgId)
          .toList();
      return List<Map<String, dynamic>>.from(jobs);
    } catch (e) {
      _logger.e('❌ Error getting offline jobs: $e');
      return [];
    }
  }

  /// Get all invoices from local cache
  Future<List<Map<String, dynamic>>> getOfflineInvoices(String orgId) async {
    try {
      final invoices = _invoicesBox.values
          .where((invoice) => invoice['org_id'] == orgId)
          .toList();
      return List<Map<String, dynamic>>.from(invoices);
    } catch (e) {
      _logger.e('❌ Error getting offline invoices: $e');
      return [];
    }
  }

  /// Sync queued operations with Supabase
  Future<void> _syncQueue() async {
    if (!_isOnline) return;

    try {
      _logger.i('🔄 Syncing queued operations...');

      final queuedOps = _syncQueueBox.values
          .where((op) => op['synced'] == false)
          .toList();

      for (final op in queuedOps) {
        try {
          final table = op['table'] as String;
          final operation = op['operation'] as String;
          final data = op['data'] as Map<String, dynamic>;
          final opId = op['id'];

          switch (operation) {
            case 'insert':
              await supabase.from(table).insert(data);
              break;
            case 'update':
              await supabase
                  .from(table)
                  .update(data)
                  .eq('id', data['id']);
              break;
            case 'delete':
              await supabase
                  .from(table)
                  .delete()
                  .eq('id', data['id']);
              break;
          }

          // Mark as synced
          op['synced'] = true;
          await _syncQueueBox.put(opId, op);
          _logger.i('✅ Operation synced: $operation on $table');
        } catch (e) {
          _logger.w('⚠️ Failed to sync operation: $e');
          // Keep in queue for retry
        }
      }
    } catch (e) {
      _logger.e('❌ Error syncing queue: $e');
    }
  }

  /// Sync all local data with remote
  Future<void> _syncAll() async {
    if (!_isOnline) return;

    try {
      _logger.i('🔄 Full sync with remote database...');

      await _syncQueue();

      // Compare local and remote versions
      // Last-write-wins conflict resolution strategy
      _logger.i('✅ Full sync completed');
    } catch (e) {
      _logger.e('❌ Error during full sync: $e');
    }
  }

  /// Handle conflict between local and remote data
  Future<void> _resolveConflict({
    required String table,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) async {
    try {
      _logger.i('⚠️ Conflict detected: $table/$recordId');

      final localTimestamp = DateTime.parse(localData['updated_at'] ?? '1970-01-01');
      final remoteTimestamp = DateTime.parse(remoteData['updated_at'] ?? '1970-01-01');

      // Last-write-wins: keep the more recent version
      if (localTimestamp.isAfter(remoteTimestamp)) {
        _logger.i('📤 Local data is newer, pushing to remote...');
        await supabase
            .from(table)
            .update(localData)
            .eq('id', recordId);
      } else {
        _logger.i('📥 Remote data is newer, updating local...');
        if (table == 'jobs') {
          await saveJob(remoteData);
        } else if (table == 'invoices') {
          await saveInvoice(remoteData);
        } else if (table == 'clients') {
          await saveClient(remoteData);
        }
      }

      // Remove from conflicts
      await _conflictsBox.delete('$table/$recordId');
    } catch (e) {
      _logger.e('❌ Error resolving conflict: $e');
    }
  }

  /// Clear offline cache
  Future<void> clearCache() async {
    try {
      _logger.i('🗑️ Clearing offline cache...');
      await _jobsBox.clear();
      await _invoicesBox.clear();
      await _clientsBox.clear();
      await _syncQueueBox.clear();
      await _conflictsBox.clear();
      _logger.i('✅ Cache cleared');
    } catch (e) {
      _logger.e('❌ Error clearing cache: $e');
    }
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final pendingOps = _syncQueueBox.values
          .where((op) => op['synced'] == false)
          .length;

      final conflicts = _conflictsBox.length;

      return {
        'is_online': _isOnline,
        'pending_operations': pendingOps,
        'conflicted_records': conflicts,
        'cached_jobs': _jobsBox.length,
        'cached_invoices': _invoicesBox.length,
        'cached_clients': _clientsBox.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Start periodic sync timer
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isOnline) {
        _syncAll();
      }
    });
  }

  /// Stop sync timer and cleanup
  void dispose() {
    _syncTimer?.cancel();
    _logger.i('🛑 Offline service disposed');
  }
}

/// Custom Hive adapter for Map serialization
class _MapAdapter extends TypeAdapter<Map<String, dynamic>> {
  @override
  final typeId = 0;

  @override
  Map<String, dynamic> read(BinaryReader reader) {
    return Map<String, dynamic>.from(reader.readMap());
  }

  @override
  void write(BinaryWriter writer, Map<String, dynamic> obj) {
    writer.writeMap(obj);
  }
}
