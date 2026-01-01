# Feature Personalization - Technical Architecture

## System Overview

The Feature Personalization System enables users to customize which features appear on their mobile and tablet interfaces, with device-specific limits:

```
┌─────────────────────────────────────────────────────┐
│            Feature Personalization System           │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │           UI Layer                            │ │
│  │  (feature_personalization_page.dart)          │ │
│  │  - Device type selector                       │ │
│  │  - Feature selection/reordering               │ │
│  │  - Progress tracking                          │ │
│  └───────────────────────────────────────────────┘ │
│                      ↓                              │
│  ┌───────────────────────────────────────────────┐ │
│  │      Service Layer                            │ │
│  │  (feature_personalization_service.dart)       │ │
│  │  - CRUD operations                            │ │
│  │  - Validation & constraints                   │ │
│  │  - Feature metadata                           │ │
│  │  - Statistics & analytics                     │ │
│  └───────────────────────────────────────────────┘ │
│                      ↓                              │
│  ┌───────────────────────────────────────────────┐ │
│  │      Helper Layer                             │ │
│  │  (feature_personalization_helper.dart)        │ │
│  │  - Caching                                    │ │
│  │  - Navigation building                        │ │
│  │  - Cross-device sync                          │ │
│  └───────────────────────────────────────────────┘ │
│                      ↓                              │
│  ┌───────────────────────────────────────────────┐ │
│  │      Data Access Layer                        │ │
│  │  (Supabase)                                   │ │
│  │  - Persistent storage                         │ │
│  │  - Authentication & RLS                       │ │
│  │  - Real-time subscriptions                    │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Component Architecture

### 1. FeaturePersonalizationService (Singleton)

**Responsibility**: Core business logic

```
FeaturePersonalizationService
├── Static Data
│   ├── MOBILE_MAX_FEATURES = 8
│   ├── TABLET_MAX_FEATURES = 12
│   └── ALL_FEATURES (13 features with metadata)
├── Public Methods
│   ├── getPersonalizedFeatures()      // Get user selections
│   ├── savePersonalizedFeatures()     // Save selections
│   ├── toggleFeature()                // Toggle one feature
│   ├── addFeature()                   // Add specific feature
│   ├── removeFeature()                // Remove specific feature
│   ├── reorderFeatures()              // Change feature order
│   ├── resetToDefaults()              // Reset to defaults
│   ├── getDefaultFeaturesForDevice()  // Get default set
│   ├── getAllAvailableFeatures()      // Get all features
│   ├── getFeaturesByCategory()        // Filter by category
│   ├── getAllCategories()             // Get unique categories
│   └── getPersonalizationStats()      // Get usage stats
└── Private Methods
    └── _internal()                     // Singleton pattern
```

**Key Features**:
- Singleton pattern (one instance per app)
- Direct Supabase client access
- Logger integration (via `package:logger`)
- Error handling with detailed logging
- Comprehensive CRUD operations

### 2. FeaturePersonalizationPage (Stateful Widget)

**Responsibility**: User interface for feature customization

```
FeaturePersonalizationPage
├── State: _FeaturePersonalizationPageState
│   ├── TabController for device switching
│   ├── Feature lists (mobile & tablet)
│   ├── Available features (mobile & tablet)
│   ├── Statistics tracking
│   └── Loading state
├── UI Sections
│   ├── AppBar with tab navigation
│   ├── Device feature selector
│   │   ├── Selected features (with remove buttons)
│   │   ├── Available features (clickable grid)
│   │   └── Feature counter/progress
│   ├── Category-based feature organization
│   ├── Action buttons
│   │   ├── Reset to Defaults
│   │   ├── Copy to Other Device
│   │   └── Save Changes
│   └── Info card with limits
└── Methods
    ├── _loadFeatures()        // Fetch from service
    ├── _toggleFeature()       // Toggle feature
    ├── _resetToDefaults()     // Reset defaults
    └── _duplicateFeatures()   // Copy to other device
```

**Responsive Behavior**:
- Mobile (<600px): Single column, compact layout
- Tablet (600-1200px): Two column, comfortable spacing
- Desktop (>1200px): Three column, full features

### 3. FeaturePersonalizationHelper (Singleton)

**Responsibility**: Helper utilities and optimizations

```
FeaturePersonalizationHelper
├── Caching Layer
│   ├── _featureCache          // Feature data cache
│   ├── _featureAvailabilityCache
│   └── clearCache()           // Cache invalidation
├── Navigation Building
│   ├── buildNavigationDestinations()
│   ├── buildFeatureGrid()
│   └── getDeviceType()        // Detect from context
├── Feature Metadata
│   ├── getFeatureName()
│   ├── getFeatureDescription()
│   ├── getFeatureIcon()
│   └── getFeatureMetadata()
├── User Operations
│   ├── getPersonalizedFeatures()   (with caching)
│   ├── isFeatureAvailable()        (cached)
│   ├── initializeForNewUser()
│   └── getRemainingSlots()
├── Import/Export
│   ├── exportPersonalizationSettings()
│   └── importPersonalizationSettings()
└── UI Helpers
    ├── buildFeatureInfoCard()
    ├── showFeatureCustomizationDialog()
    └── getRecommendedFeatures()
```

**Caching Strategy**:
- In-memory Map for active session
- Key format: `userId:deviceType:featureId`
- Manual invalidation after changes
- No disk persistence (lightweight)

## Data Flow

### Feature Selection Flow

```
User Interface
    ↓
Feature Selection Action
    ↓
FeaturePersonalizationPage._toggleFeature()
    ↓
FeaturePersonalizationService.toggleFeature()
    ├── Check feature exists ✓
    ├── Check device limit ✓
    ├── Toggle in local list ✓
    └── Save to Supabase ✓
    ↓
Supabase RLS Validation
    ├── Verify user authenticated ✓
    ├── Verify user_id matches ✓
    └── Write to feature_personalization ✓
    ↓
Update trigger
    ├── Set updated_at timestamp
    └── Commit transaction
    ↓
UI State Update
    ├── Clear cache
    ├── Refresh display
    └── Show confirmation
    ↓
User Feedback (SnackBar)
```

### Feature Loading Flow

```
App Launch / Page Navigation
    ↓
FeaturePersonalizationPage.initState()
    ↓
Get current user from auth
    ├── Get user ID
    └── Detect device type (screen width)
    ↓
FeaturePersonalizationHelper.getPersonalizedFeatures()
    ├── Check cache → Return if hit
    └── Query Supabase if miss:
        ├── SELECT from feature_personalization
        ├── WHERE user_id = ? AND device_type = ?
        └── Handle if NULL → Return defaults
    ↓
Supabase RLS
    ├── Verify user authenticated
    ├── Check auth.uid() = user_id
    └── Return data if authorized
    ↓
Cache result in _featureCache
    ↓
Update UI with features
    ├── Build navigation
    ├── Display selected features
    └── Show available features
```

## Database Schema

### feature_personalization Table

```sql
CREATE TABLE feature_personalization (
  id BIGSERIAL PRIMARY KEY,
  
  -- Foreign Keys
  user_id UUID NOT NULL REFERENCES auth.users(id),
  
  -- Feature Configuration
  device_type TEXT NOT NULL CHECK (device_type IN ('mobile', 'tablet')),
  selected_features TEXT[] NOT NULL DEFAULT '{}',
  feature_details JSONB,  -- Full feature metadata
  
  -- Lifecycle
  archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Constraints
  UNIQUE(user_id, device_type),
  UNIQUE(user_id, device_type, archived=false)
);
```

### Indexes

```sql
-- Fast user lookups
idx_feature_personalization_user_id
  ON feature_personalization(user_id)

-- Device type filtering  
idx_feature_personalization_device_type
  ON feature_personalization(device_type)

-- Combined lookups (most common query)
idx_feature_personalization_user_device
  ON feature_personalization(user_id, device_type)

-- Active records only
idx_feature_personalization_archived
  ON feature_personalization(archived)
  WHERE archived = FALSE
```

### RLS Policies

```sql
-- SELECT: Users see only their own
ON feature_personalization
FOR SELECT
USING (auth.uid() = user_id)

-- INSERT: Users create only their own
ON feature_personalization  
FOR INSERT
WITH CHECK (auth.uid() = user_id)

-- UPDATE: Users modify only their own
ON feature_personalization
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id)

-- DELETE: Users delete only their own
ON feature_personalization
FOR DELETE
USING (auth.uid() = user_id)
```

## Feature Constants

### Available Features (13 Total)

| ID | Name | Category | Priority | Icon |
|-----|------|----------|----------|------|
| dashboard | Dashboard | core | 1 | 📊 |
| jobs | Jobs | core | 2 | 💼 |
| invoices | Invoices | billing | 3 | 📋 |
| clients | Clients | core | 4 | 👥 |
| calendar | Calendar | scheduling | 5 | 📅 |
| team | Team | management | 6 | 👨‍💼 |
| dispatch | Dispatch | operations | 7 | 📍 |
| inventory | Inventory | operations | 8 | 📦 |
| expenses | Expenses | accounting | 9 | 💰 |
| reports | Reports | insights | 10 | 📈 |
| ai_agents | AI Agents | ai | 11 | 🤖 |
| marketing | Marketing | marketing | 12 | 📧 |
| settings | Settings | admin | 13 | ⚙️ |

### Device Limits

```
Mobile (< 600px):    Max 8 features
Tablet (600-1200px): Max 12 features  
Desktop (>1200px):   No limit (all features)
```

### Default Selections

**Mobile (8 features)**:
- dashboard, jobs, invoices, clients, calendar, team, dispatch, inventory

**Tablet (12 features)**:
- All mobile features + expenses, reports, ai_agents, marketing

**Desktop**: All 13 features

## State Management

### Local State (FeaturePersonalizationPage)

```dart
// Tab state
TabController _tabController

// Feature selections
List<String> _mobileFeatures
List<String> _tabletFeatures

// Available features
List<String> _availableMobileFeatures
List<String> _availableTabletFeatures

// UI state
bool _loading
Map<String, dynamic> _stats
```

### Cache State (FeaturePersonalizationHelper)

```dart
// In-memory cache
Map<String, List<Map<String, dynamic>>> _featureCache
Map<String, bool> _featureAvailabilityCache

// Key format: "userId:deviceType[:featureId]"
// Cleared manually after saves
```

### Persistent State (Supabase)

```dart
// feature_personalization table
{
  user_id,
  device_type,
  selected_features: ['feature1', 'feature2', ...],
  feature_details: {...},
  updated_at
}
```

## Error Handling Strategy

### Service Layer

```dart
try {
  // Query Supabase
  final result = await supabase.from(...).select(...);
} catch (e) {
  // Log with context
  _logger.e('❌ Error: $e');
  
  // Return sensible default
  return defaultFeaturesForDevice(deviceType);
  
  // Optionally rethrow for UI handling
}
```

### UI Layer

```dart
try {
  await _featureService.toggleFeature(...);
  
  // Reload data
  await _loadFeatures();
  
  // Show success
  _showSnackBar('✅ Feature updated');
} catch (e) {
  // Log error
  print('❌ Error: $e');
  
  // Show to user
  _showErrorDialog(e.toString());
  
  // Attempt recovery (reload)
  await _loadFeatures();
}
```

### Error Types

1. **Authentication**: User not logged in → redirect to login
2. **Validation**: Invalid feature ID → reject silently
3. **Limits**: Max features exceeded → show warning
4. **Database**: Query failed → use defaults + log
5. **Network**: Connection lost → use cached data

## Performance Considerations

### Caching Strategy

```
Query 1: ⏱️ 50ms (database + network)
        ↓ cache result
Query 2: ⏱️ <1ms (from cache)
```

**Cache Invalidation**:
- Automatic after saves
- Selective per user/device
- Full clear on logout

### Query Optimization

```sql
-- Good: Uses index on (user_id, device_type)
SELECT selected_features FROM feature_personalization
WHERE user_id = ? AND device_type = ?

-- Bad: Full table scan
SELECT * FROM feature_personalization
WHERE selected_features @> '["jobs"]'
```

### Memory Management

- ~5KB per user preference set
- ~200 bytes per cached feature
- Total memory: < 5MB even with 1000+ cached features

## Security Model

### Authentication

- Must be logged in to access personalization
- `auth.currentUser?.id` verified at service level
- Supabase auth handles session management

### Authorization (RLS)

```sql
-- User can only see their own preferences
WHERE auth.uid() = user_id
```

### Data Validation

1. **Feature ID validation**: Must be in `ALL_FEATURES`
2. **Device type validation**: Must be 'mobile' or 'tablet'
3. **Array length validation**: ≤ device limit
4. **Constraint validation**: Unique per user/device

### Input Sanitization

- All inputs are strings (no SQL injection risk)
- Array length checked before save
- Unknown feature IDs rejected

## Testing Strategy

### Unit Tests

```dart
testWidgets('Feature limit enforced', (tester) async {
  // Mock 8 features selected
  // Try to add 9th feature
  // Expect failure/warning
});

testWidgets('Device type detection', (tester) async {
  // Render at 400px width
  // Expect 'mobile'
  // Resize to 700px
  // Expect 'tablet'
});
```

### Integration Tests

```dart
testWidgets('Full workflow', (tester) async {
  // 1. Load customization page
  // 2. Toggle features
  // 3. Save
  // 4. Verify in database
  // 5. Log out and in
  // 6. Verify persistence
});
```

### Performance Tests

```dart
testWidgets('Load time < 500ms', (tester) async {
  final stopwatch = Stopwatch()..start();
  
  await tester.pumpWidget(const FeaturePersonalizationPage());
  
  expect(stopwatch.elapsed, lessThan(Duration(milliseconds: 500)));
});
```

## Deployment Checklist

- [ ] Run database migration
- [ ] Verify RLS policies enabled
- [ ] Add route to main.dart
- [ ] Update home_page.dart
- [ ] Test on physical devices
- [ ] Load test (100+ concurrent users)
- [ ] Monitor error rates
- [ ] Check Supabase logs

## Future Enhancements

1. **Real-time Sync**: WebSocket updates to other devices
2. **Analytics**: Track feature selection patterns
3. **A/B Testing**: Test different defaults
4. **Recommendations**: ML-based feature suggestions
5. **Templates**: Team/organization level presets
6. **Versioning**: Feature set versions with migrations
7. **Audit Log**: Track all personalization changes
8. **Bulk Operations**: Team-wide feature management

---

## Summary

The Feature Personalization System provides:

✅ **Device-aware limits** (8 mobile, 12 tablet)
✅ **User-driven customization** via intuitive UI
✅ **Persistent storage** with Supabase
✅ **Performance optimization** via caching
✅ **Security** via RLS policies
✅ **Extensibility** for future enhancements

Designed for maximum flexibility while maintaining security, performance, and user experience.
