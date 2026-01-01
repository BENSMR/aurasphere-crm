import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feature_personalization_service.dart';

/// Helper utility for integrating feature personalization throughout the app
class FeaturePersonalizationHelper {
  static final _instance = FeaturePersonalizationHelper._internal();
  final supabase = Supabase.instance.client;
  late final service = FeaturePersonalizationService();

  // Cache to avoid repeated database calls
  final Map<String, List<Map<String, dynamic>>> _featureCache = {};
  final Map<String, bool> _featureAvailabilityCache = {};

  FeaturePersonalizationHelper._internal();

  factory FeaturePersonalizationHelper() {
    return _instance;
  }

  /// Get device type based on screen width
  String getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 'mobile';
    } else if (width < 1200) {
      return 'tablet';
    } else {
      return 'desktop';
    }
  }

  /// Get personalized features with caching
  Future<List<Map<String, dynamic>>> getPersonalizedFeatures({
    required String userId,
    required String deviceType,
    bool ignoreCache = false,
  }) async {
    final cacheKey = '$userId:$deviceType';

    if (!ignoreCache && _featureCache.containsKey(cacheKey)) {
      return _featureCache[cacheKey]!;
    }

    try {
      final features = await service.getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      _featureCache[cacheKey] = features;
      return features;
    } catch (e) {
      print('❌ Error fetching personalized features: $e');
      // Return defaults on error
      return service.getDefaultFeaturesForDevice(deviceType)
          .map((id) => service.getAllAvailableFeatures()
              .firstWhere(
                (f) => f['id'] == id,
                orElse: () => {'id': id, 'name': id},
              ))
          .toList();
    }
  }

  /// Check if feature is available for user on device
  Future<bool> isFeatureAvailable({
    required String userId,
    required String deviceType,
    required String featureId,
  }) async {
    final cacheKey = '$userId:$deviceType:$featureId';

    if (_featureAvailabilityCache.containsKey(cacheKey)) {
      return _featureAvailabilityCache[cacheKey]!;
    }

    try {
      final features = await getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      final available = features.any((f) => f['id'] == featureId);
      _featureAvailabilityCache[cacheKey] = available;
      return available;
    } catch (e) {
      print('❌ Error checking feature availability: $e');
      return false;
    }
  }

  /// Get feature by ID with full metadata
  Map<String, dynamic>? getFeatureMetadata(String featureId) {
    try {
      final allFeatures = service.getAllAvailableFeatures();
      return allFeatures.firstWhere(
        (f) => f['id'] == featureId,
        orElse: () => {},
      );
    } catch (e) {
      print('❌ Error getting feature metadata: $e');
      return null;
    }
  }

  /// Get feature display name
  String getFeatureName(String featureId) {
    return getFeatureMetadata(featureId)?['name'] ?? featureId;
  }

  /// Get feature description
  String getFeatureDescription(String featureId) {
    return getFeatureMetadata(featureId)?['description'] ?? '';
  }

  /// Get icon for feature (as IconData)
  IconData getFeatureIcon(String featureId) {
    final iconMap = {
      'dashboard': Icons.dashboard,
      'jobs': Icons.work,
      'invoices': Icons.receipt,
      'clients': Icons.people,
      'calendar': Icons.calendar_today,
      'team': Icons.group,
      'dispatch': Icons.location_on,
      'inventory': Icons.inventory_2,
      'expenses': Icons.receipt_long,
      'reports': Icons.analytics,
      'ai_agents': Icons.smart_toy,
      'marketing': Icons.campaign,
      'settings': Icons.settings,
    };

    return iconMap[featureId] ?? Icons.help;
  }

  /// Build navigation items for visible features
  Future<List<NavigationDestination>> buildNavigationDestinations({
    required String userId,
    required String deviceType,
    required int? selectedIndex,
    required Function(int) onNavigate,
  }) async {
    try {
      final features = await getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      return features
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final feature = entry.value;

            return NavigationDestination(
              icon: Icon(getFeatureIcon(feature['id'] as String)),
              label: feature['name'] as String,
              tooltip: feature['description'] as String? ?? '',
            );
          })
          .toList();
    } catch (e) {
      print('❌ Error building navigation: $e');
      return [];
    }
  }

  /// Clear cache (call after personalization changes)
  void clearCache([String? userId, String? deviceType]) {
    if (userId == null) {
      _featureCache.clear();
      _featureAvailabilityCache.clear();
    } else if (deviceType == null) {
      _featureCache.removeWhere((key, _) => key.startsWith(userId));
      _featureAvailabilityCache
          .removeWhere((key, _) => key.startsWith(userId));
    } else {
      final cacheKey = '$userId:$deviceType';
      _featureCache.remove(cacheKey);
      _featureAvailabilityCache
          .removeWhere((key, _) => key.startsWith(cacheKey));
    }
  }

  /// Get feature limit for device
  int getFeatureLimitForDevice(String deviceType) {
    return deviceType == 'mobile'
        ? FeaturePersonalizationService.MOBILE_MAX_FEATURES
        : FeaturePersonalizationService.TABLET_MAX_FEATURES;
  }

  /// Get remaining feature slots
  Future<int> getRemainingSlots({
    required String userId,
    required String deviceType,
  }) async {
    try {
      final features = await getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      final limit = getFeatureLimitForDevice(deviceType);
      return (limit - features.length).clamp(0, limit);
    } catch (e) {
      print('❌ Error getting remaining slots: $e');
      return 0;
    }
  }

  /// Build feature info card for display
  Widget buildFeatureInfoCard(
    String featureId, {
    bool showIcon = true,
    double iconSize = 32,
  }) {
    final metadata = getFeatureMetadata(featureId);

    if (metadata == null || metadata.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                getFeatureIcon(featureId),
                size: iconSize,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              metadata['name'] ?? featureId,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if ((metadata['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                metadata['description'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show feature customization dialog
  Future<void> showFeatureCustomizationDialog(
    BuildContext context, {
    required String userId,
    required String deviceType,
  }) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Features'),
        content: Text(
          'Go to Settings to customize which features appear on your $deviceType.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/feature-personalization');
            },
            child: const Text('Customize'),
          ),
        ],
      ),
    );
  }

  /// Get personalization recommendations for plan
  List<String> getRecommendedFeatures(String planId) {
    return service.getSuggestedFeaturesForPlan(planId);
  }

  /// Build feature grid
  Widget buildFeatureGrid({
    required List<Map<String, dynamic>> features,
    required double spacing,
    required int crossAxisCount,
    VoidCallback? onFeatureSelected,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final feature = features[index];
        return GestureDetector(
          onTap: onFeatureSelected,
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  getFeatureIcon(feature['id'] as String),
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),
                Text(
                  feature['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Initialize personalization for new user
  Future<void> initializeForNewUser(String userId) async {
    try {
      // Set up mobile preferences
      await service.savePersonalizedFeatures(
        userId: userId,
        deviceType: 'mobile',
        selectedFeatureIds:
            service.getDefaultFeaturesForDevice('mobile'),
      );

      // Set up tablet preferences
      await service.savePersonalizedFeatures(
        userId: userId,
        deviceType: 'tablet',
        selectedFeatureIds:
            service.getDefaultFeaturesForDevice('tablet'),
      );

      print('✅ Feature personalization initialized for user: $userId');
    } catch (e) {
      print('❌ Error initializing feature personalization: $e');
    }
  }

  /// Export personalization settings (for backup/export)
  Future<Map<String, dynamic>> exportPersonalizationSettings({
    required String userId,
  }) async {
    try {
      final stats = await service.getPersonalizationStats(userId: userId);
      final mobile = await getPersonalizedFeatures(
        userId: userId,
        deviceType: 'mobile',
      );
      final tablet = await getPersonalizedFeatures(
        userId: userId,
        deviceType: 'tablet',
      );

      return {
        'user_id': userId,
        'exported_at': DateTime.now().toIso8601String(),
        'mobile_features': mobile.map((f) => f['id']).toList(),
        'tablet_features': tablet.map((f) => f['id']).toList(),
        'stats': stats,
      };
    } catch (e) {
      print('❌ Error exporting settings: $e');
      rethrow;
    }
  }

  /// Import personalization settings
  Future<void> importPersonalizationSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      if (settings['mobile_features'] != null) {
        await service.savePersonalizedFeatures(
          userId: userId,
          deviceType: 'mobile',
          selectedFeatureIds:
              List<String>.from(settings['mobile_features'] as List),
        );
      }

      if (settings['tablet_features'] != null) {
        await service.savePersonalizedFeatures(
          userId: userId,
          deviceType: 'tablet',
          selectedFeatureIds:
              List<String>.from(settings['tablet_features'] as List),
        );
      }

      clearCache(userId);
      print('✅ Feature settings imported');
    } catch (e) {
      print('❌ Error importing settings: $e');
      rethrow;
    }
  }
}
