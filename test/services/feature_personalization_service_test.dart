import 'package:flutter_test/flutter_test.dart';
import 'package:aura_crm/services/feature_personalization_service.dart';

void main() {
  late FeaturePersonalizationService service;

  setUpAll(() {
    service = FeaturePersonalizationService();
  });

  group('Feature Personalization Service - Core Methods', () {
    
    test('getDefaultFeaturesForDevice - Mobile returns 6 features', () {
      final features = service.getDefaultFeaturesForDevice('mobile');
      expect(features.length, 6);
      expect(features, containsAll(['dashboard', 'jobs', 'invoices']));
    });

    test('getDefaultFeaturesForDevice - Tablet returns 8 features', () {
      final features = service.getDefaultFeaturesForDevice('tablet');
      expect(features.length, 8);
      expect(features, containsAll(['dashboard', 'jobs', 'team']));
    });

    test('getAllAvailableFeatures - Returns all features', () {
      final features = service.getAllAvailableFeatures();
      expect(features.length, greaterThanOrEqualTo(13));
      expect(features.any((f) => f['id'] == 'ai_agents'), true);
    });

    test('getFeaturesByCategory - Returns features by category', () {
      final coreFeatures = service.getFeaturesByCategory('core');
      expect(coreFeatures.isNotEmpty, true);
      expect(coreFeatures.every((f) => f['category'] == 'core'), true);
    });

    test('getAllCategories - Returns unique categories', () {
      final categories = service.getAllCategories();
      expect(categories.isNotEmpty, true);
      expect(categories, containsAll(['core', 'billing', 'ai', 'management']));
    });
  });

  group('Device Limits by Plan - Configuration', () {
    
    test('SOLO plan - 2 mobile, 1 tablet', () {
      final limits = FeaturePersonalizationService.deviceLimitsByPlan['solo']!;
      expect(limits['mobile_devices'], 2);
      expect(limits['tablet_devices'], 1);
    });

    test('TEAM plan - 3 mobile, 2 tablet', () {
      final limits = FeaturePersonalizationService.deviceLimitsByPlan['team']!;
      expect(limits['mobile_devices'], 3);
      expect(limits['tablet_devices'], 2);
    });

    test('WORKSHOP plan - 5 mobile, 3 tablet', () {
      final limits = FeaturePersonalizationService.deviceLimitsByPlan['workshop']!;
      expect(limits['mobile_devices'], 5);
      expect(limits['tablet_devices'], 3);
    });

    test('ENTERPRISE plan - 10 mobile, 5 tablet', () {
      final limits = FeaturePersonalizationService.deviceLimitsByPlan['enterprise']!;
      expect(limits['mobile_devices'], 10);
      expect(limits['tablet_devices'], 5);
    });
  });

  group('Feature Limits per Device Type', () {
    
    test('Mobile max features is 6', () {
      expect(FeaturePersonalizationService.mobileMaxFeatures, 6);
    });

    test('Tablet max features is 8', () {
      expect(FeaturePersonalizationService.tabletMaxFeatures, 8);
    });
  });

  group('Default Features Configuration', () {
    
    test('Default mobile features list is defined', () {
      expect(FeaturePersonalizationService.defaultMobileFeatures.isNotEmpty, true);
      expect(FeaturePersonalizationService.defaultMobileFeatures.length, 6);
    });

    test('Default tablet features list is defined', () {
      expect(FeaturePersonalizationService.defaultTabletFeatures.isNotEmpty, true);
      expect(FeaturePersonalizationService.defaultTabletFeatures.length, 8);
    });

    test('Default features are in available features', () {
      final availableIds = FeaturePersonalizationService.allFeatures
          .map((f) => f['id'])
          .toSet();
      
      for (var id in FeaturePersonalizationService.defaultMobileFeatures) {
        expect(availableIds.contains(id), true, reason: 'Feature $id not found in all features');
      }
    });
  });

  group('Owner Control Methods - Configuration Validation', () {
    
    test('forceEnableAllFeaturesOnDevice method exists', () {
      expect(service.forceEnableAllFeaturesOnDevice, isNotNull);
    });

    test('disableFeaturesOnDevice method exists', () {
      expect(service.disableFeaturesOnDevice, isNotNull);
    });

    test('lockFeaturesOrgWide method exists', () {
      expect(service.lockFeaturesOrgWide, isNotNull);
    });

    test('unlockFeaturesOrgWide method exists', () {
      expect(service.unlockFeaturesOrgWide, isNotNull);
    });

    test('getFeatureAuditLog method exists', () {
      expect(service.getFeatureAuditLog, isNotNull);
    });

    test('getOwnerControlStatus method exists', () {
      expect(service.getOwnerControlStatus, isNotNull);
    });

    test('resetAllTeamFeaturestoDefaults method exists', () {
      expect(service.resetAllTeamFeaturestoDefaults, isNotNull);
    });

    test('registerDevice method exists', () {
      expect(service.registerDevice, isNotNull);
    });

    test('canAddDevice method exists', () {
      expect(service.canAddDevice, isNotNull);
    });

    test('getDeviceLimits method exists', () {
      expect(service.getDeviceLimits, isNotNull);
    });

    test('getDeviceUsage method exists', () {
      expect(service.getDeviceUsage, isNotNull);
    });

    test('getDeviceLimitSummary method exists', () {
      expect(service.getDeviceLimitSummary, isNotNull);
    });

    test('getTeamDeviceControlPanel method exists', () {
      expect(service.getTeamDeviceControlPanel, isNotNull);
    });
  });

  group('Singleton Pattern', () {
    
    test('Service returns same instance', () {
      final service1 = FeaturePersonalizationService();
      final service2 = FeaturePersonalizationService();
      expect(identical(service1, service2), true);
    });
  });

  group('Feature Data Integrity', () {
    
    test('All features have required fields', () {
      for (var feature in FeaturePersonalizationService.allFeatures) {
        expect(feature.containsKey('id'), true);
        expect(feature.containsKey('name'), true);
        expect(feature.containsKey('icon'), true);
        expect(feature.containsKey('category'), true);
        expect(feature.containsKey('priority'), true);
      }
    });

    test('All feature IDs are unique', () {
      final ids = FeaturePersonalizationService.allFeatures
          .map((f) => f['id'])
          .toList();
      expect(ids.length, ids.toSet().length);
    });

    test('All feature priorities are unique and ordered', () {
      final priorities = FeaturePersonalizationService.allFeatures
          .map((f) => f['priority'])
          .toList();
      expect(priorities.length, priorities.toSet().length);
      expect(priorities.isSorted, true);
    });
  });
}

extension on List<num> {
  bool get isSorted {
    for (int i = 0; i < length - 1; i++) {
      if (this[i].compareTo(this[i + 1]) > 0) return false;
    }
    return true;
  }
}
