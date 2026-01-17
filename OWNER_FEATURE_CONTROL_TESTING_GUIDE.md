# 🧪 Owner Feature Control - Comprehensive Testing Guide
**Date**: January 17, 2026  
**Purpose**: Verify owner controls work correctly before production launch

---

## 📋 Testing Phases

### **Phase 1: Database Migration Verification** (5 min)
### **Phase 2: SQL-Level Testing** (10 min)
### **Phase 3: Service Method Testing** (15 min)
### **Phase 4: UI Integration Testing** (10 min)
### **Phase 5: Security & RLS Testing** (10 min)
### **Phase 6: Performance Testing** (5 min)

**Total Time**: ~55 minutes

---

## ✅ Phase 1: Database Migration Verification

### Step 1.1: Verify Migration Applied Successfully

```sql
-- Check if migration columns exist
SELECT 
  table_name, 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE 
  (table_name = 'organizations' OR 
   table_name = 'feature_personalization' OR 
   table_name = 'feature_audit_log')
  AND column_name IN (
    'feature_lock_enabled', 'locked_features', 'feature_lock_reason',
    'is_owner_enforced', 'enforced_by', 'enforced_at', 'disabled_features',
    'disabled_by_owner', 'disabled_by', 'disabled_at'
  )
ORDER BY table_name, ordinal_position;
```

**Expected Output**:
```
organizations:
  - feature_lock_enabled (BOOLEAN)
  - locked_features (JSONB)
  - feature_lock_reason (VARCHAR)
  - feature_lock_by (UUID)
  - feature_lock_at (TIMESTAMPTZ)
  - feature_unlock_at (TIMESTAMPTZ)

feature_personalization:
  - is_owner_enforced (BOOLEAN)
  - enforced_by (UUID)
  - enforced_at (TIMESTAMPTZ)
  - disabled_features (JSONB)
  - disabled_by_owner (BOOLEAN)
  - disabled_by (UUID)
  - disabled_at (TIMESTAMPTZ)

feature_audit_log:
  - id (UUID)
  - org_id (UUID)
  - action (VARCHAR)
  - performed_by (UUID)
  - target_user_id (UUID)
  - target_device_id (UUID)
  - details (TEXT)
  - timestamp (TIMESTAMPTZ)
  - created_at (TIMESTAMPTZ)
```

### Step 1.2: Verify Indexes Created

```sql
-- Check indexes on feature_audit_log
SELECT 
  schemaname, 
  tablename, 
  indexname 
FROM pg_indexes 
WHERE tablename = 'feature_audit_log'
ORDER BY indexname;
```

**Expected Output**:
```
idx_feature_audit_log_org_id
idx_feature_audit_log_created_at
idx_feature_audit_log_action
idx_feature_audit_log_performer
```

### Step 1.3: Verify RLS Policies

```sql
-- Check RLS policies on feature_audit_log
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  qual
FROM pg_policies
WHERE tablename = 'feature_audit_log'
ORDER BY policyname;
```

**Expected Output**:
```
audit_log_owner_view    (SELECT policy for owners)
audit_log_service_insert (INSERT policy for service role)
```

### Step 1.4: Verify Trigger

```sql
-- Check trigger is created
SELECT 
  trigger_schema,
  trigger_name,
  event_object_table,
  action_timing,
  event_manipulation
FROM information_schema.triggers
WHERE trigger_name = 'feature_personalization_audit_trigger';
```

**Expected Output**:
```
trigger_name: feature_personalization_audit_trigger
event_object_table: feature_personalization
action_timing: AFTER
event_manipulation: UPDATE
```

---

## ✅ Phase 2: SQL-Level Testing

### Step 2.1: Setup Test Data

```sql
-- Create test organization and users
INSERT INTO organizations (id, owner_id, name, plan)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Test Org - Owner Control',
  'team'
) ON CONFLICT DO NOTHING;

-- Create test team member
INSERT INTO org_members (org_id, user_id, role, email)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
  '00000000-0000-0000-0000-000000000002'::uuid,
  'member',
  'member@test.com'
) ON CONFLICT DO NOTHING;

-- Create test device
INSERT INTO devices (org_id, device_type, device_name, registered_by)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
  'mobile',
  'Test Device - Mobile',
  '00000000-0000-0000-0000-000000000002'
) ON CONFLICT DO NOTHING;
```

### Step 2.2: Test Owner Lock Feature Org-Wide

```sql
-- Owner locks features for compliance
UPDATE organizations
SET 
  feature_lock_enabled = true,
  locked_features = '["ai_agents", "marketing"]'::jsonb,
  feature_lock_reason = 'Compliance requirement: HIPAA',
  feature_lock_by = '00000000-0000-0000-0000-000000000001'::uuid,
  feature_lock_at = NOW()
WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;

-- Verify update
SELECT 
  feature_lock_enabled,
  locked_features,
  feature_lock_reason,
  feature_lock_by,
  feature_lock_at
FROM organizations
WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
```

**Expected**:
- feature_lock_enabled = true
- locked_features = ["ai_agents", "marketing"]
- feature_lock_reason = "Compliance requirement: HIPAA"

### Step 2.3: Test Owner Force Enable on Device

```sql
-- Owner forces all features on team member's device
UPDATE feature_personalization
SET 
  is_owner_enforced = true,
  enforced_by = '00000000-0000-0000-0000-000000000001'::uuid,
  enforced_at = NOW(),
  selected_features = '["dashboard", "jobs", "invoices", "clients", "calendar", "expenses"]'::jsonb
WHERE 
  user_id = '00000000-0000-0000-0000-000000000002'::uuid
  AND device_type = 'mobile';

-- Verify
SELECT 
  user_id,
  device_type,
  is_owner_enforced,
  enforced_by,
  selected_features
FROM feature_personalization
WHERE 
  user_id = '00000000-0000-0000-0000-000000000002'::uuid
  AND device_type = 'mobile';
```

**Expected**:
- is_owner_enforced = true
- enforced_by = owner UUID
- selected_features populated with 6 features

### Step 2.4: Test Trigger - Audit Log Auto-Logging

```sql
-- This should trigger the audit log
UPDATE feature_personalization
SET is_owner_enforced = true
WHERE 
  user_id = '00000000-0000-0000-0000-000000000002'::uuid
  AND device_type = 'mobile';

-- Check if trigger logged the change
SELECT 
  id,
  org_id,
  action,
  performed_by,
  target_user_id,
  details,
  created_at
FROM feature_audit_log
WHERE org_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid
ORDER BY created_at DESC
LIMIT 1;
```

**Expected**:
- Audit log entry created automatically
- action = 'feature_enforcement_enabled'
- created_at = recent timestamp

### Step 2.5: Test RLS - Owner Can View Audit Logs

```sql
-- Set JWT to owner user
-- Run as owner user
SELECT 
  id,
  org_id,
  action,
  performed_by,
  target_user_id,
  created_at
FROM feature_audit_log
WHERE org_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
```

**Expected**: ✅ Returns audit log rows (owner can view)

### Step 2.6: Test RLS - Non-Owner Cannot View Audit Logs

```sql
-- Set JWT to different org owner
-- Run as different org owner
SELECT 
  id,
  org_id,
  action
FROM feature_audit_log
WHERE org_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
```

**Expected**: ❌ Returns 0 rows (RLS blocks non-owners)

### Step 2.7: Test RLS - Service Role Can Insert Audit Logs

```sql
-- Run as service_role (backend only)
INSERT INTO feature_audit_log (
  org_id,
  action,
  performed_by,
  target_user_id,
  details
)
VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
  'manual_test_insert',
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000002'::uuid,
  'Test manual insert from service role'
);

-- Verify insert worked
SELECT COUNT(*) as audit_count
FROM feature_audit_log
WHERE org_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
```

**Expected**: ✅ INSERT succeeds, row count increases

---

## ✅ Phase 3: Service Method Testing

### Create Dart Test File

**Location**: `test/services/feature_personalization_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_crm/services/feature_personalization_service.dart';

void main() {
  late FeaturePersonalizationService service;
  late String testOrgId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  late String testOwnerId = '00000000-0000-0000-0000-000000000001';
  late String testUserId = '00000000-0000-0000-0000-000000000002';
  late String testDeviceId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  setUpAll(() {
    service = FeaturePersonalizationService();
  });

  group('Owner Feature Control Tests', () {
    
    test('forceEnableAllFeaturesOnDevice - Success', () async {
      final result = await service.forceEnableAllFeaturesOnDevice(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
        targetDeviceId: testDeviceId,
        targetUserId: testUserId,
      );

      expect(result['success'], true);
      expect(result['device_id'], testDeviceId);
      expect(result['features_enabled'], 6); // Mobile max 6
    });

    test('forceEnableAllFeaturesOnDevice - Non-owner fails', () async {
      final result = await service.forceEnableAllFeaturesOnDevice(
        orgId: testOrgId,
        ownerUserId: 'not-owner-id',
        targetDeviceId: testDeviceId,
        targetUserId: testUserId,
      );

      expect(result['error'], isNotNull);
      expect(result['status'], 'unauthorized');
    });

    test('disableFeaturesOnDevice - Success', () async {
      final result = await service.disableFeaturesOnDevice(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
        targetDeviceId: testDeviceId,
        targetUserId: testUserId,
        featuresToDisable: ['ai_agents', 'marketing'],
      );

      expect(result['success'], true);
      expect(result['features_disabled'], 2);
    });

    test('lockFeaturesOrgWide - Success', () async {
      final result = await service.lockFeaturesOrgWide(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
        lockedFeatureIds: ['ai_agents', 'marketing'],
        reason: 'Compliance: HIPAA',
      );

      expect(result['success'], true);
      expect(result['locked_features'], 2);
      expect(result['reason'], 'Compliance: HIPAA');
    });

    test('unlockFeaturesOrgWide - Success', () async {
      final result = await service.unlockFeaturesOrgWide(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
      );

      expect(result['success'], true);
      expect(result['message'], contains('unlocked'));
    });

    test('getFeatureAuditLog - Owner can view', () async {
      final logs = await service.getFeatureAuditLog(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
      );

      expect(logs, isA<List>());
      expect(logs.isNotEmpty, true); // Should have audit entries from tests above
    });

    test('getOwnerControlStatus - Shows enforcement status', () async {
      final status = await service.getOwnerControlStatus(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
      );

      expect(status['org_id'], testOrgId);
      expect(status['org_wide_lock_enabled'], isA<bool>());
      expect(status['devices_with_enforced_features'], isA<int>());
    });

    test('canAddDevice - Respects subscription limits', () async {
      // Solo plan allows 2 mobile devices
      final canAdd = await service.canAddDevice(
        orgId: testOrgId,
        deviceType: 'mobile',
      );

      expect(canAdd, isA<bool>());
    });

    test('registerDevice - Owner only', () async {
      final result = await service.registerDevice(
        orgId: testOrgId,
        userId: testOwnerId,
        deviceType: 'mobile',
        deviceName: 'Test Device',
      );

      expect(result['success'], true);
      expect(result['device'], isA<Map>());
    });

    test('resetAllTeamFeaturestoDefaults - Owner only', () async {
      final result = await service.resetAllTeamFeaturestoDefaults(
        orgId: testOrgId,
        ownerUserId: testOwnerId,
        reason: 'Policy change',
      );

      expect(result['success'], true);
      expect(result['members_reset'], isA<int>());
    });

  });

  group('Device Limit Tests', () {
    
    test('getDeviceLimits - Returns subscription tier limits', () async {
      final limits = await service.getDeviceLimits(orgId: testOrgId);

      expect(limits['mobile_devices'], isA<int>());
      expect(limits['tablet_devices'], isA<int>());
      expect(limits['mobile_devices'] > 0, true);
    });

    test('getDeviceUsage - Counts current devices', () async {
      final usage = await service.getDeviceUsage(orgId: testOrgId);

      expect(usage['mobile_devices'], isA<int>());
      expect(usage['tablet_devices'], isA<int>());
    });

    test('getDeviceLimitSummary - Shows available slots', () async {
      final summary = await service.getDeviceLimitSummary(orgId: testOrgId);

      expect(summary['mobile'], isA<Map>());
      expect(summary['mobile']['limit'], isA<int>());
      expect(summary['mobile']['used'], isA<int>());
      expect(summary['mobile']['available'], isA<int>());
      expect(summary['mobile']['can_add'], isA<bool>());
    });

  });

  group('RLS & Security Tests', () {
    
    test('isOrgOwner - Identifies owner correctly', () async {
      final isOwner = await service.isOrgOwner(
        orgId: testOrgId,
        userId: testOwnerId,
      );

      expect(isOwner, true);
    });

    test('isOrgOwner - Non-owner returns false', () async {
      final isOwner = await service.isOrgOwner(
        orgId: testOrgId,
        userId: 'not-owner',
      );

      expect(isOwner, false);
    });

  });
}
```

### Run Tests

```bash
# Run specific test file
flutter test test/services/feature_personalization_service_test.dart

# Run with verbose output
flutter test test/services/feature_personalization_service_test.dart --verbose

# Run with coverage
flutter test test/services/feature_personalization_service_test.dart --coverage
```

---

## ✅ Phase 4: UI Integration Testing

### Step 4.1: Manual Test - Feature Personalization Page

```dart
// In feature_personalization_page.dart (if it exists)
// Or create feature_control_admin_page.dart

class FeatureControlAdminPage extends StatefulWidget {
  const FeatureControlAdminPage({super.key});
  
  @override
  State<FeatureControlAdminPage> createState() => _FeatureControlAdminPageState();
}

class _FeatureControlAdminPageState extends State<FeatureControlAdminPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> devices = [];
  List<Map<String, dynamic>> auditLog = [];
  
  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }
  
  Future<void> _checkAuthAndLoad() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/');
      return;
    }
    
    await _loadControlPanel();
    await _loadAuditLog();
  }
  
  Future<void> _loadControlPanel() async {
    try {
      final panel = await FeaturePersonalizationService()
          .getTeamDeviceControlPanel(
            orgId: 'YOUR_ORG_ID',
            ownerUserId: supabase.auth.currentUser!.id,
          );
      
      if (mounted) {
        setState(() {
          devices = (panel['devices'] as List).cast<Map<String, dynamic>>();
          loading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading control panel: $e');
      if (mounted) setState(() => loading = false);
    }
  }
  
  Future<void> _loadAuditLog() async {
    try {
      final logs = await FeaturePersonalizationService()
          .getFeatureAuditLog(
            orgId: 'YOUR_ORG_ID',
            ownerUserId: supabase.auth.currentUser!.id,
          );
      
      if (mounted) setState(() => auditLog = logs.cast<Map<String, dynamic>>());
    } catch (e) {
      print('❌ Error loading audit log: $e');
    }
  }
  
  Future<void> _forceEnableAllFeatures(String deviceId, String userId) async {
    try {
      final result = await FeaturePersonalizationService()
          .forceEnableAllFeaturesOnDevice(
            orgId: 'YOUR_ORG_ID',
            ownerUserId: supabase.auth.currentUser!.id,
            targetDeviceId: deviceId,
            targetUserId: userId,
          );
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All features enabled')),
        );
        await _loadControlPanel();
        await _loadAuditLog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${result['error']}')),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Feature Control')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Owner Feature Control')),
      body: ListView(
        children: [
          // Device Control Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Team Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...devices.map((device) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${device['device_name']} (${device['device_type']})'),
                        Text('Email: ${device['member_email']}'),
                        Text('Features: ${device['features_count']}/6'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _forceEnableAllFeatures(
                            device['device_id'],
                            device['member_email'],
                          ),
                          child: const Text('Force Enable All Features'),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          // Audit Log Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audit Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...auditLog.take(10).map((log) => ListTile(
                  title: Text(log['action']),
                  subtitle: Text(log['details'] ?? ''),
                  trailing: Text(log['created_at'].toString().split('.')[0]),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Step 4.2: Test Checklist

- [ ] Owner can access feature control page
- [ ] Device list shows all team member devices
- [ ] "Force Enable All Features" button works
- [ ] Audit log displays with correct entries
- [ ] Features update in real-time (or after refresh)
- [ ] Non-owner cannot access control page (auth check)
- [ ] Error messages display correctly

---

## ✅ Phase 5: Security & RLS Testing

### Test 5.1: Cross-Org Data Isolation

```dart
// Simulate different org trying to access another org's audit logs
test('RLS prevents cross-org audit log access', () async {
  // Set auth to org2 user
  final supabase = Supabase.instance.client;
  
  // Try to view org1's audit logs (should fail)
  final result = await supabase
      .from('feature_audit_log')
      .select()
      .eq('org_id', 'org1-uuid');
  
  // Should return 0 rows due to RLS (different org)
  expect(result.length, 0);
});
```

### Test 5.2: Owner Permission Enforcement

```dart
// Non-owner tries to lock features (should fail)
test('Non-owner cannot lock features', () async {
  final result = await FeaturePersonalizationService()
      .lockFeaturesOrgWide(
        orgId: testOrgId,
        ownerUserId: 'non-owner-uuid', // Not the owner
        lockedFeatureIds: ['ai_agents'],
      );
  
  expect(result['error'], isNotNull);
  expect(result['status'], 'unauthorized');
});
```

### Test 5.3: Audit Trail Immutability

```sql
-- Verify audit logs cannot be updated or deleted (only inserted)
-- Try to update an audit log entry
UPDATE feature_audit_log
SET action = 'fake_action'
WHERE id = 'some-uuid';

-- Should fail with permission denied (RLS)
-- OR if it succeeds, trigger should log it as a new entry

-- Check if update was blocked
SELECT action FROM feature_audit_log WHERE id = 'some-uuid';
-- Expected: Original action still there (update blocked)
```

---

## ✅ Phase 6: Performance Testing

### Test 6.1: Query Performance

```sql
-- Check index usage
EXPLAIN ANALYZE
SELECT 
  id, action, performed_by, created_at
FROM feature_audit_log
WHERE org_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid
ORDER BY created_at DESC
LIMIT 100;
```

**Expected**: Uses index `idx_feature_audit_log_org_id` and `idx_feature_audit_log_created_at`

### Test 6.2: Load Test - 1000 Audit Entries

```sql
-- Insert 1000 test audit entries
WITH RECURSIVE nums AS (
  SELECT 1 as n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 1000
)
INSERT INTO feature_audit_log (org_id, action, performed_by, target_user_id, details)
SELECT 
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
  CASE (n % 5)
    WHEN 0 THEN 'force_enable_allFeatures'
    WHEN 1 THEN 'disable_features'
    WHEN 2 THEN 'lock_features_org_wide'
    WHEN 3 THEN 'unlock_features_org_wide'
    ELSE 'reset_all_team_features'
  END,
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000002'::uuid,
  'Load test entry #' || n::text
FROM nums;

-- Query should complete in < 100ms
SELECT COUNT(*) FROM feature_audit_log 
WHERE org_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid;
```

### Test 6.3: Trigger Performance

```sql
-- Update 100 feature_personalization records
-- Should create 100 audit logs via trigger
-- Measure time to complete

WITH RECURSIVE nums AS (
  SELECT 1 as n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 100
)
UPDATE feature_personalization fp
SET is_owner_enforced = (n % 2 = 0)
FROM nums
WHERE fp.user_id = '00000000-0000-0000-0000-000000000002'::uuid
AND row_number() OVER (ORDER BY fp.id) = nums.n;

-- Check if 100 audit logs were created
SELECT COUNT(*) FROM feature_audit_log
WHERE action IN ('feature_enforcement_enabled', 'feature_enforcement_disabled');
```

---

## 📊 Testing Summary Table

| Phase | Test | Expected Result | Status |
|-------|------|-----------------|--------|
| **1** | Migration columns exist | All 13 columns present | ☐ Pass |
| **1** | Indexes created | 4 indexes on audit_log | ☐ Pass |
| **1** | RLS policies exist | 2 policies configured | ☐ Pass |
| **1** | Trigger exists | feature_personalization_audit_trigger active | ☐ Pass |
| **2** | Owner lock features | organizations updated | ☐ Pass |
| **2** | Force enable device | feature_personalization updated | ☐ Pass |
| **2** | Trigger logs change | feature_audit_log entry created | ☐ Pass |
| **2** | Owner views logs | RLS allows access | ☐ Pass |
| **2** | Non-owner blocked | RLS denies access | ☐ Pass |
| **2** | Service role insert | Audit log insertion works | ☐ Pass |
| **3** | Service methods work | All 10 methods return expected results | ☐ Pass |
| **3** | Permission checks | Non-owner methods fail | ☐ Pass |
| **4** | UI loads correctly | Feature control page renders | ☐ Pass |
| **4** | Buttons functional | Force enable, disable, lock work | ☐ Pass |
| **5** | Cross-org blocked | RLS prevents data leak | ☐ Pass |
| **5** | Owner enforced | Non-owner cannot perform actions | ☐ Pass |
| **6** | Queries fast | < 100ms for 1000 entries | ☐ Pass |
| **6** | Trigger efficient | 100 updates trigger 100 logs | ☐ Pass |

---

## 🚀 Launch Checklist

Once all phases pass:

- [ ] All Phase 1 checks pass (migration applied)
- [ ] All Phase 2 checks pass (SQL-level)
- [ ] All Phase 3 checks pass (service methods)
- [ ] All Phase 4 checks pass (UI integration)
- [ ] All Phase 5 checks pass (security)
- [ ] All Phase 6 checks pass (performance)
- [ ] No production data affected (test data only)
- [ ] Team notified of new feature
- [ ] Documentation updated for users
- [ ] Deployment plan communicated

---

## 🔧 Rollback Plan (If Issues Found)

If any test fails:

```sql
-- Rollback: Remove new columns from organizations
ALTER TABLE organizations
DROP COLUMN IF EXISTS feature_lock_enabled,
DROP COLUMN IF EXISTS locked_features,
DROP COLUMN IF EXISTS feature_lock_reason,
DROP COLUMN IF EXISTS feature_lock_by,
DROP COLUMN IF EXISTS feature_lock_at,
DROP COLUMN IF EXISTS feature_unlock_at;

-- Rollback: Remove new columns from feature_personalization
ALTER TABLE feature_personalization
DROP COLUMN IF EXISTS is_owner_enforced,
DROP COLUMN IF EXISTS enforced_by,
DROP COLUMN IF EXISTS enforced_at,
DROP COLUMN IF EXISTS disabled_features,
DROP COLUMN IF EXISTS disabled_by_owner,
DROP COLUMN IF EXISTS disabled_by,
DROP COLUMN IF EXISTS disabled_at;

-- Rollback: Drop trigger and function
DROP TRIGGER IF EXISTS feature_personalization_audit_trigger ON feature_personalization;
DROP FUNCTION IF EXISTS log_feature_personalization_change();

-- Rollback: Drop feature_audit_log table
DROP TABLE IF EXISTS feature_audit_log;
```

---

**Ready to test!** Run Phase 1 first, then proceed sequentially. Let me know results! 🧪

