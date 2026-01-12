import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'dart:math' show Random;

final _logger = Logger();

/// Feature Personalization Service
/// Allows users to customize which features display on mobile/tablet interfaces
/// Mobile: Recommended 6 best features (user-selectable) | Tablet: Recommended 8 features (user-selectable)
/// 
/// DEVICE FEATURE LIMITS PER SUBSCRIPTION:
/// SOLO: Mobile 2 devices / Tablet 1 device
/// TEAM: Mobile 3 devices / Tablet 2 devices  
/// WORKSHOP: Mobile 5 devices / Tablet 3 devices
class FeaturePersonalizationService {
  static final FeaturePersonalizationService _instance = 
      FeaturePersonalizationService._internal();
  
  final supabase = Supabase.instance.client;

  // DEPRECATED: Device type max features - now using subscription-based limits
  // @deprecated Use getMaxFeaturesForPlan() instead
  static const int mobileMaxFeatures = 6;  // Changed from 8 to 6 best features
  static const int tabletMaxFeatures = 8;  // Changed from 12 to 8 best features

  // Subscription device limits
  static const Map<String, Map<String, int>> deviceLimitsByPlan = {
    'solo': {'mobile_devices': 2, 'tablet_devices': 1},
    'team': {'mobile_devices': 3, 'tablet_devices': 2},
    'workshop': {'mobile_devices': 5, 'tablet_devices': 3},
    'enterprise': {'mobile_devices': 10, 'tablet_devices': 5},
  };

  // Default recommended features per device (users can customize)
  static const List<String> defaultMobileFeatures = [
    'dashboard',
    'jobs',
    'clients',
    'invoices',
    'calendar',
    'expenses',
  ];

  static const List<String> defaultTabletFeatures = [
    'dashboard',
    'jobs',
    'clients',
    'invoices',
    'calendar',
    'team',
    'dispatch',
    'analytics',
  ];

  // Available features
  static const List<Map<String, dynamic>> allFeatures = [
    {
      'id': 'dashboard',
      'name': 'Dashboard',
      'icon': 'dashboard',
      'category': 'core',
      'priority': 1,
      'description': 'Overview of all business metrics',
    },
    {
      'id': 'jobs',
      'name': 'Jobs',
      'icon': 'work',
      'category': 'core',
      'priority': 2,
      'description': 'Manage and track all jobs',
    },
    {
      'id': 'invoices',
      'name': 'Invoices',
      'icon': 'receipt',
      'category': 'billing',
      'priority': 3,
      'description': 'Create and manage invoices',
    },
    {
      'id': 'clients',
      'name': 'Clients',
      'icon': 'people',
      'category': 'core',
      'priority': 4,
      'description': 'Client management and history',
    },
    {
      'id': 'calendar',
      'name': 'Calendar',
      'icon': 'calendar_today',
      'category': 'scheduling',
      'priority': 5,
      'description': 'Job scheduling and calendar view',
    },
    {
      'id': 'team',
      'name': 'Team',
      'icon': 'group',
      'category': 'management',
      'priority': 6,
      'description': 'Manage team members and roles',
    },
    {
      'id': 'dispatch',
      'name': 'Dispatch',
      'icon': 'location_on',
      'category': 'operations',
      'priority': 7,
      'description': 'Dispatch jobs to team members',
    },
    {
      'id': 'inventory',
      'name': 'Inventory',
      'icon': 'inventory_2',
      'category': 'operations',
      'priority': 8,
      'description': 'Track materials and stock levels',
    },
    {
      'id': 'expenses',
      'name': 'Expenses',
      'icon': 'receipt_long',
      'category': 'accounting',
      'priority': 9,
      'description': 'Track business expenses',
    },
    {
      'id': 'reports',
      'name': 'Reports',
      'icon': 'analytics',
      'category': 'insights',
      'priority': 10,
      'description': 'Generate business reports',
    },
    {
      'id': 'ai_agents',
      'name': 'AI Agents',
      'icon': 'smart_toy',
      'category': 'ai',
      'priority': 11,
      'description': 'CEO, COO, CFO autonomous agents',
    },
    {
      'id': 'marketing',
      'name': 'Marketing',
      'icon': 'campaign',
      'category': 'marketing',
      'priority': 12,
      'description': 'Email and SMS marketing automation',
    },
    {
      'id': 'settings',
      'name': 'Settings',
      'icon': 'settings',
      'category': 'admin',
      'priority': 13,
      'description': 'Account and app settings',
    },
  ];

  FeaturePersonalizationService._internal();

  factory FeaturePersonalizationService() {
    return _instance;
  }

  /// Get default featured features for a device type
  List<String> getDefaultFeaturesForDevice(String deviceType) {
    // 'mobile' or 'tablet'
    int maxFeatures = deviceType == 'mobile' ? mobileMaxFeatures : tabletMaxFeatures;
    
    // Return top priority features up to max
    return allFeatures
        .take(maxFeatures)
        .map((f) => f['id'] as String)
        .toList();
  }

  /// Get all available features
  List<Map<String, dynamic>> getAllAvailableFeatures() {
    return List<Map<String, dynamic>>.from(allFeatures);
  }

  /// Get features by category
  List<Map<String, dynamic>> getFeaturesByCategory(String category) {
    return allFeatures
        .where((f) => f['category'] == category)
        .toList();
  }

  /// Get unique categories
  List<String> getAllCategories() {
    final categories = <String>{};
    for (var feature in allFeatures) {
      categories.add(feature['category'] as String);
    }
    return categories.toList();
  }

  /// Save personalized features for a user on a device
  Future<Map<String, dynamic>> savePersonalizedFeatures({
    required String userId,
    required String deviceType, // 'mobile' or 'tablet'
    required List<String> selectedFeatureIds,
  }) async {
    try {
      _logger.i('💾 Saving personalized features for $deviceType: ${selectedFeatureIds.length} features');

      // Validate max features limit
      int maxFeatures = deviceType == 'mobile' ? mobileMaxFeatures : tabletMaxFeatures;
      if (selectedFeatureIds.length > maxFeatures) {
        return {
          'error': 'Too many features selected',
          'max_allowed': maxFeatures,
          'selected': selectedFeatureIds.length,
        };
      }

      // Validate all feature IDs exist
      final validIds = allFeatures.map((f) => f['id']).toSet();
      for (var id in selectedFeatureIds) {
        if (!validIds.contains(id)) {
          return {'error': 'Invalid feature ID: $id'};
        }
      }

      // Get selected feature details
      final selectedFeatures = allFeatures
          .where((f) => selectedFeatureIds.contains(f['id']))
          .toList();

      // Save to database
      await supabase
          .from('feature_personalization')
          .upsert({
            'user_id': userId,
            'device_type': deviceType,
            'selected_features': selectedFeatureIds,
            'feature_details': selectedFeatures,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,device_type');

      _logger.i('✅ Personalized features saved');

      return {
        'success': true,
        'device_type': deviceType,
        'total_features': selectedFeatureIds.length,
        'max_allowed': maxFeatures,
        'selected_feature_ids': selectedFeatureIds,
      };
    } catch (e) {
      _logger.e('❌ Error saving personalized features: $e');
      return {'error': e.toString()};
    }
  }

  /// Get personalized features for a user on a device
  Future<List<Map<String, dynamic>>> getPersonalizedFeatures({
    required String userId,
    required String deviceType,
  }) async {
    try {
      _logger.i('📋 Fetching personalized features for $deviceType');

      final result = await supabase
          .from('feature_personalization')
          .select('selected_features, feature_details')
          .eq('user_id', userId)
          .eq('device_type', deviceType)
          .maybeSingle();

      if (result == null) {
        // Return defaults if no personalization found
        _logger.i('ℹ️ No personalization found, returning defaults');
        final defaultIds = getDefaultFeaturesForDevice(deviceType);
        return allFeatures
            .where((f) => defaultIds.contains(f['id']))
            .toList();
      }

      final selectedIds = List<String>.from(result['selected_features'] ?? []);
      return allFeatures
          .where((f) => selectedIds.contains(f['id']))
          .toList();
    } catch (e) {
      _logger.e('❌ Error fetching personalized features: $e');
      // Return defaults on error
      final defaultIds = getDefaultFeaturesForDevice(deviceType);
      return allFeatures
          .where((f) => defaultIds.contains(f['id']))
          .toList();
    }
  }

  /// Add a feature to personalized list
  Future<void> addFeature({
    required String userId,
    required String deviceType,
    required String featureId,
  }) async {
    try {
      _logger.i('➕ Adding feature: $featureId to $deviceType');

      final current = await getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      int maxFeatures = deviceType == 'mobile' ? mobileMaxFeatures : tabletMaxFeatures;
      
      if (current.length >= maxFeatures) {
        _logger.w('⚠️ Max features reached for $deviceType');
        return;
      }

      final currentIds = current.map((f) => f['id'] as String).toList();
      if (!currentIds.contains(featureId)) {
        currentIds.add(featureId);
        
        await savePersonalizedFeatures(
          userId: userId,
          deviceType: deviceType,
          selectedFeatureIds: currentIds,
        );
      }

      _logger.i('✅ Feature added');
    } catch (e) {
      _logger.e('❌ Error adding feature: $e');
    }
  }

  /// Remove a feature from personalized list
  Future<void> removeFeature({
    required String userId,
    required String deviceType,
    required String featureId,
  }) async {
    try {
      _logger.i('➖ Removing feature: $featureId from $deviceType');

      final current = await getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      final currentIds = current
          .map((f) => f['id'] as String)
          .where((id) => id != featureId)
          .toList();

      await savePersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
        selectedFeatureIds: currentIds,
      );

      _logger.i('✅ Feature removed');
    } catch (e) {
      _logger.e('❌ Error removing feature: $e');
    }
  }

  /// Reorder features (change priority)
  Future<void> reorderFeatures({
    required String userId,
    required String deviceType,
    required List<String> orderedFeatureIds,
  }) async {
    try {
      _logger.i('🔄 Reordering features for $deviceType');

      await savePersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
        selectedFeatureIds: orderedFeatureIds,
      );

      _logger.i('✅ Features reordered');
    } catch (e) {
      _logger.e('❌ Error reordering features: $e');
    }
  }

  /// Reset to default features
  Future<void> resetToDefaults({
    required String userId,
    required String deviceType,
  }) async {
    try {
      _logger.i('🔄 Resetting features to default for $deviceType');

      final defaultIds = getDefaultFeaturesForDevice(deviceType);
      
      await savePersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
        selectedFeatureIds: defaultIds,
      );

      _logger.i('✅ Features reset to default');
    } catch (e) {
      _logger.e('❌ Error resetting to defaults: $e');
    }
  }

  /// Get personalization stats
  Future<Map<String, dynamic>> getPersonalizationStats({
    required String userId,
  }) async {
    try {
      _logger.i('📊 Getting personalization stats');

      final mobileFeatures = await getPersonalizedFeatures(
        userId: userId,
        deviceType: 'mobile',
      );

      final tabletFeatures = await getPersonalizedFeatures(
        userId: userId,
        deviceType: 'tablet',
      );

      return {
        'user_id': userId,
        'mobile_features_selected': mobileFeatures.length,
        'mobile_features_max': mobileMaxFeatures,
        'mobile_features_available_slots': mobileMaxFeatures - mobileFeatures.length,
        'tablet_features_selected': tabletFeatures.length,
        'tablet_features_max': tabletMaxFeatures,
        'tablet_features_available_slots': tabletMaxFeatures - tabletFeatures.length,
        'total_available_features': allFeatures.length,
      };
    } catch (e) {
      _logger.e('❌ Error getting stats: $e');
      return {'error': e.toString()};
    }
  }

  /// Get feature suggestions based on plan
  List<String> getSuggestedFeaturesForPlan(String planId) {
    // Suggest features based on plan tier
    switch (planId) {
      case 'solo_trades':
        return ['dashboard', 'jobs', 'invoices', 'clients', 'calendar', 'settings'];
      case 'small_team':
        return ['dashboard', 'jobs', 'invoices', 'clients', 'calendar', 'team', 'dispatch', 'inventory'];
      case 'workshop':
        return allFeatures.map((f) => f['id'] as String).toList();
      default:
        return getDefaultFeaturesForDevice('mobile');
    }
  }

  /// Quick toggle for feature visibility
  Future<void> toggleFeature({
    required String userId,
    required String deviceType,
    required String featureId,
  }) async {
    try {
      final current = await getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      final currentIds = current.map((f) => f['id'] as String).toList();

      if (currentIds.contains(featureId)) {
        await removeFeature(userId: userId, deviceType: deviceType, featureId: featureId);
      } else {
        await addFeature(userId: userId, deviceType: deviceType, featureId: featureId);
      }
    } catch (e) {
      _logger.e('❌ Error toggling feature: $e');
    }
  }

  /// ===== NEW: DEVICE LIMITS ENFORCEMENT =====

  /// Check if org can add more devices of given type based on subscription plan
  Future<bool> canAddDevice({
    required String orgId,
    required String deviceType, // 'mobile' or 'tablet'
  }) async {
    try {
      _logger.i('🔍 Checking device limit for org: $orgId - type: $deviceType');

      // Get org plan
      final org = await supabase
          .from('organizations')
          .select('plan, max_mobile_devices, max_tablet_devices')
          .eq('id', orgId)
          .single();

      final plan = org['plan'] as String? ?? 'solo';
      final limits = deviceLimitsByPlan[plan] ?? deviceLimitsByPlan['solo']!;
      
      final maxDevices = deviceType == 'mobile' 
          ? limits['mobile_devices'] ?? 2
          : limits['tablet_devices'] ?? 1;

      // Count current devices
      final devices = await supabase
          .from('devices')
          .select('id')
          .eq('org_id', orgId)
          .eq('device_type', deviceType);

      final currentCount = devices.length;
      final canAdd = currentCount < maxDevices;

      _logger.i('📱 Device check: $currentCount/$maxDevices for $deviceType');
      return canAdd;
    } catch (e) {
      _logger.e('❌ Error checking device limit: $e');
      return false;
    }
  }

  /// Get device limit for organization
  Future<Map<String, int>> getDeviceLimits({required String orgId}) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('plan')
          .eq('id', orgId)
          .single();

      final plan = org['plan'] as String? ?? 'solo';
      final limits = deviceLimitsByPlan[plan] ?? deviceLimitsByPlan['solo']!;

      return {
        'mobile_devices': limits['mobile_devices'] ?? 2,
        'tablet_devices': limits['tablet_devices'] ?? 1,
      };
    } catch (e) {
      _logger.e('❌ Error getting device limits: $e');
      return {'mobile_devices': 2, 'tablet_devices': 1}; // Default to SOLO limits
    }
  }

  /// Get current device usage for organization
  Future<Map<String, int>> getDeviceUsage({required String orgId}) async {
    try {
      final mobileDevices = await supabase
          .from('devices')
          .select('id')
          .eq('org_id', orgId)
          .eq('device_type', 'mobile');

      final tabletDevices = await supabase
          .from('devices')
          .select('id')
          .eq('org_id', orgId)
          .eq('device_type', 'tablet');

      return {
        'mobile_devices': mobileDevices.length,
        'tablet_devices': tabletDevices.length,
      };
    } catch (e) {
      _logger.e('❌ Error getting device usage: $e');
      return {'mobile_devices': 0, 'tablet_devices': 0};
    }
  }

  /// Get device limit summary (available slots remaining)
  Future<Map<String, dynamic>> getDeviceLimitSummary({required String orgId}) async {
    try {
      final limits = await getDeviceLimits(orgId: orgId);
      final usage = await getDeviceUsage(orgId: orgId);

      return {
        'mobile': {
          'limit': limits['mobile_devices'],
          'used': usage['mobile_devices'],
          'available': (limits['mobile_devices'] ?? 2) - (usage['mobile_devices'] ?? 0),
          'can_add': (usage['mobile_devices'] ?? 0) < (limits['mobile_devices'] ?? 2),
        },
        'tablet': {
          'limit': limits['tablet_devices'],
          'used': usage['tablet_devices'],
          'available': (limits['tablet_devices'] ?? 1) - (usage['tablet_devices'] ?? 0),
          'can_add': (usage['tablet_devices'] ?? 0) < (limits['tablet_devices'] ?? 1),
        },
      };
    } catch (e) {
      _logger.e('❌ Error getting device limit summary: $e');
      return {};
    }
  }

  /// Validate owner permission before device management
  Future<bool> isOrgOwner({
    required String orgId,
    required String userId,
  }) async {
    try {
      final org = await supabase
          .from('organizations')
          .select('owner_id')
          .eq('id', orgId)
          .single();

      final isOwner = org['owner_id'] == userId;
      _logger.i(isOwner ? '✅ User is org owner' : '❌ User is not org owner');
      return isOwner;
    } catch (e) {
      _logger.e('❌ Error checking owner permission: $e');
      return false;
    }
  }

  /// Register a new device with owner permission check
  Future<Map<String, dynamic>> registerDevice({
    required String orgId,
    required String userId,
    required String deviceType, // 'mobile' or 'tablet'
    required String deviceName,
    String? referenceCode,
  }) async {
    try {
      // 1. Check owner permission
      final isOwner = await isOrgOwner(orgId: orgId, userId: userId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can register devices',
          'status': 'unauthorized',
        };
      }

      // 2. Check device limit
      final canAdd = await canAddDevice(orgId: orgId, deviceType: deviceType);
      if (!canAdd) {
        final limits = await getDeviceLimits(orgId: orgId);
        final maxCount = deviceType == 'mobile' 
            ? limits['mobile_devices'] ?? 2 
            : limits['tablet_devices'] ?? 1;
        
        return {
          'error': '❌ Device limit reached for subscription plan',
          'device_type': deviceType,
          'max_allowed': maxCount,
          'status': 'limit_exceeded',
        };
      }

      // 3. Register device
      final newDevice = await supabase
          .from('devices')
          .insert({
            'org_id': orgId,
            'device_type': deviceType,
            'device_name': deviceName,
            'reference_code': referenceCode ?? _generateReferenceCode(),
            'registered_by': userId,
            'registered_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('✅ Device registered: $deviceName ($deviceType)');
      return {
        'success': true,
        'device': newDevice,
        'message': 'Device registered successfully',
      };
    } catch (e) {
      _logger.e('❌ Error registering device: $e');
      return {'error': e.toString()};
    }
  }

  /// Helper to generate unique reference code for device
  String _generateReferenceCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = _random;
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Random instance for code generation
  static final _random = Random();

  // ===== OWNER CONTROL LAYER =====
  // FULL CONTROL: Owner can force/disable features, lock org-wide, audit everything

  /// 🔐 OWNER ONLY: Force enable all features on a specific team member device
  /// Used for: Ensuring team member has access to all tools
  /// Only owner can do this
  Future<Map<String, dynamic>> forceEnableAllFeaturesOnDevice({
    required String orgId,
    required String ownerUserId,
    required String targetDeviceId,
    required String targetUserId,
  }) async {
    try {
      _logger.i('🔐 Owner forcing all features on device: $targetDeviceId');

      // SECURITY CHECK 1: Verify user is owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        _logger.w('❌ Unauthorized: Non-owner attempted feature override');
        return {
          'error': '❌ Only organization owner can force features',
          'status': 'unauthorized',
        };
      }

      // Get device info
      final device = await supabase
          .from('devices')
          .select('device_type')
          .eq('id', targetDeviceId)
          .eq('org_id', orgId)
          .single();

      final deviceType = device['device_type'] as String;
      final maxFeatures = deviceType == 'mobile' ? mobileMaxFeatures : tabletMaxFeatures;

      // Get all features for this device type
      final allFeatureIds = allFeatures
          .take(maxFeatures)
          .map((f) => f['id'] as String)
          .toList();

      // Force save all features
      await supabase
          .from('feature_personalization')
          .upsert({
            'user_id': targetUserId,
            'device_type': deviceType,
            'selected_features': allFeatureIds,
            'is_owner_enforced': true,
            'enforced_by': ownerUserId,
            'enforced_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,device_type');

      // LOG AUDIT
      await _logAudit(
        orgId: orgId,
        action: 'force_enable_allFeatures',
        performedBy: ownerUserId,
        targetUserId: targetUserId,
        targetDeviceId: targetDeviceId,
        details: 'All $maxFeatures features enabled on $deviceType device',
      );

      _logger.i('✅ All features enforced on device $targetDeviceId');

      return {
        'success': true,
        'message': 'All features enabled on device',
        'device_id': targetDeviceId,
        'features_enabled': allFeatureIds.length,
        'enforced': true,
      };
    } catch (e) {
      _logger.e('❌ Error forcing features: $e');
      return {'error': e.toString()};
    }
  }

  /// 🔐 OWNER ONLY: Disable specific features on team member device
  /// Used for: Compliance, security, reducing access
  Future<Map<String, dynamic>> disableFeaturesOnDevice({
    required String orgId,
    required String ownerUserId,
    required String targetDeviceId,
    required String targetUserId,
    required List<String> featuresToDisable,
  }) async {
    try {
      _logger.i('🔐 Owner disabling features on device: $targetDeviceId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can disable features',
          'status': 'unauthorized',
        };
      }

      // Get current features
      final current = await getPersonalizedFeatures(
        userId: targetUserId,
        deviceType: 'mobile', // Will get from device type
      );

      final currentIds = current.map((f) => f['id'] as String).toList();

      // Remove disabled features
      final updatedIds = currentIds
          .where((id) => !featuresToDisable.contains(id))
          .toList();

      // Update database
      await supabase
          .from('feature_personalization')
          .upsert({
            'user_id': targetUserId,
            'device_type': 'mobile',
            'selected_features': updatedIds,
            'disabled_features': featuresToDisable,
            'disabled_by_owner': true,
            'disabled_by': ownerUserId,
            'disabled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,device_type');

      // LOG AUDIT
      await _logAudit(
        orgId: orgId,
        action: 'disable_features',
        performedBy: ownerUserId,
        targetUserId: targetUserId,
        targetDeviceId: targetDeviceId,
        details: 'Disabled ${featuresToDisable.length} features: ${featuresToDisable.join(", ")}',
      );

      _logger.i('✅ Features disabled on device $targetDeviceId');

      return {
        'success': true,
        'message': 'Features disabled on device',
        'device_id': targetDeviceId,
        'features_disabled': featuresToDisable.length,
        'remaining_features': updatedIds.length,
      };
    } catch (e) {
      _logger.e('❌ Error disabling features: $e');
      return {'error': e.toString()};
    }
  }

  /// 🔒 OWNER ONLY: Lock feature selection org-wide
  /// Team members cannot change features when locked
  /// Used for: Compliance requirements, security policies
  Future<Map<String, dynamic>> lockFeaturesOrgWide({
    required String orgId,
    required String ownerUserId,
    required List<String> lockedFeatureIds,
    String? reason,
  }) async {
    try {
      _logger.i('🔒 Owner locking features org-wide for org: $orgId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can lock features',
          'status': 'unauthorized',
        };
      }

      // Save org-wide lock policy
      await supabase
          .from('organizations')
          .update({
            'feature_lock_enabled': true,
            'locked_features': lockedFeatureIds,
            'feature_lock_reason': reason ?? 'Security/Compliance Policy',
            'feature_lock_by': ownerUserId,
            'feature_lock_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orgId);

      // LOG AUDIT
      await _logAudit(
        orgId: orgId,
        action: 'lock_features_org_wide',
        performedBy: ownerUserId,
        details: 'Locked ${lockedFeatureIds.length} features org-wide. Reason: $reason',
      );

      _logger.i('✅ Features locked org-wide for all devices');

      return {
        'success': true,
        'message': 'Features locked org-wide',
        'locked_features': lockedFeatureIds.length,
        'reason': reason,
      };
    } catch (e) {
      _logger.e('❌ Error locking features: $e');
      return {'error': e.toString()};
    }
  }

  /// 🔓 OWNER ONLY: Unlock features org-wide
  Future<Map<String, dynamic>> unlockFeaturesOrgWide({
    required String orgId,
    required String ownerUserId,
  }) async {
    try {
      _logger.i('🔓 Owner unlocking features org-wide for org: $orgId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can unlock features',
          'status': 'unauthorized',
        };
      }

      // Unlock
      await supabase
          .from('organizations')
          .update({
            'feature_lock_enabled': false,
            'locked_features': null,
            'feature_lock_reason': null,
            'feature_lock_by': null,
            'feature_lock_at': null,
            'feature_unlock_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orgId);

      // LOG AUDIT
      await _logAudit(
        orgId: orgId,
        action: 'unlock_features_org_wide',
        performedBy: ownerUserId,
        details: 'Unlocked all features',
      );

      _logger.i('✅ Features unlocked org-wide');

      return {
        'success': true,
        'message': 'Features unlocked org-wide',
      };
    } catch (e) {
      _logger.e('❌ Error unlocking features: $e');
      return {'error': e.toString()};
    }
  }

  /// 📋 OWNER ONLY: Get audit log of all feature changes
  /// Shows: who changed what, when, and why
  Future<List<Map<String, dynamic>>> getFeatureAuditLog({
    required String orgId,
    required String ownerUserId,
    int limit = 100,
  }) async {
    try {
      _logger.i('📋 Owner viewing feature audit log for org: $orgId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        _logger.w('❌ Non-owner attempted to view audit log');
        return [];
      }

      // Fetch audit logs
      final logs = await supabase
          .from('feature_audit_log')
          .select()
          .eq('org_id', orgId)
          .order('created_at', ascending: false)
          .limit(limit);

      _logger.i('✅ Retrieved ${logs.length} audit log entries');

      return logs.cast<Map<String, dynamic>>();
    } catch (e) {
      _logger.e('❌ Error fetching audit log: $e');
      return [];
    }
  }

  /// 📊 OWNER ONLY: Get owner control status for entire org
  /// Shows: what's locked, who disabled what, enforcement status
  Future<Map<String, dynamic>> getOwnerControlStatus({
    required String orgId,
    required String ownerUserId,
  }) async {
    try {
      _logger.i('📊 Owner checking control status for org: $orgId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can view control status',
          'status': 'unauthorized',
        };
      }

      // Get org settings
      final org = await supabase
          .from('organizations')
          .select('feature_lock_enabled, locked_features, feature_lock_reason, feature_lock_by, feature_lock_at')
          .eq('id', orgId)
          .single();

      // Get devices with enforced features
      final enforcedDevices = await supabase
          .from('feature_personalization')
          .select('user_id, device_type, is_owner_enforced, enforced_at')
          .eq('org_id', orgId)
          .eq('is_owner_enforced', true);

      // Get devices with disabled features
      final disabledDevices = await supabase
          .from('feature_personalization')
          .select('user_id, device_type, disabled_features, disabled_at')
          .eq('org_id', orgId)
          .eq('disabled_by_owner', true);

      // Get recent audit entries
      final recentAudit = await supabase
          .from('feature_audit_log')
          .select()
          .eq('org_id', orgId)
          .order('created_at', ascending: false)
          .limit(10);

      return {
        'org_id': orgId,
        'org_wide_lock_enabled': org['feature_lock_enabled'] ?? false,
        'locked_features': org['locked_features'] ?? [],
        'lock_reason': org['feature_lock_reason'],
        'lock_started_at': org['feature_lock_at'],
        'devices_with_enforced_features': enforcedDevices.length,
        'devices_with_disabled_features': disabledDevices.length,
        'recent_changes': recentAudit.length,
        'last_change': recentAudit.isNotEmpty ? recentAudit.first['created_at'] : null,
        'status': '✅ Owner control active',
      };
    } catch (e) {
      _logger.e('❌ Error getting control status: $e');
      return {'error': e.toString()};
    }
  }

  /// 🚨 INTERNAL: Log all feature changes for audit trail
  /// Called by all owner control methods
  /// Never accessible to team members (internal only)
  Future<void> _logAudit({
    required String orgId,
    required String action,
    required String performedBy,
    String? targetUserId,
    String? targetDeviceId,
    String? details,
  }) async {
    try {
      await supabase
          .from('feature_audit_log')
          .insert({
            'org_id': orgId,
            'action': action,
            'performed_by': performedBy,
            'target_user_id': targetUserId,
            'target_device_id': targetDeviceId,
            'details': details,
            'timestamp': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });

      _logger.i('🔒 Audit logged: $action by $performedBy');
    } catch (e) {
      _logger.e('⚠️ Failed to log audit: $e');
      // Don't rethrow - audit failure shouldn't break the action
    }
  }

  /// 🔐 OWNER ONLY: Reset all team member features to defaults
  /// Used for: Compliance reset, security policy change
  Future<Map<String, dynamic>> resetAllTeamFeaturestoDefaults({
    required String orgId,
    required String ownerUserId,
    String? reason,
  }) async {
    try {
      _logger.i('🔐 Owner resetting all team features to defaults for org: $orgId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can reset features',
          'status': 'unauthorized',
        };
      }

      // Get all team members
      final members = await supabase
          .from('org_members')
          .select('user_id')
          .eq('org_id', orgId)
          .neq('role', 'owner');

      int resetCount = 0;

      // Reset each team member's features
      for (var member in members) {
        final userId = member['user_id'] as String;

        // Reset mobile features
        await supabase
            .from('feature_personalization')
            .upsert({
              'user_id': userId,
              'device_type': 'mobile',
              'selected_features': defaultMobileFeatures,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,device_type');

        // Reset tablet features
        await supabase
            .from('feature_personalization')
            .upsert({
              'user_id': userId,
              'device_type': 'tablet',
              'selected_features': defaultTabletFeatures,
              'updated_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,device_type');

        resetCount++;
      }

      // LOG AUDIT
      await _logAudit(
        orgId: orgId,
        action: 'reset_all_team_features',
        performedBy: ownerUserId,
        details: 'Reset features for $resetCount team members. Reason: $reason',
      );

      _logger.i('✅ Reset features for $resetCount team members');

      return {
        'success': true,
        'message': 'All team features reset to defaults',
        'members_reset': resetCount,
        'reason': reason,
      };
    } catch (e) {
      _logger.e('❌ Error resetting features: $e');
      return {'error': e.toString()};
    }
  }

  /// 🔐 OWNER ONLY: Get all team member devices with their feature status
  /// Shows: each device, assigned features, enforcement status
  Future<Map<String, dynamic>> getTeamDeviceControlPanel({
    required String orgId,
    required String ownerUserId,
  }) async {
    try {
      _logger.i('🔐 Owner viewing team device control panel for org: $orgId');

      // SECURITY CHECK: Verify owner
      final isOwner = await isOrgOwner(orgId: orgId, userId: ownerUserId);
      if (!isOwner) {
        return {
          'error': '❌ Only organization owner can view control panel',
          'status': 'unauthorized',
        };
      }

      // Get all team members (non-owner)
      final members = await supabase
          .from('org_members')
          .select('user_id, email')
          .eq('org_id', orgId)
          .neq('role', 'owner');

      // Get all devices
      final devices = await supabase
          .from('devices')
          .select('id, device_type, device_name, registered_by, registered_at')
          .eq('org_id', orgId);

      // Get all feature personalization
      final features = await supabase
          .from('feature_personalization')
          .select();

      // Build control panel data
      final deviceList = <Map<String, dynamic>>[];

      for (var device in devices) {
        final deviceId = device['id'] as String;
        final userId = device['registered_by'] as String;

        final memberInfo = members.firstWhere(
          (m) => m['user_id'] == userId,
          orElse: () => {'email': 'Unknown'},
        );

        final featureInfo = features.firstWhere(
          (f) => f['user_id'] == userId,
          orElse: () => {},
        );

        deviceList.add({
          'device_id': deviceId,
          'device_name': device['device_name'],
          'device_type': device['device_type'],
          'member_email': memberInfo['email'],
          'registered_at': device['registered_at'],
          'features_count': (featureInfo['selected_features'] as List?)?.length ?? 0,
          'is_enforced': featureInfo['is_owner_enforced'] ?? false,
          'has_disabled_features': (featureInfo['disabled_features'] as List?)?.isNotEmpty ?? false,
          'actions_available': ['force_allFeatures', 'disable_features', 'reset_to_default'],
        });
      }

      _logger.i('✅ Retrieved control panel for ${deviceList.length} devices');

      return {
        'success': true,
        'org_id': orgId,
        'total_devices': deviceList.length,
        'devices': deviceList,
        'owner_actions': [
          'force_enable_allFeatures_on_device',
          'disable_features_on_device',
          'lock_features_org_wide',
          'unlock_features_org_wide',
          'reset_all_team_features_to_defaults',
          'view_audit_log',
          'view_control_status',
        ],
      };
    } catch (e) {
      _logger.e('❌ Error getting control panel: $e');
      return {'error': e.toString()};
    }
  }
}
