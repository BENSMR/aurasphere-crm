# Feature Personalization Guide

## Overview

The **Feature Personalization System** allows users to customize which features appear on their mobile and tablet interfaces. This creates a personalized experience based on device type and user workflow preferences.

### Key Constraints

- **Mobile**: Maximum 8 features can be selected
- **Tablet**: Maximum 12 features can be selected
- **Desktop**: Uses all available features (no limit)

## Available Features

The system includes 13 core features that can be personalized:

| Feature | ID | Category | Description |
|---------|-------|----------|-------------|
| Dashboard | `dashboard` | Core | Overview of all business metrics |
| Jobs | `jobs` | Core | Manage and track all jobs |
| Invoices | `invoices` | Billing | Create and manage invoices |
| Clients | `clients` | Core | Client management and history |
| Calendar | `calendar` | Scheduling | Job scheduling and calendar view |
| Team | `team` | Management | Manage team members and roles |
| Dispatch | `dispatch` | Operations | Dispatch jobs to team members |
| Inventory | `inventory` | Operations | Track materials and stock levels |
| Expenses | `expenses` | Accounting | Track business expenses |
| Reports | `reports` | Insights | Generate business reports |
| AI Agents | `ai_agents` | AI | CEO, COO, CFO autonomous agents |
| Marketing | `marketing` | Marketing | Email and SMS marketing automation |
| Settings | `settings` | Admin | Account and app settings |

## Architecture

### Services Layer

#### FeaturePersonalizationService

Located in `lib/services/feature_personalization_service.dart`

**Key Methods:**

```dart
// Retrieve user's personalized features for a device
Future<List<Map<String, dynamic>>> getPersonalizedFeatures({
  required String userId,
  required String deviceType, // 'mobile' or 'tablet'
})

// Save feature selections for a device
Future<Map<String, dynamic>> savePersonalizedFeatures({
  required String userId,
  required String deviceType,
  required List<String> selectedFeatureIds,
})

// Add a single feature
Future<void> addFeature({
  required String userId,
  required String deviceType,
  required String featureId,
})

// Remove a single feature
Future<void> removeFeature({
  required String userId,
  required String deviceType,
  required String featureId,
})

// Reorder features (change display priority)
Future<void> reorderFeatures({
  required String userId,
  required String deviceType,
  required List<String> orderedFeatureIds,
})

// Reset to default features
Future<void> resetToDefaults({
  required String userId,
  required String deviceType,
})

// Toggle feature visibility
Future<void> toggleFeature({
  required String userId,
  required String deviceType,
  required String featureId,
})

// Get personalization statistics
Future<Map<String, dynamic>> getPersonalizationStats({
  required String userId,
})

// Get all available features
List<Map<String, dynamic>> getAllAvailableFeatures()

// Get features by category
List<Map<String, dynamic>> getFeaturesByCategory(String category)

// Get all unique categories
List<String> getAllCategories()
```

### UI Layer

#### FeaturePersonalizationPage

Located in `lib/feature_personalization_page.dart`

**Features:**

- Device type selector (mobile/tablet tabs)
- Real-time feature selection with visual feedback
- Reorderable list for selected features (drag & drop)
- Available features displayed by category
- Progress indicator showing selected/max features
- One-click reset to defaults
- Feature counter with remaining slots
- Responsive design (mobile/tablet/desktop)

## Database Schema

### feature_personalization Table

```sql
CREATE TABLE feature_personalization (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL,              -- Reference to auth.users
  device_type TEXT NOT NULL,          -- 'mobile' or 'tablet'
  selected_features TEXT[],           -- Array of feature IDs
  feature_details JSONB,              -- Full feature metadata
  archived BOOLEAN DEFAULT FALSE,     -- Soft delete flag
  created_at TIMESTAMP,               -- Auto-set on creation
  updated_at TIMESTAMP,               -- Auto-updated
  UNIQUE(user_id, device_type)        -- One preference per device type
);
```

**Indexes:**
- `user_id` - Fast lookups by user
- `device_type` - Filter by device
- `user_id, device_type` - Composite for specific user/device
- `archived` - Quick access to active preferences

**RLS Policies:**
- Users can only view/modify their own preferences
- Automatic timestamp updates on changes
- Soft delete support via archived flag

## Usage Patterns

### 1. Display Features on Home Page

```dart
// Get personalized features for current device
final personalizationService = FeaturePersonalizationService();
final userId = supabase.auth.currentUser!.id;
final deviceType = MediaQuery.of(context).size.width < 600 ? 'mobile' : 'tablet';

final features = await personalizationService.getPersonalizedFeatures(
  userId: userId,
  deviceType: deviceType,
);

// Build navigation with only selected features
List<Widget> navItems = features
    .map((feature) => _buildNavItem(feature))
    .toList();
```

### 2. Initialize with Default Features

```dart
// Get default features for device on first login
final defaults = personalizationService.getDefaultFeaturesForDevice('mobile');
// Returns: ['dashboard', 'jobs', 'invoices', 'clients', 'calendar', 'team', 'dispatch', 'inventory']

// Tablet defaults include: all mobile + 'reports', 'ai_agents', 'marketing', 'settings'
```

### 3. Allow User Customization

```dart
// Navigate to customization page
Navigator.pushNamed(context, '/feature-personalization');

// Or programmatically toggle a feature
await personalizationService.toggleFeature(
  userId: userId,
  deviceType: 'mobile',
  featureId: 'inventory',
);
```

### 4. Check Feature Availability

```dart
// Check if a feature is enabled for user
final features = await personalizationService.getPersonalizedFeatures(
  userId: userId,
  deviceType: deviceType,
);

final featureIds = features.map((f) => f['id']).toSet();

if (featureIds.contains('ai_agents')) {
  // Show AI agents feature
  showAIAgentsSection();
}
```

### 5. Get User Statistics

```dart
// Get personalization stats for analytics
final stats = await personalizationService.getPersonalizationStats(
  userId: userId,
);

print('Mobile features: ${stats['mobile_features_selected']}/${stats['mobile_features_max']}');
print('Tablet features: ${stats['tablet_features_selected']}/${stats['tablet_features_max']}');
```

## Integration Points

### 1. Home Page Navigation

Update `lib/home_page.dart` to load personalized features:

```dart
class _HomePageState extends State<HomePage> {
  final personalizationService = FeaturePersonalizationService();
  List<Map<String, dynamic>> visibleFeatures = [];

  @override
  void initState() {
    super.initState();
    _loadPersonalizedFeatures();
  }

  Future<void> _loadPersonalizedFeatures() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final deviceType = _getDeviceType();
    
    final features = await personalizationService.getPersonalizedFeatures(
      userId: userId!,
      deviceType: deviceType,
    );

    setState(() => visibleFeatures = features);
  }

  String _getDeviceType() {
    final width = MediaQuery.of(context).size.width;
    return width < 600 ? 'mobile' : 'tablet';
  }
}
```

### 2. Settings Page

Add "Customize Features" option to settings:

```dart
ListTile(
  title: const Text('Customize Features'),
  subtitle: const Text('Choose which features to display'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.pushNamed(context, '/feature-personalization');
  },
)
```

### 3. Routes Configuration

Add route in `lib/main.dart`:

```dart
'/feature-personalization': (context) => const FeaturePersonalizationPage(),
```

## Best Practices

### 1. Respect Device Limits
Always validate against device-specific limits before saving:

```dart
if (selectedIds.length > (deviceType == 'mobile' ? 8 : 12)) {
  showError('Too many features for this device');
  return;
}
```

### 2. Fallback to Defaults
Always provide sensible defaults if personalization fails:

```dart
try {
  features = await service.getPersonalizedFeatures(...);
} catch (e) {
  features = service.getDefaultFeaturesForDevice(deviceType);
}
```

### 3. Responsive Behavior
Check device type dynamically to handle orientation changes:

```dart
final deviceType = MediaQuery.of(context).size.width < 600 ? 'mobile' : 'tablet';
```

### 4. Cache Results
Minimize database calls by caching personalization data:

```dart
Map<String, List<Map<String, dynamic>>> _featureCache = {};

Future<List<Map<String, dynamic>>> getFeatures(String deviceType) async {
  return _featureCache.putIfAbsent(deviceType, () async {
    return await service.getPersonalizedFeatures(...);
  });
}
```

### 5. Real-time Sync
Consider using Supabase real-time subscriptions for cross-device sync:

```dart
supabase
  .from('feature_personalization')
  .on(RealtimeListenTypes.postgresChanges, 
     PostgresChangeFilter(
      event: '*',
      schema: 'public',
      table: 'feature_personalization',
    ))
  .eq('user_id', userId)
  .subscribe((payload) {
    // Reload features when personalization changes
    _loadPersonalizedFeatures();
  });
```

## Analytics & Monitoring

### Track Feature Usage

```dart
// Log which features users actually select
analytics.logEvent(
  'feature_selected',
  parameters: {
    'device_type': deviceType,
    'feature_id': featureId,
    'total_selected': selectedCount,
  },
);
```

### Monitor Personalization Stats

```dart
// Periodically check how users personalize
final stats = await service.getPersonalizationStats(userId: userId);

// Log for analytics
firestore
  .collection('personalization_analytics')
  .add(stats);
```

## Account Lifecycle

### On User Signup

Create default personalization records:

```dart
// Called after signup
await service.savePersonalizedFeatures(
  userId: newUserId,
  deviceType: 'mobile',
  selectedFeatureIds: service.getDefaultFeaturesForDevice('mobile'),
);

await service.savePersonalizedFeatures(
  userId: newUserId,
  deviceType: 'tablet',
  selectedFeatureIds: service.getDefaultFeaturesForDevice('tablet'),
);
```

### On Account Deletion

Archive personalization data:

```dart
// Before deleting user account
await service.archivePreferences();

// Then delete user via Supabase Auth
```

## Troubleshooting

### Features not saving

1. Check RLS policies are enabled on `feature_personalization` table
2. Verify user is authenticated (`auth.uid()` is set)
3. Check `selected_features` array contains valid feature IDs
4. Review Supabase logs for constraint violations

### Features always showing defaults

1. Check if personalization query is failing (wrap in try/catch)
2. Verify user_id is correctly retrieved from auth
3. Ensure device_type is exactly 'mobile' or 'tablet'
4. Check if table exists and is accessible

### Performance issues

1. Add indexes on `user_id` and `(user_id, device_type)`
2. Cache feature list in local state
3. Use `maybeSingle()` instead of `select()` to reduce data transfer
4. Consider pagination if feature list grows beyond 50 items

## Future Enhancements

- [ ] Sync features across devices
- [ ] Feature recommendations based on user behavior
- [ ] A/B testing different default configurations
- [ ] Team-wide feature templates
- [ ] Feature analytics dashboard
- [ ] Conditional feature availability (plan-based)
- [ ] Feature usage tracking and insights
