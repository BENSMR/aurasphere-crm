# Owner Feature Control - Testing & Validation Plan
**Date:** January 17, 2026  
**Component:** Owner Feature Control & Audit Logging System

---

## ✅ Tests to Run

### 1. **Schema Verification Tests**
- [ ] `feature_audit_log` table exists with all columns
- [ ] `organizations` table has owner control columns
- [ ] `feature_personalization` table has enforcement columns
- [ ] All foreign key constraints are valid
- [ ] All indexes are created (4 indexes on feature_audit_log)
- [ ] RLS is enabled on feature_audit_log

**SQL Test File:** `test_owner_feature_control.sql`

---

### 2. **RLS Policy Tests**

#### Policy 1: Audit Log Owner View
```dart
// Only org owner should see their audit logs
final logs = await supabase
    .from('feature_audit_log')
    .select()
    .eq('org_id', orgId);
// ✅ SHOULD: Return logs if user is org owner
// ❌ SHOULD NOT: Return logs if user is team member
```

#### Policy 2: Audit Log Service Insert
```dart
// Service/system role should insert logs
final result = await supabase
    .from('feature_audit_log')
    .insert({...});
// ✅ SHOULD: Allow insert with proper permissions
```

---

### 3. **Feature Enforcement Tests (FeaturePersonalizationService)**

#### Test: Force Enable All Features
```dart
final result = await FeaturePersonalizationService()
    .forceEnableAllFeaturesOnDevice(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
      targetDeviceId: 'target-device-id',
      targetUserId: 'team-member-id',
    );
// ✅ SHOULD: Return success with all features enabled
// ✅ SHOULD: Set is_owner_enforced = true
// ✅ SHOULD: Log action in feature_audit_log
// ❌ SHOULD FAIL: If user is not org owner
```

#### Test: Disable Specific Features
```dart
final result = await FeaturePersonalizationService()
    .disableFeaturesOnDevice(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
      targetDeviceId: 'device-id',
      targetUserId: 'team-member-id',
      featuresToDisable: ['ai_agents', 'marketing'],
    );
// ✅ SHOULD: Remove specified features
// ✅ SHOULD: Set disabled_features JSONB
// ✅ SHOULD: Log in audit trail
// ❌ SHOULD FAIL: If not owner
```

#### Test: Lock Features Org-Wide
```dart
final result = await FeaturePersonalizationService()
    .lockFeaturesOrgWide(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
      lockedFeatureIds: ['digital_signature', 'whitelabel'],
      reason: 'Enterprise security requirement',
    );
// ✅ SHOULD: Update organizations.feature_lock_enabled = true
// ✅ SHOULD: Store locked_features in JSONB
// ✅ SHOULD: Log action in audit trail
// ✅ SHOULD: Set feature_lock_at timestamp
```

#### Test: Unlock Features Org-Wide
```dart
final result = await FeaturePersonalizationService()
    .unlockFeaturesOrgWide(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
    );
// ✅ SHOULD: Set feature_lock_enabled = false
// ✅ SHOULD: Clear locked_features
// ✅ SHOULD: Set feature_unlock_at timestamp
// ✅ SHOULD: Log unlock action
```

#### Test: Reset All Team Features
```dart
final result = await FeaturePersonalizationService()
    .resetAllTeamFeaturestoDefaults(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
      reason: 'Compliance reset',
    );
// ✅ SHOULD: Reset all team members to default features
// ✅ SHOULD: Log reset action with reason
```

---

### 4. **Audit Trail Tests**

#### Test: Retrieve Audit Log
```dart
final auditLog = await FeaturePersonalizationService()
    .getFeatureAuditLog(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
    );
// ✅ SHOULD: Return list of audit entries
// ✅ SHOULD: Show action, performer, timestamp, details
// ✅ SHOULD: Filter by org_id automatically (RLS)
// ❌ SHOULD FAIL: If user is not owner
```

#### Test: Get Control Status
```dart
final status = await FeaturePersonalizationService()
    .getOwnerControlStatus(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
    );
// ✅ SHOULD: Show:
//   - org_wide_lock_enabled status
//   - locked_features list
//   - devices_with_enforced_features count
//   - devices_with_disabled_features count
//   - recent_changes count
// ❌ SHOULD FAIL: If not owner
```

#### Test: Get Team Device Control Panel
```dart
final panel = await FeaturePersonalizationService()
    .getTeamDeviceControlPanel(
      orgId: 'test-org-id',
      ownerUserId: 'owner-user-id',
    );
// ✅ SHOULD: Return all team devices with:
//   - Device name, type, owner
//   - Features count
//   - Enforcement status
//   - Available actions
// ❌ SHOULD FAIL: If not owner
```

---

### 5. **Device Registration Tests**

#### Test: Register Device with Limit Check
```dart
final result = await FeaturePersonalizationService()
    .registerDevice(
      orgId: 'test-org-id',
      userId: 'owner-user-id',
      deviceType: 'mobile',
      deviceName: 'John\'s iPhone',
      referenceCode: 'ABC123',
    );
// ✅ SHOULD: Create device with reference code
// ❌ SHOULD FAIL: If limit exceeded for plan
// ❌ SHOULD FAIL: If not org owner
```

#### Test: Device Limit Checking
```dart
final canAdd = await FeaturePersonalizationService()
    .canAddDevice(orgId: 'test-org-id', deviceType: 'mobile');
// ✅ SHOULD: Return true if under limit
// ✅ SHOULD: Return false if at limit

final summary = await FeaturePersonalizationService()
    .getDeviceLimitSummary(orgId: 'test-org-id');
// ✅ SHOULD: Show:
//   - Mobile: limit, used, available, can_add
//   - Tablet: limit, used, available, can_add
```

---

### 6. **Permission Tests**

#### Test: Owner Verification
```dart
final isOwner = await FeaturePersonalizationService()
    .isOrgOwner(orgId: 'test-org-id', userId: 'user-id');
// ✅ SHOULD: Return true for owner
// ✅ SHOULD: Return false for team member
```

#### Test: Non-Owner Cannot Control Features
```dart
// Try to force features as team member
final result = await FeaturePersonalizationService()
    .forceEnableAllFeaturesOnDevice(
      orgId: 'test-org-id',
      ownerUserId: 'team-member-id', // NOT OWNER
      targetDeviceId: 'device-id',
      targetUserId: 'other-member-id',
    );
// ❌ SHOULD: Return error "Only organization owner can force features"
// ❌ SHOULD: NOT create audit log entry
// ❌ SHOULD: NOT modify features
```

---

### 7. **Trigger Tests**

#### Test: Audit Trigger Fires on Update
```dart
// Update feature_personalization directly
UPDATE feature_personalization 
SET is_owner_enforced = true, enforced_by = 'owner-id'
WHERE user_id = 'user-id' AND device_type = 'mobile';

// Check if trigger logged it
SELECT * FROM feature_audit_log 
WHERE action = 'feature_enforcement_enabled'
AND target_user_id = 'user-id';
// ✅ SHOULD: Find new audit log entry
```

---

### 8. **Data Integrity Tests**

#### Test: Cascade Delete on Org Delete
```dart
-- When organization is deleted, audit logs should cascade delete
DELETE FROM organizations WHERE id = 'org-id';

SELECT COUNT(*) FROM feature_audit_log 
WHERE org_id = 'org-id';
-- ✅ SHOULD: Return 0 (all logs deleted)
```

#### Test: Foreign Key Constraints
```dart
-- Try to insert audit log with invalid org_id
INSERT INTO feature_audit_log (org_id, action, performed_by) 
VALUES ('invalid-uuid'::uuid, 'test', 'user-id'::uuid);
-- ❌ SHOULD: Fail with foreign key constraint error
```

---

## 🎯 Expected Results Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Schema Creation | ✅ | All tables and columns present |
| RLS Policies | ✅ | Owner can view, system can insert |
| Triggers | ✅ | Auto-log on feature enforcement changes |
| Permission Checks | ✅ | Only owners can control features |
| Audit Trail | ✅ | Complete history for compliance |
| Device Limits | ✅ | Enforced by subscription plan |
| Cascade Deletes | ✅ | Maintains referential integrity |

---

## 🚀 How to Run Tests

### Option 1: Manual SQL Validation
```bash
cat test_owner_feature_control.sql | psql -h your-db-host -U postgres -d postgres
```

### Option 2: Dart Integration Tests
Create `test/feature_personalization_test.dart` with all scenarios above

### Option 3: Manual Flutter Testing
1. Sign in as org owner
2. Navigate to Owner Control Panel
3. Test each action: force enable, disable, lock, unlock, reset
4. Verify audit trail shows all changes
5. Test as team member - should see "unauthorized" errors

---

## 📋 Test Execution Checklist

- [ ] Run schema validation SQL
- [ ] Test all RLS policies
- [ ] Test owner permission enforcement
- [ ] Test all feature control methods
- [ ] Verify audit trail logging
- [ ] Test device registration and limits
- [ ] Test cascade deletes
- [ ] Run with both owner and team member accounts
- [ ] Check Flutter app UI reflects changes
- [ ] Verify no console errors in browser dev tools

---

**Last Updated:** January 17, 2026  
**Status:** Ready for Testing
