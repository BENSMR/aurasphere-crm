import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:math';

final _logger = Logger();

/// Device Management Service
/// Manages mobile and tablet devices with permission control and reference codes
class DeviceManagementService {
  static final DeviceManagementService _instance =
      DeviceManagementService._internal();

  final supabase = Supabase.instance.client;

  DeviceManagementService._internal();

  factory DeviceManagementService() {
    return _instance;
  }

  /// Generate device reference code
  String _generateDeviceCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'DEV-${List.generate(10, (index) => chars[random.nextInt(chars.length)])
            .join()}';
  }

  /// Register new device
  Future<Map<String, dynamic>> registerDevice({
    required String orgId,
    required String deviceName,
    required String deviceType, // 'mobile' or 'tablet'
    required String memberId,
    required String deviceModel,
    required String osVersion,
  }) async {
    try {
      _logger.i('📱 Registering device: $deviceName');

      final deviceCode = _generateDeviceCode();

      final result = await supabase
          .from('device_management')
          .insert({
            'org_id': orgId,
            'member_id': memberId,
            'device_code': deviceCode,
            'device_name': deviceName,
            'device_type': deviceType,
            'device_model': deviceModel,
            'os_version': osVersion,
            'is_active': true,
            'approval_status': 'pending',
            'last_accessed': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('✅ Device registered with code: $deviceCode');
      return {
        'success': true,
        'device_code': deviceCode,
        'device': result,
      };
    } catch (e) {
      _logger.e('❌ Error registering device: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Approve device (CEO only)
  Future<Map<String, dynamic>> approveDevice({
    required String deviceId,
    required String approvedBy,
  }) async {
    try {
      _logger.i('✅ Approving device: $deviceId');

      final result = await supabase
          .from('device_management')
          .update({
            'approval_status': 'approved',
            'approved_by': approvedBy,
            'approved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deviceId)
          .select()
          .single();

      _logger.i('✅ Device approved');
      return {'success': true, 'device': result};
    } catch (e) {
      _logger.e('❌ Error approving device: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Revoke device access (CEO only)
  Future<Map<String, dynamic>> revokeDeviceAccess(String deviceId) async {
    try {
      _logger.i('🚫 Revoking device access: $deviceId');

      final result = await supabase
          .from('device_management')
          .update({
            'is_active': false,
            'revoked_at': DateTime.now().toIso8601String(),
            'revoked_reason': 'Revoked by CEO',
          })
          .eq('id', deviceId)
          .select()
          .single();

      _logger.i('✅ Device access revoked');
      return {'success': true, 'device': result};
    } catch (e) {
      _logger.e('❌ Error revoking access: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all devices for organization
  Future<List<Map<String, dynamic>>> getOrgDevices(String orgId) async {
    try {
      _logger.i('📱 Fetching devices for org: $orgId');

      final devices = await supabase
          .from('device_management')
          .select('*')
          .eq('org_id', orgId)
          .order('created_at', ascending: false);

      _logger.i('✅ Loaded ${devices.length} devices');
      return List<Map<String, dynamic>>.from(devices);
    } catch (e) {
      _logger.e('❌ Error fetching devices: $e');
      return [];
    }
  }

  /// Get devices for specific member
  Future<List<Map<String, dynamic>>> getMemberDevices(String memberId) async {
    try {
      _logger.i('📱 Fetching devices for member: $memberId');

      final devices = await supabase
          .from('device_management')
          .select('*')
          .eq('member_id', memberId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(devices);
    } catch (e) {
      _logger.e('❌ Error fetching member devices: $e');
      return [];
    }
  }

  /// Get device by code
  Future<Map<String, dynamic>?> getDeviceByCode(String deviceCode) async {
    try {
      _logger.i('🔍 Looking up device by code: $deviceCode');

      final result = await supabase
          .from('device_management')
          .select('*')
          .eq('device_code', deviceCode)
          .maybeSingle();

      if (result != null) {
        _logger.i('✅ Device found: ${result['device_name']}');
      }
      return result;
    } catch (e) {
      _logger.e('❌ Error looking up device: $e');
      return null;
    }
  }

  /// Update device last accessed timestamp
  Future<void> updateLastAccessed(String deviceId) async {
    try {
      await supabase
          .from('device_management')
          .update({
            'last_accessed': DateTime.now().toIso8601String(),
          })
          .eq('id', deviceId);
    } catch (e) {
      _logger.e('❌ Error updating last accessed: $e');
    }
  }

  /// Set device permissions
  Future<Map<String, dynamic>> setDevicePermissions({
    required String deviceId,
    required List<String> permissions,
  }) async {
    try {
      _logger.i('🔒 Setting device permissions');

      final result = await supabase
          .from('device_management')
          .update({
            'permissions': permissions,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deviceId)
          .select()
          .single();

      _logger.i('✅ Device permissions updated');
      return {'success': true, 'device': result};
    } catch (e) {
      _logger.e('❌ Error setting permissions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get pending device approvals
  Future<List<Map<String, dynamic>>> getPendingDeviceApprovals(
      String orgId) async {
    try {
      _logger.i('⏳ Fetching pending device approvals');

      final pending = await supabase
          .from('device_management')
          .select(
              '*, org_members(full_name, email), device_management!inner(approval_status)')
          .eq('org_id', orgId)
          .eq('approval_status', 'pending')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(pending);
    } catch (e) {
      _logger.e('❌ Error fetching pending approvals: $e');
      return [];
    }
  }

  /// Get device usage statistics
  Future<Map<String, dynamic>> getDeviceStats(String orgId) async {
    try {
      final devices = await supabase
          .from('device_management')
          .select('device_type, is_active, approval_status')
          .eq('org_id', orgId);

      int totalDevices = devices.length;
      int activeDevices = 0;
      int mobileDevices = 0;
      int tabletDevices = 0;
      int approvedDevices = 0;
      int pendingDevices = 0;

      for (var device in devices) {
        if (device['is_active'] == true) activeDevices++;
        if (device['device_type'] == 'mobile') mobileDevices++;
        if (device['device_type'] == 'tablet') tabletDevices++;
        if (device['approval_status'] == 'approved') approvedDevices++;
        if (device['approval_status'] == 'pending') pendingDevices++;
      }

      return {
        'total_devices': totalDevices,
        'active_devices': activeDevices,
        'mobile_devices': mobileDevices,
        'tablet_devices': tabletDevices,
        'approved_devices': approvedDevices,
        'pending_devices': pendingDevices,
        'inactive_devices': totalDevices - activeDevices,
      };
    } catch (e) {
      _logger.e('❌ Error getting device stats: $e');
      return {};
    }
  }

  /// Remote wipe device data
  Future<Map<String, dynamic>> remoteWipeDevice(String deviceId) async {
    try {
      _logger.i('🗑️ Remote wiping device: $deviceId');

      final result = await supabase
          .from('device_management')
          .update({
            'is_wiped': true,
            'wiped_at': DateTime.now().toIso8601String(),
            'is_active': false,
          })
          .eq('id', deviceId)
          .select()
          .single();

      _logger.i('✅ Device wiped');
      return {'success': true, 'device': result};
    } catch (e) {
      _logger.e('❌ Error wiping device: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get device access log
  Future<List<Map<String, dynamic>>> getDeviceAccessLog(
      String deviceId) async {
    try {
      _logger.i('📋 Fetching access log for device: $deviceId');

      final logs = await supabase
          .from('device_access_logs')
          .select('*')
          .eq('device_id', deviceId)
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      _logger.e('❌ Error fetching access log: $e');
      return [];
    }
  }

  /// Log device access
  Future<void> logDeviceAccess({
    required String deviceId,
    required String memberId,
    required String action,
  }) async {
    try {
      await supabase.from('device_access_logs').insert({
        'device_id': deviceId,
        'member_id': memberId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('❌ Error logging device access: $e');
    }
  }
}
