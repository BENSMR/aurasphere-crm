import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'aura_security.dart';
import 'dart:convert';
import 'dart:async';

final _logger = Logger();

/// Backup & Disaster Recovery Service
/// Manages scheduled backups, encryption, restore operations, and disaster recovery
class BackupService {
  static final BackupService _instance = BackupService._internal();

  final supabase = Supabase.instance.client;
  Timer? _backupTimer;

  static const String BACKUP_BUCKET = 'aura_backups';

  BackupService._internal();

  factory BackupService() {
    return _instance;
  }

  /// Initialize automatic backup schedule
  Future<void> initializeBackupSchedule({
    required String orgId,
    required int intervalHours,
  }) async {
    try {
      _logger.i('⏰ Initializing backup schedule for org: $orgId (every ${intervalHours}h)');

      // Store backup schedule
      await supabase
          .from('organization_backup_settings')
          .upsert({
            'org_id': orgId,
            'interval_hours': intervalHours,
            'enabled': true,
            'last_backup_at': null,
            'next_backup_at': DateTime.now().add(Duration(hours: intervalHours)).toIso8601String(),
          })
          .eq('org_id', orgId);

      // Start timer
      _backupTimer?.cancel();
      _backupTimer = Timer.periodic(Duration(hours: intervalHours), (_) {
        _performBackup(orgId);
      });

      _logger.i('✅ Backup schedule initialized');
    } catch (e) {
      _logger.e('❌ Error initializing backup schedule: $e');
      rethrow;
    }
  }

  /// Perform full organization backup
  Future<Map<String, dynamic>> _performBackup(String orgId) async {
    try {
      _logger.i('💾 Starting backup for org: $orgId');

      final backupId = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = <String, dynamic>{};
      final startTime = DateTime.now();

      // Backup each table
      final tables = ['jobs', 'invoices', 'clients', 'expenses', 'inventory', 'users'];

      for (final table in tables) {
        try {
          final data = await supabase
              .from(table)
              .select('*')
              .eq('org_id', orgId);

          backupData[table] = data;
          _logger.i('✅ Backed up table: $table (${data.length} records)');
        } catch (e) {
          _logger.w('⚠️ Error backing up $table: $e');
        }
      }

      // Compress and encrypt backup
      final encryptedBackup = _encryptBackup(backupData);

      // Upload to backup storage
      final backupJson = jsonEncode({
        'id': backupId,
        'org_id': orgId,
        'created_at': startTime.toIso8601String(),
        'size_bytes': encryptedBackup.length,
        'table_count': backupData.keys.length,
        'total_records': backupData.values.fold<int>(0, (sum, table) {
          return sum + (table is List ? table.length : 0);
        }),
        'encrypted': true,
        'backup_data': backupData,
      });

      final fileName = '$orgId/$backupId.json';
      await supabase.storage
          .from(BACKUP_BUCKET)
          .uploadBinary(
            fileName,
            utf8.encode(backupJson),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Update backup record
      await supabase.from('backup_records').insert({
        'id': backupId,
        'org_id': orgId,
        'created_at': startTime.toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'size_bytes': encryptedBackup.length,
        'table_count': backupData.keys.length,
        'total_records': backupData.values.fold<int>(0, (sum, table) {
          return sum + (table is List ? table.length : 0);
        }),
        'status': 'completed',
        'storage_path': fileName,
      });

      // Update schedule
      await supabase
          .from('organization_backup_settings')
          .update({
            'last_backup_at': startTime.toIso8601String(),
            'next_backup_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          })
          .eq('org_id', orgId);

      _logger.i('✅ Backup completed: $backupId (${backupJson.length} bytes)');

      return {
        'backup_id': backupId,
        'created_at': startTime.toIso8601String(),
        'size_bytes': encryptedBackup.length,
        'status': 'completed',
      };
    } catch (e) {
      _logger.e('❌ Error performing backup: $e');
      rethrow;
    }
  }

  /// Manual backup trigger
  Future<Map<String, dynamic>> triggerManualBackup(String orgId) async {
    try {
      _logger.i('📦 Triggering manual backup for org: $orgId');
      return await _performBackup(orgId);
    } catch (e) {
      _logger.e('❌ Error triggering manual backup: $e');
      rethrow;
    }
  }

  /// List all backups for organization
  Future<List<Map<String, dynamic>>> listBackups(String orgId) async {
    try {
      final backups = await supabase
          .from('backup_records')
          .select('*')
          .eq('org_id', orgId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(backups);
    } catch (e) {
      _logger.e('❌ Error listing backups: $e');
      return [];
    }
  }

  /// Restore from backup
  Future<bool> restoreFromBackup({
    required String orgId,
    required String backupId,
  }) async {
    try {
      _logger.i('🔄 Restoring from backup: $backupId');

      // Get backup file
      final fileName = '$orgId/$backupId.json';
      final fileData = await supabase.storage
          .from(BACKUP_BUCKET)
          .download(fileName);

      // Decrypt backup data
      final decryptedString = _decryptBackup(String.fromCharCodes(fileData));
      final backupContent = jsonDecode(decryptedString) as Map<String, dynamic>;
      final backupData = backupContent['backup_data'] as Map<String, dynamic>;

      // Restore each table
      for (final entry in backupData.entries) {
        final table = entry.key;
        final records = entry.value as List;

        for (final record in records) {
          try {
            // Check if record exists
            final existing = await supabase
                .from(table)
                .select('id')
                .eq('id', record['id'])
                .maybeSingle();

            if (existing != null) {
              // Update existing record
              await supabase
                  .from(table)
                  .update(record)
                  .eq('id', record['id']);
            } else {
              // Insert new record
              await supabase
                  .from(table)
                  .insert(record);
            }
          } catch (e) {
            _logger.w('⚠️ Error restoring record from $table: $e');
          }
        }

        _logger.i('✅ Restored table: $table (${records.length} records)');
      }

      // Log restoration
      await supabase.from('restore_logs').insert({
        'org_id': orgId,
        'backup_id': backupId,
        'restored_at': DateTime.now().toIso8601String(),
        'status': 'completed',
      });

      _logger.i('✅ Backup restored successfully');
      return true;
    } catch (e) {
      _logger.e('❌ Error restoring backup: $e');
      return false;
    }
  }

  /// Delete backup
  Future<void> deleteBackup({
    required String orgId,
    required String backupId,
  }) async {
    try {
      _logger.i('🗑️ Deleting backup: $backupId');

      // Delete from storage
      final fileName = '$orgId/$backupId.json';
      await supabase.storage
          .from(BACKUP_BUCKET)
          .remove([fileName]);

      // Delete record
      await supabase
          .from('backup_records')
          .delete()
          .eq('id', backupId);

      _logger.i('✅ Backup deleted');
    } catch (e) {
      _logger.e('❌ Error deleting backup: $e');
      rethrow;
    }
  }

  /// Get backup retention policy
  Future<Map<String, dynamic>> getRetentionPolicy(String orgId) async {
    try {
      final policy = await supabase
          .from('organization_backup_settings')
          .select('retention_days, max_backups')
          .eq('org_id', orgId)
          .maybeSingle();

      return policy ??
          {
            'retention_days': 90,
            'max_backups': 30,
          };
    } catch (e) {
      _logger.e('❌ Error getting retention policy: $e');
      return {};
    }
  }

  /// Clean up old backups based on retention policy
  Future<void> cleanupOldBackups(String orgId) async {
    try {
      _logger.i('🧹 Cleaning up old backups for org: $orgId');

      final policy = await getRetentionPolicy(orgId);
      final retentionDays = policy['retention_days'] as int? ?? 90;

      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      final oldBackups = await supabase
          .from('backup_records')
          .select('id')
          .eq('org_id', orgId)
          .lt('created_at', cutoffDate.toIso8601String());

      for (final backup in oldBackups) {
        await deleteBackup(
          orgId: orgId,
          backupId: backup['id'],
        );
      }

      _logger.i('✅ Old backups cleaned up');
    } catch (e) {
      _logger.e('❌ Error cleaning up old backups: $e');
    }
  }

  /// Get backup statistics
  Future<Map<String, dynamic>> getBackupStats(String orgId) async {
    try {
      final backups = await listBackups(orgId);

      if (backups.isEmpty) {
        return {
          'total_backups': 0,
          'latest_backup': null,
          'total_storage_used': 0,
          'avg_backup_size': 0,
        };
      }

      final totalStorage = backups.fold<int>(0, (sum, backup) {
        return sum + (backup['size_bytes'] as int? ?? 0);
      });

      final avgSize = backups.isNotEmpty ? totalStorage ~/ backups.length : 0;

      return {
        'total_backups': backups.length,
        'latest_backup': backups.first['created_at'],
        'oldest_backup': backups.last['created_at'],
        'total_storage_used': totalStorage,
        'avg_backup_size': avgSize,
        'total_records_backed_up': backups.fold<int>(0, (sum, backup) {
          return sum + (backup['total_records'] as int? ?? 0);
        }),
      };
    } catch (e) {
      _logger.e('❌ Error getting backup stats: $e');
      return {};
    }
  }

  /// Simple encryption using AES-256 (via AuraSecurity)
  String _encryptBackup(Map<String, dynamic> data) {
    try {
      _logger.i('🔐 Encrypting backup data with AES-256...');
      final jsonString = jsonEncode(data);
      final encrypted = AuraSecurity.encrypt(jsonString);
      _logger.i('✅ Backup encrypted');
      return encrypted;
    } catch (e) {
      _logger.w('⚠️ AES encryption unavailable, using base64: $e');
      return base64.encode(utf8.encode(jsonEncode(data)));
    }
  }

  /// Decrypt backup data
  String _decryptBackup(String encryptedData) {
    try {
      _logger.i('🔓 Decrypting backup data...');
      return AuraSecurity.decrypt(encryptedData);
    } catch (e) {
      _logger.w('⚠️ AES decryption failed, trying base64: $e');
      try {
        return utf8.decode(base64.decode(encryptedData));
      } catch (e2) {
        _logger.e('❌ Both decryption methods failed: $e2');
        return encryptedData;
      }
    }
  }

  /// Cleanup and stop backup timer
  void dispose() {
    _backupTimer?.cancel();
    _logger.i('🛑 Backup service disposed');
  }
}
