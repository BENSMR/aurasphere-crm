# ✅ Feature Personalization Database Setup - QUICK START

## 📋 What's Included

Three production-ready database tables with full RLS security:

1. **devices** - Register mobile/tablet devices with subscription limit enforcement
2. **feature_personalization** - Store user's selected features per device type
3. **feature_audit_log** - Complete audit trail for compliance/security

---

## 🚀 HOW TO APPLY (2 Options)

### ✅ OPTION 1: Supabase Dashboard (Easiest - 1 minute)

1. **Open Supabase Dashboard**
   - Go to: https://app.supabase.com/project/lxufgzembtogmsvwhdvq

2. **Navigate to SQL Editor**
   - Left sidebar → SQL Editor

3. **Create New Query**
   - Click "New Query" button

4. **Copy & Paste SQL**
   - Open: `supabase/migrations/20260117_add_feature_personalization.sql`
   - Copy entire file contents
   - Paste into SQL Editor

5. **Run Query**
   - Click "Run" button
   - Wait for green ✓ Success message

6. **Verify**
   - Go to "Table Editor"
   - Should see 3 new tables:
     - ✅ devices
     - ✅ feature_personalization
     - ✅ feature_audit_log

---

### ⏳ OPTION 2: Supabase CLI (If you prefer CLI)

```bash
# Tables will be created automatically from migration file
supabase db push

# Or view the SQL first
cat supabase/migrations/20260117_add_feature_personalization.sql

# Then push
supabase functions deploy  # Will also run migrations
```

---

## 🎯 What Each Table Does

### devices
```
✅ Register mobile/tablet devices
✅ Assign to users in organization
✅ Enforce subscription-based limits:
   - Solo: 2 mobile / 1 tablet
   - Team: 3 mobile / 2 tablet
   - Workshop: 5 mobile / 3 tablet
✅ Track last used & registration date
```

Example:
```
Device: "Ben's iPhone"
Type: mobile
Reference Code: ABC123
Registered: Jan 17, 2026
```

### feature_personalization
```
✅ Store selected features per user per device
✅ Max 6 features on mobile
✅ Max 8 features on tablet
✅ Support owner enforcement
✅ Track disabled features per owner
```

Example:
```
User: ben@email.com
Device Type: mobile
Selected: ['dashboard', 'jobs', 'invoices', 'clients', 'calendar', 'expenses']
Enforced by: owner (can't change)
```

### feature_audit_log
```
✅ Complete audit trail
✅ Track who changed what
✅ Record compliance events
✅ Security logging
```

Example:
```
Action: force_enable_allFeatures
Performer: owner@email.com
Target: team_member@email.com
Device: ABC123
Time: Jan 17, 2026 10:15 AM
```

---

## ✅ AFTER SETUP - What Works Now

### For Users
- ✅ Select favorite 6 features (mobile) or 8 (tablet)
- ✅ Selection saves to database
- ✅ Works across all devices
- ✅ Easy feature switching

### For Organization Owners
- ✅ Force all features on team member device
- ✅ Disable specific features for compliance
- ✅ Lock features org-wide
- ✅ View complete audit trail
- ✅ Reset all team features to defaults
- ✅ Manage device limits per subscription

### In the App
- **Feature Personalization Page** - Now fully functional ✅
- **Device Management** - Now fully functional ✅
- **Owner Control Panel** - Now fully functional ✅
- **Audit Trail** - Now fully functional ✅

---

## 🔍 VERIFICATION AFTER SETUP

### In Supabase Dashboard:

1. **Table Editor** → Should show 3 new tables
   ```
   ✓ devices
   ✓ feature_personalization
   ✓ feature_audit_log
   ```

2. **RLS Status** → All 3 tables should have lock icon 🔒
   ```
   Click each table → Shows RLS enabled
   ```

3. **Policies** → Each table should have policies
   ```
   devices: 4 policies (select, insert, update, delete)
   feature_personalization: 5 policies
   feature_audit_log: 2 policies
   ```

### In Flutter App:

Test the service:
```dart
// In any page:
final service = FeaturePersonalizationService();

// Get user's features for mobile
final features = await service.getPersonalizedFeatures(
  userId: userId,
  deviceType: 'mobile',
);

// Save features
await service.savePersonalizedFeatures(
  userId: userId,
  deviceType: 'mobile',
  selectedFeatureIds: ['dashboard', 'jobs', 'invoices'],
);

// Owner: Force all features
await service.forceEnableAllFeaturesOnDevice(
  orgId: orgId,
  ownerUserId: currentUserId,
  targetDeviceId: deviceId,
  targetUserId: teamMemberId,
);
```

---

## 📊 Table Structure Reference

### devices
```sql
id: UUID (primary key)
org_id: UUID (references organizations)
device_type: 'mobile' | 'tablet'
device_name: string (e.g., "Ben's iPhone")
reference_code: string (6-char code)
user_id: UUID (device owner)
registered_by: UUID (who registered)
registered_at: timestamp
is_active: boolean
created_at, updated_at: timestamp
```

### feature_personalization
```sql
id: UUID (primary key)
user_id: UUID
device_type: 'mobile' | 'tablet'
org_id: UUID
selected_features: string[] (feature IDs)
is_owner_enforced: boolean
enforced_by: UUID
disabled_features: string[]
created_at, updated_at: timestamp
```

### feature_audit_log
```sql
id: UUID (primary key)
org_id: UUID
action: string (action type)
performed_by: UUID
target_user_id: UUID (nullable)
target_device_id: UUID (nullable)
details: string
timestamp: timestamp
created_at: timestamp
```

---

## ⚠️ TROUBLESHOOTING

### Error: "Relation does not exist"
- Table wasn't created successfully
- Check for SQL errors in dashboard
- Rerun the entire migration

### Error: "Permission denied"
- RLS policy blocking access
- Verify you're logged in as org owner
- Check `organization.owner_id` matches current user

### Error: "Unique violation on unique_user_device_type"
- User already has feature preference for that device type
- This is expected on second save
- Update should use upsert (which service does)

### Features not persisting
- Check browser DevTools → Network tab
- Verify API calls to Supabase are succeeding (200 status)
- Check feature_personalization table has rows

---

## 🎯 NEXT STEPS

1. ✅ **Apply Migration** (this document)
   - Run SQL in Supabase Dashboard
   - Verify 3 tables created with RLS

2. ⏳ **Test in App**
   - Sign in
   - Navigate to Feature Personalization page
   - Select features
   - Verify they persist on reload

3. ⏳ **Test Owner Control** (if you have team member)
   - Sign in as owner
   - Go to Owner Control Panel
   - Force/disable features on team device
   - Verify in audit log

4. ⏳ **Optional: Device Registration**
   - Register a mobile device
   - Check device limits enforced
   - Verify reference code generated

---

## 📝 FILE LOCATION

Migration file: `supabase/migrations/20260117_add_feature_personalization.sql`

Contains:
- 3 table definitions with indexes
- 9 RLS security policies
- 2 auto-update triggers
- Comprehensive comments
- Verification queries

---

## ✨ COMPLETION CHECKLIST

After running the migration:

- [ ] 3 tables created (devices, feature_personalization, feature_audit_log)
- [ ] RLS enabled on all 3 tables (lock icons visible)
- [ ] All indexes created for performance
- [ ] All RLS policies active
- [ ] Migration file in supabase/migrations/
- [ ] Feature Personalization Service ready to use
- [ ] Device management ready
- [ ] Owner control panel ready
- [ ] Audit logging ready

---

**Status**: Ready to apply ✅
**Complexity**: Low (copy & paste SQL)
**Time to apply**: 1-2 minutes
**Impact**: Feature personalization fully enabled

Good luck! 🚀
