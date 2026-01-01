# Feature Personalization Implementation Examples

## Quick Start

### 1. Add Route to Main App

In `lib/main.dart`:

```dart
'/feature-personalization': (context) => const FeaturePersonalizationPage(),
```

### 2. Initialize on User Signup

```dart
// In your signup/authentication service
Future<void> onUserSignupComplete(String userId) async {
  final helper = FeaturePersonalizationHelper();
  await helper.initializeForNewUser(userId);
}
```

### 3. Add to Settings Page

```dart
// In lib/settings_page.dart or similar
ListTile(
  leading: const Icon(Icons.tune),
  title: const Text('Customize Features'),
  subtitle: const Text('Choose which features to display'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.pushNamed(context, '/feature-personalization'),
)
```

---

## Implementation Examples

### Example 1: Dynamic Navigation Based on Features

```dart
import 'package:flutter/material.dart';
import 'services/feature_personalization_helper.dart';

class DynamicNavigationPage extends StatefulWidget {
  const DynamicNavigationPage({Key? key}) : super(key: key);

  @override
  State<DynamicNavigationPage> createState() => _DynamicNavigationPageState();
}

class _DynamicNavigationPageState extends State<DynamicNavigationPage> {
  final helper = FeaturePersonalizationHelper();
  int selectedIndex = 0;
  List<Map<String, dynamic>> visibleFeatures = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }

  Future<void> _loadFeatures() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final deviceType = helper.getDeviceType(context);

      final features = await helper.getPersonalizedFeatures(
        userId: userId,
        deviceType: deviceType,
      );

      setState(() {
        visibleFeatures = features;
        loading = false;
      });
    } catch (e) {
      print('❌ Error loading features: $e');
      setState(() => loading = false);
    }
  }

  void _navigateToFeature(String featureId) {
    // Map feature IDs to routes
    final routeMap = {
      'dashboard': '/home',
      'jobs': '/jobs',
      'invoices': '/invoices',
      'clients': '/clients',
      'calendar': '/calendar',
      'team': '/team',
      'dispatch': '/dispatch',
      'inventory': '/inventory',
      'expenses': '/expenses',
      'reports': '/reports',
      'ai_agents': '/ai-agents',
      'marketing': '/marketing',
      'settings': '/settings',
    };

    final route = routeMap[featureId];
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Main content')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index < visibleFeatures.length) {
            setState(() => selectedIndex = index);
            _navigateToFeature(visibleFeatures[index]['id'] as String);
          }
        },
        destinations: visibleFeatures
            .map((feature) => NavigationDestination(
                  icon: Icon(
                    helper.getFeatureIcon(feature['id'] as String),
                  ),
                  label: feature['name'] as String,
                ))
            .toList(),
      ),
    );
  }
}
```

### Example 2: Conditional Feature Display

```dart
import 'package:flutter/material.dart';
import 'services/feature_personalization_helper.dart';

class ConditionalFeatureDisplay extends StatefulWidget {
  const ConditionalFeatureDisplay({Key? key}) : super(key: key);

  @override
  State<ConditionalFeatureDisplay> createState() =>
      _ConditionalFeatureDisplayState();
}

class _ConditionalFeatureDisplayState extends State<ConditionalFeatureDisplay> {
  final helper = FeaturePersonalizationHelper();

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final deviceType = helper.getDeviceType(context);

    return FutureBuilder<bool>(
      future: helper.isFeatureAvailable(
        userId: userId,
        deviceType: deviceType,
        featureId: 'ai_agents',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final isAvailable = snapshot.data ?? false;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Always show
              Card(
                child: ListTile(
                  title: const Text('Dashboard'),
                  onTap: () =>
                      Navigator.pushNamed(context, '/dashboard'),
                ),
              ),

              // Conditionally show AI Agents
              if (isAvailable)
                Card(
                  child: ListTile(
                    leading: Icon(
                      helper.getFeatureIcon('ai_agents'),
                    ),
                    title: const Text('AI Agents'),
                    subtitle: Text(
                      helper.getFeatureDescription('ai_agents'),
                    ),
                    onTap: () =>
                        Navigator.pushNamed(context, '/ai-agents'),
                  ),
                ),

              // Conditionally show other features
              if (isAvailable)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      // Show AI-specific features
                    },
                    child: const Text('Launch AI Assistants'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
```

### Example 3: Feature Limit Enforcement

```dart
import 'package:flutter/material.dart';
import 'services/feature_personalization_service.dart';

class FeatureLimitExample extends StatefulWidget {
  const FeatureLimitExample({Key? key}) : super(key: key);

  @override
  State<FeatureLimitExample> createState() => _FeatureLimitExampleState();
}

class _FeatureLimitExampleState extends State<FeatureLimitExample> {
  final service = FeaturePersonalizationService();
  List<String> selectedFeatures = [];
  String selectedDevice = 'mobile';

  Future<void> _addFeature(String featureId) async {
    final limit = FeaturePersonalizationService.getFeatureLimitForDevice(
      selectedDevice,
    );

    if (selectedFeatures.length >= limit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Maximum $limit features allowed on $selectedDevice',
          ),
        ),
      );
      return;
    }

    setState(() => selectedFeatures.add(featureId));

    // Show remaining slots
    final remaining = limit - selectedFeatures.length;
    print('📊 $remaining slots remaining');
  }

  @override
  Widget build(BuildContext context) {
    final limit =
        FeaturePersonalizationService.getFeatureLimitForDevice(selectedDevice);
    final remaining = limit - selectedFeatures.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Selection'),
      ),
      body: Column(
        children: [
          // Device selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mobile', label: Text('Mobile')),
                ButtonSegment(value: 'tablet', label: Text('Tablet')),
              ],
              selected: {selectedDevice},
              onSelectionChanged: (newSelection) {
                setState(() {
                  selectedDevice = newSelection.first;
                  selectedFeatures.clear();
                });
              },
            ),
          ),

          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected: ${selectedFeatures.length}/$limit',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: selectedFeatures.length / limit,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        selectedFeatures.length == limit
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status message
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: remaining > 0 ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                remaining > 0
                    ? '✅ $remaining slots available'
                    : '⚠️ Limit reached! Remove features to add more',
                style: TextStyle(
                  color:
                      remaining > 0 ? Colors.blue.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          ),

          // Features grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: FeaturePersonalizationService.ALL_FEATURES.length,
              itemBuilder: (context, index) {
                final feature =
                    FeaturePersonalizationService.ALL_FEATURES[index];
                final isSelected = selectedFeatures
                    .contains(feature['id'] as String);

                return GestureDetector(
                  onTap: isSelected
                      ? () => setState(() => selectedFeatures
                          .remove(feature['id']))
                      : () => _addFeature(feature['id'] as String),
                  child: Card(
                    color: isSelected ? Colors.blue.shade100 : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help,
                          size: 32,
                          color: isSelected ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Example 4: Feature Analytics

```dart
import 'package:flutter/material.dart';
import 'services/feature_personalization_service.dart';

class FeatureAnalyticsPage extends StatefulWidget {
  const FeatureAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<FeatureAnalyticsPage> createState() => _FeatureAnalyticsPageState();
}

class _FeatureAnalyticsPageState extends State<FeatureAnalyticsPage> {
  final service = FeaturePersonalizationService();
  Map<String, dynamic> stats = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

      final newStats =
          await service.getPersonalizationStats(userId: userId);

      setState(() {
        stats = newStats;
        loading = false;
      });
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Feature Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mobile stats
            _buildStatsCard(
              title: 'Mobile Features',
              selected: stats['mobile_features_selected'] ?? 0,
              max: stats['mobile_features_max'] ?? 8,
              remaining: stats['mobile_features_available_slots'] ?? 8,
            ),
            const SizedBox(height: 16),

            // Tablet stats
            _buildStatsCard(
              title: 'Tablet Features',
              selected: stats['tablet_features_selected'] ?? 0,
              max: stats['tablet_features_max'] ?? 12,
              remaining: stats['tablet_features_available_slots'] ?? 12,
            ),
            const SizedBox(height: 16),

            // Overall stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Available Features:'),
                        Text(
                          '${stats['total_available_features'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required int selected,
    required int max,
    required int remaining,
  }) {
    final percentage = (selected / max * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: selected / max,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                selected == max ? Colors.orange : Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selected: $selected/$max'),
                Text('$percentage% used'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining: $remaining slots',
              style: TextStyle(
                color: remaining > 0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Example 5: Cross-Device Synchronization

```dart
import 'package:flutter/material.dart';
import 'services/feature_personalization_service.dart';

class CrossDeviceSyncExample extends StatefulWidget {
  const CrossDeviceSyncExample({Key? key}) : super(key: key);

  @override
  State<CrossDeviceSyncExample> createState() =>
      _CrossDeviceSyncExampleState();
}

class _CrossDeviceSyncExampleState extends State<CrossDeviceSyncExample> {
  final service = FeaturePersonalizationService();

  Future<void> _syncMobileToTablet() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

      // Get mobile features
      final mobileFeatures = await service.getPersonalizedFeatures(
        userId: userId,
        deviceType: 'mobile',
      );

      final mobileIds =
          mobileFeatures.map((f) => f['id'] as String).toList();

      // Apply to tablet (respecting tablet limit)
      final tabletLimit =
          FeaturePersonalizationService.TABLET_MAX_FEATURES;
      final adjustedIds = mobileIds.take(tabletLimit).toList();

      await service.savePersonalizedFeatures(
        userId: userId,
        deviceType: 'tablet',
        selectedFeatureIds: adjustedIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Synced mobile to tablet')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  Future<void> _syncTabletToMobile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';

      // Get tablet features
      final tabletFeatures = await service.getPersonalizedFeatures(
        userId: userId,
        deviceType: 'tablet',
      );

      final tabletIds =
          tabletFeatures.map((f) => f['id'] as String).toList();

      // Apply to mobile (respecting mobile limit)
      final mobileLimit =
          FeaturePersonalizationService.MOBILE_MAX_FEATURES;
      final adjustedIds = tabletIds.take(mobileLimit).toList();

      await service.savePersonalizedFeatures(
        userId: userId,
        deviceType: 'mobile',
        selectedFeatureIds: adjustedIds,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Synced tablet to mobile')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cross-Device Sync')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _syncMobileToTablet,
              icon: const Icon(Icons.phone_android),
              label: const Text('Copy Mobile → Tablet'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _syncTabletToMobile,
              icon: const Icon(Icons.tablet),
              label: const Text('Copy Tablet → Mobile'),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Features Across Devices',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Copying adjusts to fit the target device limit\n'
                      '• Excess features are automatically trimmed\n'
                      '• Original device settings remain unchanged',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Testing Examples

```dart
// Unit test example
void main() {
  group('FeaturePersonalizationService', () {
    late FeaturePersonalizationService service;

    setUp(() {
      service = FeaturePersonalizationService();
    });

    test('Mobile limit is 8 features', () {
      expect(FeaturePersonalizationService.MOBILE_MAX_FEATURES, 8);
    });

    test('Tablet limit is 12 features', () {
      expect(FeaturePersonalizationService.TABLET_MAX_FEATURES, 12);
    });

    test('Default features for mobile', () {
      final defaults = service.getDefaultFeaturesForDevice('mobile');
      expect(defaults.length, lessThanOrEqualTo(8));
    });

    test('Get all available features', () {
      final features = service.getAllAvailableFeatures();
      expect(features.length, greaterThan(0));
    });

    test('Get features by category', () {
      final coreFeatures = service.getFeaturesByCategory('core');
      expect(coreFeatures.isNotEmpty, true);
    });
  });
}
```

---

## State Management Integration

If using Provider:

```dart
class FeaturePersonalizationProvider extends ChangeNotifier {
  final service = FeaturePersonalizationService();
  List<Map<String, dynamic>> _features = [];

  List<Map<String, dynamic>> get features => _features;

  Future<void> loadFeatures(String userId, String deviceType) async {
    _features = await service.getPersonalizedFeatures(
      userId: userId,
      deviceType: deviceType,
    );
    notifyListeners();
  }

  Future<void> toggleFeature(
    String userId,
    String deviceType,
    String featureId,
  ) async {
    await service.toggleFeature(
      userId: userId,
      deviceType: deviceType,
      featureId: featureId,
    );
    await loadFeatures(userId, deviceType);
  }
}
```

Usage in widget:

```dart
Consumer<FeaturePersonalizationProvider>(
  builder: (context, provider, _) {
    return ListView(
      children: provider.features.map((feature) {
        return ListTile(
          title: Text(feature['name']),
        );
      }).toList(),
    );
  },
)
```
