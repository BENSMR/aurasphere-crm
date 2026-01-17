# Owner Feature Control - Manual Flutter Testing Guide
**Date:** January 17, 2026  
**Component:** Feature Personalization & Owner Control  
**Duration:** ~30-45 minutes

---

## 🚀 Quick Start

### Prerequisites
1. Flutter app running locally: `flutter run -d chrome`
2. Two test accounts:
   - **Owner Account** (org owner)
   - **Team Member Account** (regular user)
3. Network inspector open (for API calls)
4. Browser console open (for errors)

---

## 📋 Test Scenarios

### **SCENARIO 1: Owner Permissions**

#### Test 1.1: Owner Can View Control Panel
```
👤 Account: Owner
🎯 Objective: Access owner control features

Steps:
1. Sign in as owner
2. Navigate to Settings → Organization → Owner Controls (or similar)
3. Look for:
   ✅ Team Member list with devices
   ✅ Force Enable button
   ✅ Disable Features button
   ✅ Lock/Unlock org-wide button
   ✅ Audit Log button
   ✅ Reset All Features button

Expected Result:
🟢 All owner control buttons visible and enabled
🟢 No "Unauthorized" errors
🟢 Console: No 401/403 errors
```

#### Test 1.2: Team Member Cannot View Control Panel
```
👤 Account: Team Member
🎯 Objective: Verify permission restriction

Steps:
1. Sign in as team member
2. Try to navigate to Owner Controls (type URL directly if needed)
3. Observe navigation/error

Expected Result:
🔴 Redirects to dashboard or shows "Unauthorized"
🔴 Cannot see owner control features
🟢 Console: Should show RLS policy denial or auth error
```

---

### **SCENARIO 2: Force Enable All Features**

#### Test 2.1: Owner Force-Enables Features on Team Member Device
```
👤 Account: Owner
🎯 Objective: Force all features on a team member's device

Steps:
1. Open Owner Control Panel
2. Select a team member from list (e.g., "John Smith")
3. Click device (e.g., "John's iPhone - Mobile")
4. Click "Force Enable All Features" button
5. Confirm action
6. Check network call in dev tools

Expected API Call:
📤 POST /invoke/forceEnableAllFeaturesOnDevice
{
  "orgId": "xxx",
  "ownerUserId": "yyy",
  "targetDeviceId": "device-id",
  "targetUserId": "team-member-id"
}

Expected Response:
✅ {
  "success": true,
  "message": "All features enabled on device",
  "device_id": "device-id",
  "features_enabled": 6 (mobile) or 8 (tablet),
  "enforced": true
}

Verification:
✅ Success message displayed
✅ Device shows "All Features Enabled" badge
✅ Audit log immediately shows new entry
✅ Team member's device reflects change (after refresh)
```

#### Test 2.2: Team Member's Device Shows Enforced Features
```
👤 Account: Team Member (after force enable)
🎯 Objective: Verify enforced features appear on device

Steps:
1. Sign in as team member on the affected device
2. Go to Feature Settings
3. Observe feature list

Expected Result:
✅ All features are selected (6 mobile / 8 tablet)
✅ Features appear "locked" or "enforced" (visual indicator)
✅ User cannot unselect enforced features
✅ Tooltip shows "Enforced by owner: [Date]"
```

---

### **SCENARIO 3: Disable Specific Features**

#### Test 3.1: Owner Disables Features for Team Member
```
👤 Account: Owner
🎯 Objective: Selectively disable features on device

Steps:
1. Open Owner Control Panel
2. Select team member and device
3. Click "Disable Features" button
4. Popup shows available features
5. Select features to disable (e.g., "AI Agents", "Marketing")
6. Click "Confirm Disable"
7. Check network call

Expected API Call:
📤 POST /invoke/disableFeaturesOnDevice
{
  "orgId": "xxx",
  "ownerUserId": "yyy",
  "targetDeviceId": "device-id",
  "targetUserId": "team-member-id",
  "featuresToDisable": ["ai_agents", "marketing"]
}

Expected Response:
✅ {
  "success": true,
  "message": "Features disabled on device",
  "features_disabled": 2,
  "remaining_features": 4
}

Verification:
✅ Success toast notification
✅ Device card shows "2 features disabled"
✅ Audit log shows new entry: "Disabled 2 features: ai_agents, marketing"
✅ Team member loses those features on next refresh
```

#### Test 3.2: Team Member Cannot Use Disabled Features
```
👤 Account: Team Member
🎯 Objective: Verify disabled features don't appear

Steps:
1. Refresh the app or re-login
2. Go to Feature Settings
3. Check feature list

Expected Result:
✅ "AI Agents" is unchecked and disabled
✅ "Marketing" is unchecked and disabled
✅ User cannot re-enable them (greyed out)
✅ Hover tooltip: "Disabled by organization owner"
```

---

### **SCENARIO 4: Lock Features Organization-Wide**

#### Test 4.1: Owner Locks Features for Entire Org
```
👤 Account: Owner
🎯 Objective: Enforce a compliance policy across entire org

Steps:
1. Open Owner Control Panel
2. Click "Lock Features Org-Wide" button
3. Select features to lock (e.g., "Digital Signature", "White Label")
4. Enter reason: "Enterprise security requirement"
5. Click "Lock"
6. Check network call

Expected API Call:
📤 POST /invoke/lockFeaturesOrgWide
{
  "orgId": "xxx",
  "ownerUserId": "yyy",
  "lockedFeatureIds": ["digital_signature", "whitelabel"],
  "reason": "Enterprise security requirement"
}

Expected Response:
✅ {
  "success": true,
  "message": "Features locked org-wide",
  "locked_features": 2,
  "reason": "Enterprise security requirement"
}

Verification:
✅ Success notification
✅ Control Panel shows lock status: "🔒 Features Locked"
✅ Shows locked features list
✅ Shows lock date and reason
✅ "Unlock" button now appears instead of "Lock"
```

#### Test 4.2: All Team Members See Locked Features
```
👤 Account: Team Member 1 & 2
🎯 Objective: Verify locked features apply org-wide

Steps:
1. Team Member 1 opens Feature Settings
2. Observe locked features (Digital Signature, White Label)
3. Team Member 2 does same in different window

Expected Result:
✅ Both see same locked features
✅ Locked features appear as "Organization Policy" badges
✅ Cannot disable locked features
✅ Cannot change locked features via API
```

---

### **SCENARIO 5: Unlock Features**

#### Test 5.1: Owner Unlocks Org-Wide Features
```
👤 Account: Owner
🎯 Objective: Remove org-wide lock

Steps:
1. Open Owner Control Panel
2. Click "Unlock Features" button
3. Confirm unlock action
4. Check network call

Expected API Call:
📤 POST /invoke/unlockFeaturesOrgWide
{
  "orgId": "xxx",
  "ownerUserId": "yyy"
}

Expected Response:
✅ {
  "success": true,
  "message": "Features unlocked org-wide"
}

Verification:
✅ Lock status removed
✅ Team members can now control locked features individually
```

---

### **SCENARIO 6: Reset All Team Features**

#### Test 6.1: Owner Resets All Team Member Features to Defaults
```
👤 Account: Owner
🎯 Objective: Reset team to default feature configuration

Steps:
1. Open Owner Control Panel
2. Click "Reset All Team Features" button
3. Enter reason: "Policy update - resetting to baseline"
4. Click "Confirm Reset"
5. Check for confirmation dialog

Expected Dialog:
⚠️ "This will reset features for X team members to defaults"
⚠️ "This cannot be undone"
⚠️ Show list of members affected
⚠️ Require reason entry
⚠️ Two buttons: "Cancel" and "Reset"

Expected API Call:
📤 POST /invoke/resetAllTeamFeaturestoDefaults
{
  "orgId": "xxx",
  "ownerUserId": "yyy",
  "reason": "Policy update - resetting to baseline"
}

Expected Response:
✅ {
  "success": true,
  "message": "All team features reset to defaults",
  "members_reset": 5,
  "reason": "Policy update - resetting to baseline"
}

Verification:
✅ Toast shows "Reset features for 5 team members"
✅ Audit log shows reset action with reason
✅ All team members now have default 6 (mobile) / 8 (tablet) features
```

---

### **SCENARIO 7: Audit Log**

#### Test 7.1: Owner Views Audit Log
```
👤 Account: Owner
🎯 Objective: See complete history of feature changes

Steps:
1. Open Owner Control Panel
2. Click "View Audit Log" or "Audit Trail" tab
3. Observe log entries
4. Filter/sort entries if available

Expected Log Entries:
🔍 Action: "force_enable_allFeatures"
   - Timestamp: [Date/Time]
   - Performer: "Owner Name (owner@email.com)"
   - Target: "John Smith - iPhone (Mobile)"
   - Details: "All features enabled on mobile device"

🔍 Action: "disable_features"
   - Timestamp: [Date/Time]
   - Performer: "Owner Name"
   - Target: "John Smith - iPhone"
   - Details: "Disabled 2 features: ai_agents, marketing"

🔍 Action: "lock_features_org_wide"
   - Timestamp: [Date/Time]
   - Performer: "Owner Name"
   - Target: (none - org-wide)
   - Details: "Locked 2 features org-wide. Reason: Enterprise security requirement"

🔍 Action: "reset_all_team_features"
   - Timestamp: [Date/Time]
   - Performer: "Owner Name"
   - Target: Multiple
   - Details: "Reset features for 5 team members. Reason: Policy update..."

Expected Result:
✅ Log shows all actions in reverse chronological order
✅ Each entry shows: action, timestamp, performer, target, details
✅ Can filter by action type
✅ Can search by performer or target
✅ Can export/download log (optional)
```

#### Test 7.2: Team Member Cannot View Audit Log
```
👤 Account: Team Member
🎯 Objective: Verify RLS protects audit log

Steps:
1. Try to access audit log (direct URL or API call)
2. Observe access denial

Expected Result:
🔴 404 Not Found or "Unauthorized"
🔴 Cannot see any audit log entries
🔴 Console: RLS policy violation message
```

---

### **SCENARIO 8: Owner Control Status**

#### Test 8.1: Owner Views Control Status Dashboard
```
👤 Account: Owner
🎯 Objective: See current feature control state

Steps:
1. Open Owner Control Panel
2. Look for "Control Status" or "Overview" section

Expected Display:
📊 Organization-wide Lock Status:
   - Lock Enabled: Yes/No
   - Locked Features: [list if locked]
   - Lock Reason: [if locked]
   - Lock Date: [timestamp]

📊 Device Enforcement Status:
   - Total Devices: 8
   - Devices with Enforced Features: 2
   - Devices with Disabled Features: 3
   - Last Change: 5 minutes ago

📊 Recent Changes:
   - [Last 5 audit log entries in brief]

Expected Result:
✅ Dashboard shows clear overview of all control actions
✅ All counts are accurate
✅ Last change timestamp matches audit log
```

---

### **SCENARIO 9: Device Registration & Limits**

#### Test 9.1: Owner Registers New Device (Under Limit)
```
👤 Account: Owner
🎯 Objective: Add a new device for team member

Current Plan: TEAM (allows 3 mobile + 2 tablet)
Current Devices: 2 mobile, 1 tablet

Steps:
1. Go to Team Members → Member Details
2. Click "Register Device"
3. Enter device info:
   - Device Type: Mobile
   - Device Name: "Sarah's Android"
   - Reference Code: (auto-generated or user input)
4. Click "Register"

Expected Result:
✅ Device registered successfully
✅ Reference code shown for device setup
✅ Device appears in list immediately
✅ Device counter updates: "3/3 mobile devices used"
```

#### Test 9.2: Owner Cannot Register Device (Limit Exceeded)
```
👤 Account: Owner
🎯 Objective: Prevent over-subscription

Current Plan: TEAM (allows 3 mobile)
Current Devices: 3 mobile (at limit)

Steps:
1. Try to register another mobile device
2. Fill in device form
3. Click "Register"

Expected Result:
🔴 Error message: "Device limit reached for subscription plan"
🔴 Cannot submit form (button disabled)
🔴 Shows: "You have 3/3 mobile devices. Upgrade to add more."
```

#### Test 9.3: Device Limit Summary
```
👤 Account: Owner
🎯 Objective: See device usage at a glance

Steps:
1. Open Device Management section
2. View device summary card

Expected Display:
📱 Mobile Devices: 3/3 (FULL)
🎨 Tablet Devices: 1/2 (1 available)

Color Coding:
🟢 Green: Under limit
🟡 Yellow: Near limit (80%+)
🔴 Red: At limit
```

---

### **SCENARIO 10: Feature Limits Per Device**

#### Test 10.1: Mobile Device Max 6 Features
```
👤 Account: Team Member
Device: Mobile (iPhone)
🎯 Objective: Verify mobile max features is 6

Steps:
1. Go to Feature Settings on mobile
2. Try to select 7 features
3. Observe behavior

Expected Result:
✅ Can select 1-6 features freely
🔴 7th feature is greyed out with message: "Mobile devices limited to 6 features"
🔴 Cannot exceed 6 even with drag/reorder
```

#### Test 10.2: Tablet Device Max 8 Features
```
👤 Account: Team Member
Device: Tablet (iPad)
🎯 Objective: Verify tablet max features is 8

Steps:
1. Go to Feature Settings on tablet
2. Try to select 9 features
3. Observe behavior

Expected Result:
✅ Can select 1-8 features freely
🔴 9th feature is greyed out with message: "Tablet devices limited to 8 features"
```

---

### **SCENARIO 11: Permission Denial Tests**

#### Test 11.1: Non-Owner Cannot Force Features
```
👤 Account: Team Member
🎯 Objective: Verify permission check at service level

Steps:
1. Open browser console
2. Run JavaScript to call API directly:
```javascript
fetch('/rest/v1/rpc/forceEnableAllFeaturesOnDevice', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + sessionStorage.getItem('sb-token')
  },
  body: JSON.stringify({
    orgId: 'xxx',
    ownerUserId: 'team-member-id', // NOT OWNER
    targetDeviceId: 'device-id',
    targetUserId: 'other-id'
  })
})
```

Expected Result:
🔴 Error response: "Only organization owner can force features"
🔴 Status: 403 Forbidden
🔴 No features modified
🔴 No audit log entry created
```

#### Test 11.2: Non-Owner Cannot Lock Org Features
```
👤 Account: Team Member
🎯 Objective: Verify org-wide lock is owner-only

Steps:
1. Use browser dev tools or API client
2. Attempt lockFeaturesOrgWide call as team member

Expected Result:
🔴 Error: "Only organization owner can lock features"
🔴 Organizations table unchanged
🔴 No audit log entry
```

---

### **SCENARIO 12: Cascade Delete & Data Integrity**

#### Test 12.1: Delete Organization Cascades Audit Logs
```
⚠️ CAUTION: This is destructive - use test org only
🎯 Objective: Verify referential integrity

Prerequisites:
- Test org with audit log entries
- No important data

Steps:
1. Admin access to Supabase console
2. Delete organization record
3. Check feature_audit_log table

Expected Result:
✅ All audit log entries for org deleted
✅ No orphaned records
✅ Foreign key constraint working
```

---

## ✅ Test Execution Checklist

- [ ] **Permission Tests**
  - [ ] Owner can access control panel
  - [ ] Team member cannot access control panel
  - [ ] Team member gets 403 on direct API calls

- [ ] **Feature Enforcement**
  - [ ] Force enable works and shows enforced indicator
  - [ ] Disable features removes them from device
  - [ ] Lock org-wide affects all team members
  - [ ] Unlock restores team member control

- [ ] **Audit Trail**
  - [ ] All actions logged in feature_audit_log
  - [ ] Timestamps are accurate
  - [ ] Audit log readable only by owner (RLS)
  - [ ] Entries show correct performer and target

- [ ] **Device Management**
  - [ ] Device registration respects plan limits
  - [ ] Cannot register device over limit
  - [ ] Reference codes are unique and functional

- [ ] **Feature Limits**
  - [ ] Mobile max 6 features enforced
  - [ ] Tablet max 8 features enforced
  - [ ] User cannot bypass limits
  - [ ] Owner-enforced features count toward limit

- [ ] **Error Handling**
  - [ ] All permission denials return proper errors
  - [ ] Limit exceeded shows helpful message
  - [ ] Network errors handled gracefully
  - [ ] Console shows no unhandled exceptions

- [ ] **Data Integrity**
  - [ ] Foreign key constraints prevent bad data
  - [ ] Cascade deletes work correctly
  - [ ] Timestamps auto-populate
  - [ ] RLS policies enforce correctly

---

## 🐛 Common Issues & Troubleshooting

### Issue: "Unauthorized" on Force Enable
```
Possible Causes:
1. User is not org owner
2. Auth token expired
3. RLS policy not applied

Debug:
- Check Supabase settings for RLS
- Verify user org_id in JWT token
- Check browser console for 403 errors
```

### Issue: Audit Log Not Showing Action
```
Possible Causes:
1. Trigger not firing
2. RLS policy blocking insert
3. Service role not configured

Debug:
- Check Supabase function logs
- Verify trigger exists: SELECT * FROM pg_trigger
- Check RLS policies on feature_audit_log
```

### Issue: Device Limit Not Enforced
```
Possible Causes:
1. canAddDevice() returns wrong value
2. UI not calling validation
3. Backend validation missing

Debug:
- Call getDeviceLimitSummary() and check results
- Verify subscription plan in organizations table
- Check service layer code
```

---

## 📊 Expected Console Logs

```
// Successful force enable:
✅ Owner forcing all features on device: abc123
🔐 Owner forcing all features on device: abc123
✅ All features enforced on device abc123

// Audit log creation:
🔒 Audit logged: force_enable_allFeatures by owner-id

// Permission denied:
❌ Unauthorized: Non-owner attempted feature override
❌ Error: Only organization owner can force features

// Device limit check:
📱 Device check: 3/3 for mobile
📱 User is org owner
✅ Device registered: Sarah's Android (mobile)
```

---

## 🎯 Success Criteria

✅ All permission checks enforced at service level  
✅ All actions logged in audit trail  
✅ RLS policies prevent unauthorized access  
✅ Device limits enforced by subscription plan  
✅ Feature enforcement works across all team members  
✅ No console errors or exceptions  
✅ UI matches expected behavior  
✅ Network calls show correct data flow  

---

**Last Updated:** January 17, 2026  
**Total Test Cases:** 25+  
**Estimated Runtime:** 30-45 minutes  
**Status:** Ready for Testing
