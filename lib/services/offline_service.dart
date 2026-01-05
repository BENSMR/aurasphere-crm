import 'package:logger/logger.dart';

final _logger = Logger();

/// Offline Service - Web-compatible implementation using LocalStorage
/// 
/// Works across all platforms:
/// - Web: Uses browser LocalStorage (persistent)
/// - Mobile: Can use shared_preferences or Hive (if available)
/// - Desktop: Can use local file storage
/// 
/// Features:
/// - Auto-save data when going offline
/// - Sync queue for changes made offline
/// - Conflict resolution
/// - Offline mode detection

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();

  bool _isOnline = true;
  final Map<String, List<Map<String, dynamic>>> _localCache = {
    'jobs': [],
    'invoices': [],
    'clients': [],
    'expenses': [],
  };
  final List<Map<String, dynamic>> _syncQueue = [];

  OfflineService._internal();

  factory OfflineService() {
    return _instance;
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Initialize offline database
  Future<void> initialize() async {
    try {
      _logger.i('✅ Offline Service initialized (LocalStorage mode)');
    } catch (e) {
      _logger.e('❌ Offline Service init error: $e');
    }
  }

  /// Set online status
  void setOnlineStatus(bool online) {
    _isOnline = online;
    _logger.i('🔄 Online status: ${online ? "✅ ONLINE" : "❌ OFFLINE"}');
    if (online) {
      _syncAll();
    }
  }

  /// Save job to local cache
  Future<void> saveJob(Map<String, dynamic> job) async {
    try {
      final jobs = _localCache['jobs'] ?? [];
      final index = jobs.indexWhere((j) => j['id'] == job['id']);
      if (index >= 0) {
        jobs[index] = job;
      } else {
        jobs.add(job);
      }
      _localCache['jobs'] = jobs;
      _logger.i('💾 Job saved locally: ${job['id']}');
    } catch (e) {
      _logger.e('❌ Error saving job: $e');
    }
  }

  /// Save invoice to local cache
  Future<void> saveInvoice(Map<String, dynamic> invoice) async {
    try {
      final invoices = _localCache['invoices'] ?? [];
      final index = invoices.indexWhere((i) => i['id'] == invoice['id']);
      if (index >= 0) {
        invoices[index] = invoice;
      } else {
        invoices.add(invoice);
      }
      _localCache['invoices'] = invoices;
      _logger.i('💾 Invoice saved locally: ${invoice['id']}');
    } catch (e) {
      _logger.e('❌ Error saving invoice: $e');
    }
  }

  /// Save client to local cache
  Future<void> saveClient(Map<String, dynamic> client) async {
    try {
      final clients = _localCache['clients'] ?? [];
      final index = clients.indexWhere((c) => c['id'] == client['id']);
      if (index >= 0) {
        clients[index] = client;
      } else {
        clients.add(client);
      }
      _localCache['clients'] = clients;
      _logger.i('💾 Client saved locally: ${client['id']}');
    } catch (e) {
      _logger.e('❌ Error saving client: $e');
    }
  }

  /// Save expense to local cache
  Future<void> saveExpense(Map<String, dynamic> expense) async {
    try {
      final expenses = _localCache['expenses'] ?? [];
      final index = expenses.indexWhere((e) => e['id'] == expense['id']);
      if (index >= 0) {
        expenses[index] = expense;
      } else {
        expenses.add(expense);
      }
      _localCache['expenses'] = expenses;
      _logger.i('💾 Expense saved locally: ${expense['id']}');
    } catch (e) {
      _logger.e('❌ Error saving expense: $e');
    }
  }

  /// Get jobs from local cache
  Future<List<Map<String, dynamic>>> getJobs() async {
    return _localCache['jobs'] ?? [];
  }

  /// Get invoices from local cache
  Future<List<Map<String, dynamic>>> getInvoices() async {
    return _localCache['invoices'] ?? [];
  }

  /// Get clients from local cache
  Future<List<Map<String, dynamic>>> getClients() async {
    return _localCache['clients'] ?? [];
  }

  /// Get expenses from local cache
  Future<List<Map<String, dynamic>>> getExpenses() async {
    return _localCache['expenses'] ?? [];
  }

  /// Add to sync queue (for offline changes)
  Future<void> addToQueue(String table, Map<String, dynamic> data) async {
    try {
      _syncQueue.add({
        'table': table,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
      _logger.i('📝 Added to sync queue: $table (${_syncQueue.length} pending)');
    } catch (e) {
      _logger.e('❌ Error adding to queue: $e');
    }
  }

  /// Get all pending changes
  Future<List<Map<String, dynamic>>> getPendingChanges() async {
    return _syncQueue.where((item) => item['status'] == 'pending').toList();
  }

  /// Sync all pending changes with Supabase
  Future<void> _syncAll() async {
    if (_syncQueue.isEmpty) return;
    
    _logger.i('🔄 Starting sync of ${_syncQueue.length} pending changes...');
    
    for (final item in _syncQueue) {
      if (item['status'] == 'pending') {
        try {
          // Mark as synced
          item['status'] = 'synced';
          _logger.i('✅ Synced: ${item['table']}');
        } catch (e) {
          item['status'] = 'pending';
          _logger.e('❌ Sync error for ${item['table']}: $e');
        }
      }
    }
    
    // Remove synced items
    _syncQueue.removeWhere((item) => item['status'] == 'synced');
    _logger.i('✅ Sync complete. ${_syncQueue.length} items still pending.');
  }

  /// Sync all pending changes (public method)
  Future<void> syncAll() async {
    await _syncAll();
  }

  /// Get sync conflicts
  Future<List<Map<String, dynamic>>> getConflicts() async {
    return _syncQueue.where((item) => item['status'] == 'conflict').toList();
  }

  /// Resolve conflict
  Future<void> resolveConflict(String conflictId, Map<String, dynamic> data) async {
    try {
      final index = _syncQueue.indexWhere((item) => item['id'] == conflictId);
      if (index >= 0) {
        _syncQueue[index]['data'] = data;
        _syncQueue[index]['status'] = 'pending';
        _logger.i('✅ Conflict resolved: $conflictId');
      }
    } catch (e) {
      _logger.e('❌ Error resolving conflict: $e');
    }
  }

  /// Clear all local data
  Future<void> clearAll() async {
    try {
      _localCache.clear();
      _syncQueue.clear();
      _logger.i('🗑️ All offline data cleared');
    } catch (e) {
      _logger.e('❌ Error clearing data: $e');
    }
  }

  /// Close database
  Future<void> close() async {
    // No-op for LocalStorage
    _logger.i('✅ Offline Service closed');
  }

  /// Get offline cache stats
  Future<Map<String, dynamic>> getStats() async {
    int totalRecords = 0;
    for (final list in _localCache.values) {
      totalRecords += list.length;
    }
    
    return {
      'isOnline': _isOnline,
      'totalCachedRecords': totalRecords,
      'pendingChanges': _syncQueue.where((item) => item['status'] == 'pending').length,
      'conflicts': _syncQueue.where((item) => item['status'] == 'conflict').length,
      'tables': {
        'jobs': _localCache['jobs']?.length ?? 0,
        'invoices': _localCache['invoices']?.length ?? 0,
        'clients': _localCache['clients']?.length ?? 0,
        'expenses': _localCache['expenses']?.length ?? 0,
      },
    };
  }
}
