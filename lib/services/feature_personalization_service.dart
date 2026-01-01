import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

final _logger = Logger();

/// Feature Personalization Service
/// Allows users to customize which features display on mobile/tablet interfaces
/// Mobile: Max 8 features | Tablet: Max 12 features
class FeaturePersonalizationService {
  static final FeaturePersonalizationService _instance = 
      FeaturePersonalizationService._internal();
  
  final supabase = Supabase.instance.client;

  // Device constants
  static const int MOBILE_MAX_FEATURES = 8;
  static const int TABLET_MAX_FEATURES = 12;

  // Available features
  static const List<Map<String, dynamic>> ALL_FEATURES = [
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
    int maxFeatures = deviceType == 'mobile' ? MOBILE_MAX_FEATURES : TABLET_MAX_FEATURES;
    
    // Return top priority features up to max
    return ALL_FEATURES
        .take(maxFeatures)
        .map((f) => f['id'] as String)
        .toList();
  }

  /// Get all available features
  List<Map<String, dynamic>> getAllAvailableFeatures() {
    return List<Map<String, dynamic>>.from(ALL_FEATURES);
  }

  /// Get features by category
  List<Map<String, dynamic>> getFeaturesByCategory(String category) {
    return ALL_FEATURES
        .where((f) => f['category'] == category)
        .toList();
  }

  /// Get unique categories
  List<String> getAllCategories() {
    final categories = <String>{};
    for (var feature in ALL_FEATURES) {
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
      int maxFeatures = deviceType == 'mobile' ? MOBILE_MAX_FEATURES : TABLET_MAX_FEATURES;
      if (selectedFeatureIds.length > maxFeatures) {
        return {
          'error': 'Too many features selected',
          'max_allowed': maxFeatures,
          'selected': selectedFeatureIds.length,
        };
      }

      // Validate all feature IDs exist
      final validIds = ALL_FEATURES.map((f) => f['id']).toSet();
      for (var id in selectedFeatureIds) {
        if (!validIds.contains(id)) {
          return {'error': 'Invalid feature ID: $id'};
        }
      }

      // Get selected feature details
      final selectedFeatures = ALL_FEATURES
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
        return ALL_FEATURES
            .where((f) => defaultIds.contains(f['id']))
            .toList();
      }

      final selectedIds = List<String>.from(result['selected_features'] ?? []);
      return ALL_FEATURES
          .where((f) => selectedIds.contains(f['id']))
          .toList();
    } catch (e) {
      _logger.e('❌ Error fetching personalized features: $e');
      // Return defaults on error
      final defaultIds = getDefaultFeaturesForDevice(deviceType);
      return ALL_FEATURES
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

      int maxFeatures = deviceType == 'mobile' ? MOBILE_MAX_FEATURES : TABLET_MAX_FEATURES;
      
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
        'mobile_features_max': MOBILE_MAX_FEATURES,
        'mobile_features_available_slots': MOBILE_MAX_FEATURES - mobileFeatures.length,
        'tablet_features_selected': tabletFeatures.length,
        'tablet_features_max': TABLET_MAX_FEATURES,
        'tablet_features_available_slots': TABLET_MAX_FEATURES - tabletFeatures.length,
        'total_available_features': ALL_FEATURES.length,
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
        return ALL_FEATURES.map((f) => f['id'] as String).toList();
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
}
