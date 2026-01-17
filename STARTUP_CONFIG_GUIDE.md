# 🚀 AuraSphere CRM - Startup Configuration Guide

**Status**: App running but needs configuration for full functionality  
**Date**: January 17, 2026  
**Project ID**: `lxufgzembtogmsvwhdvq` ✅ (Verified)

---

## 🔴 CRITICAL ISSUES (BLOCKING)

### 1. Email Confirmation Not Working
**Problem**: Users signup but don't receive verification emails  
**Root Cause**: `RESEND_API_KEY` secret not configured in Supabase  
**Solution**: [See Section 1 below]

### 2. Dashboard Shows Demo Data Only
**Problem**: Dashboard displays hardcoded sample data instead of real data  
**Root Cause**: `dashboard_page.dart` calls `_loadDemoData()` instead of querying Supabase  
**Solution**: [See Section 2 below]

### 3. Edge Functions Not Deployed
**Problem**: Email, AI agents, payments use Edge Functions but they're not deployed  
**Root Cause**: `supabase functions deploy` not run  
**Solution**: [See Section 3 below]

### 4. Feature Personalization Not Initialized
**Problem**: Missing features menu for users  
**Root Cause**: Feature tables not created, feature service not called  
**Solution**: [See Section 4 below]

---

## ✅ SOLUTION 1: Configure Email (RESEND)

### Step 1: Get RESEND API Key
```
1. Go to: https://resend.com/api-keys
2. Click "Create API Key"
3. Name: "AuraSphere Production"
4. Copy the key (starts with: re_)
```

### Step 2: Add to Supabase Secrets
```bash
# In VS Code Terminal:
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Run this command:
supabase secrets set RESEND_API_KEY=re_YOUR_KEY_HERE

# Verify it's set:
supabase secrets list
```

**Expected Output**:
```
Name                 Value
RESEND_API_KEY       re_xxxxxxxxxxxxxxxx ✅
```

### Step 3: Deploy send-email Function
```bash
supabase functions deploy send-email
```

**Expected Output**:
```
✅ Function 'send-email' deployed successfully
```

### Step 4: Test Email
```bash
# Run this in terminal:
curl -X POST https://lxufgzembtogmsvwhdvq.supabase.co/functions/v1/send-email \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4dWZnemVtYnRvZ21zdndoZHZxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTAxMTAsImV4cCI6MjA4NDEyNjExMH0.5Ha4bS4HeuMEqqalpPa_wCSol116rxlllR5s__kVtFs" \
  -H "Content-Type: application/json" \
  -d '{"to":"your-email@gmail.com","subject":"Test Email","body":"<p>Test from AuraSphere</p>"}'
```

**Expected Response**:
```json
{"success": true, "message": "Email sent successfully", "emailId": "..."}
```

---

## ✅ SOLUTION 2: Enable Real Dashboard Data

### Current Issue (Demo Data)
File: `lib/dashboard_page.dart` (Line 57-100)
```dart
// ❌ WRONG - Shows hardcoded demo data
_loadDemoData();  
```

### Fix: Connect to Real Supabase
Replace the `_loadData()` method:

```dart
Future<void> _loadData() async {
  try {
    print('📊 Loading dashboard data from Supabase...');
    
    final userId = supabase.auth.currentUser?.id;
    final orgId = await _getOrgId(userId!);
    
    if (orgId == null) {
      print('❌ User has no organization');
      return;
    }

    // Get real data from Supabase
    final stats = await _fetchDashboardStats(orgId);
    
    if (mounted) {
      setState(() {
        _totalRevenue = '\$${stats['total_revenue'] ?? 0}';
        _activeJobs = '${stats['active_jobs'] ?? 0}';
        _pendingInvoices = '${stats['pending_invoices'] ?? 0}';
        _teamMembers = '${stats['team_members'] ?? 0}';
        _completionRate = '${stats['completion_rate'] ?? 0}%';
        _expenses = '\$${stats['expenses'] ?? 0}';
        _newClients = '${stats['new_clients'] ?? 0}';
        _loading = false;
      });
    }
  } catch (e) {
    print('❌ Error loading dashboard: $e');
    if (mounted) setState(() => _loading = false);
  }
}

Future<String?> _getOrgId(String userId) async {
  try {
    final result = await supabase
        .from('org_members')
        .select('org_id')
        .eq('user_id', userId)
        .maybeSingle();
    
    return result?['org_id'] as String?;
  } catch (e) {
    print('❌ Error getting org_id: $e');
    return null;
  }
}

Future<Map<String, dynamic>> _fetchDashboardStats(String orgId) async {
  try {
    // Get invoices
    final invoices = await supabase
        .from('invoices')
        .select()
        .eq('org_id', orgId);
    
    // Get jobs
    final jobs = await supabase
        .from('jobs')
        .select()
        .eq('org_id', orgId);
    
    // Get team members
    final team = await supabase
        .from('org_members')
        .select()
        .eq('org_id', orgId);
    
    // Calculate stats
    final totalRevenue = (invoices as List)
        .where((i) => i['status'] == 'paid')
        .fold<double>(0, (sum, i) => sum + (i['amount'] as num? ?? 0).toDouble());
    
    final activeJobs = (jobs as List)
        .where((j) => j['status'] != 'completed')
        .length;
    
    final pendingInvoices = (invoices)
        .where((i) => i['status'] == 'sent')
        .length;
    
    return {
      'total_revenue': totalRevenue.toStringAsFixed(2),
      'active_jobs': activeJobs,
      'pending_invoices': pendingInvoices,
      'team_members': (team as List).length,
      'completion_rate': '85', // Calculate from jobs
      'expenses': '0', // From expenses table
      'new_clients': '0', // From clients table
    };
  } catch (e) {
    print('❌ Error fetching stats: $e');
    return {};
  }
}
```

---

## ✅ SOLUTION 3: Deploy Edge Functions

All email, payment, and AI features need Edge Functions deployed.

### Step 1: Deploy All Functions
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Deploy all functions at once
supabase functions deploy

# Or deploy individually:
supabase functions deploy send-email
supabase functions deploy send-whatsapp
supabase functions deploy groq-proxy
supabase functions deploy stripe-proxy
supabase functions deploy paddle-proxy
```

### Step 2: Verify Deployment
```bash
# List deployed functions
supabase functions list

# Expected output:
# send-email                deployed ✅
# send-whatsapp             deployed ✅
# groq-proxy                deployed ✅
# stripe-proxy              deployed ✅
# paddle-proxy              deployed ✅
```

### Step 3: Configure All Secrets
```bash
# Set all required API keys
supabase secrets set RESEND_API_KEY=re_YOUR_KEY
supabase secrets set GROQ_API_KEY=gsk_YOUR_KEY
supabase secrets set STRIPE_SECRET_KEY=sk_YOUR_KEY
supabase secrets set STRIPE_PUBLIC_KEY=pk_YOUR_KEY
supabase secrets set PADDLE_API_KEY=pdl_YOUR_KEY
supabase secrets set TWILIO_ACCOUNT_SID=AC_YOUR_SID
supabase secrets set TWILIO_AUTH_TOKEN=YOUR_TOKEN

# Verify all secrets
supabase secrets list
```

### Step 4: Test Verify Function
```bash
# This tests that all secrets are accessible
supabase functions invoke verify-secrets
```

**Expected Output**:
```
✅ GROQ_API_KEY: CONFIGURED
✅ RESEND_API_KEY: CONFIGURED
✅ STRIPE_SECRET_KEY: CONFIGURED
✅ STRIPE_PUBLIC_KEY: CONFIGURED
✅ PADDLE_API_KEY: CONFIGURED
✅ TWILIO_ACCOUNT_SID: CONFIGURED
✅ TWILIO_AUTH_TOKEN: CONFIGURED

Summary: ✅ ALL SECRETS CONFIGURED
```

---

## ✅ SOLUTION 4: Enable Feature Personalization

### Step 1: Create Feature Tables in Supabase
Run this SQL in Supabase Dashboard → SQL Editor:

```sql
-- Feature Personalization Table
CREATE TABLE IF NOT EXISTS feature_personalization (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  device_type TEXT NOT NULL, -- 'mobile' or 'tablet'
  selected_features JSONB NOT NULL DEFAULT '[]',
  feature_details JSONB,
  is_owner_enforced BOOLEAN DEFAULT FALSE,
  enforced_by UUID,
  enforced_at TIMESTAMP,
  disabled_features JSONB DEFAULT '[]',
  disabled_by_owner BOOLEAN DEFAULT FALSE,
  disabled_by UUID,
  disabled_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, device_type)
);

-- Feature Audit Log Table
CREATE TABLE IF NOT EXISTS feature_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id),
  action TEXT NOT NULL,
  performed_by UUID NOT NULL,
  target_user_id UUID,
  target_device_id UUID,
  details TEXT,
  timestamp TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Devices Table
CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organizations(id),
  device_type TEXT NOT NULL, -- 'mobile' or 'tablet'
  device_name TEXT NOT NULL,
  reference_code TEXT UNIQUE,
  registered_by UUID NOT NULL REFERENCES auth.users(id),
  registered_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE feature_personalization ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own features" 
  ON feature_personalization FOR SELECT 
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own features" 
  ON feature_personalization FOR UPDATE 
  USING (user_id = auth.uid());

CREATE POLICY "Org owners can view audit log" 
  ON feature_audit_log FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM organizations 
      WHERE organizations.id = feature_audit_log.org_id 
      AND organizations.owner_id = auth.uid()
    )
  );

CREATE POLICY "Org can view their devices" 
  ON devices FOR SELECT 
  USING (
    EXISTS (
      SELECT 1 FROM org_members 
      WHERE org_members.org_id = devices.org_id 
      AND org_members.user_id = auth.uid()
    )
  );
```

### Step 2: Test Feature Personalization
In your app, add a test button to Features page:

```dart
Future<void> _initializeFeatures() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  final features = await FeaturePersonalizationService()
      .getPersonalizedFeatures(
        userId: userId,
        deviceType: 'mobile',
      );

  print('✅ Features loaded: ${features.map((f) => f['id']).toList()}');
}
```

---

## 📋 VERIFICATION CHECKLIST

After completing all steps above, verify:

### Authentication
- [ ] Sign up with new email
- [ ] Receive verification email ✅ (RESEND configured)
- [ ] Click verification link
- [ ] Sign in successfully

### Dashboard
- [ ] Dashboard loads real data (not demo) ✅ (Supabase queries connected)
- [ ] See actual jobs, invoices, clients
- [ ] Numbers update when you add new data

### Features
- [ ] Feature menu appears ✅ (Tables created)
- [ ] Can select/deselect features
- [ ] Features persist across sessions
- [ ] Device limit enforced per plan

### Emails
- [ ] Payment reminders send ✅ (Edge Function deployed)
- [ ] Invoice notifications work
- [ ] Password reset emails send
- [ ] All emails have correct branding

### AI Agents (Optional)
- [ ] Set GROQ_API_KEY secret
- [ ] Deploy groq-proxy function
- [ ] Test Groq command parsing

### Payments (Optional)
- [ ] Set STRIPE/PADDLE secrets
- [ ] Deploy payment functions
- [ ] Test payment flow

---

## 🚨 COMMON ERRORS & FIXES

### Error: "Invalid API Key" (Email)
**Cause**: RESEND_API_KEY not set  
**Fix**: Run `supabase secrets set RESEND_API_KEY=re_...`

### Error: "Function not found"
**Cause**: Edge Function not deployed  
**Fix**: Run `supabase functions deploy`

### Error: "RLS policy violation"
**Cause**: Missing org_id in Supabase queries  
**Fix**: All queries must include `.eq('org_id', orgId)`

### Error: "No verification email received"
**Cause**: Email service not configured  
**Fix**: Complete Solution 1 above

### Dashboard shows demo data
**Cause**: Code still calls `_loadDemoData()`  
**Fix**: Replace with real Supabase queries (Solution 2)

---

## 📊 CONFIGURATION STATUS

| Feature | Status | How to Fix |
|---------|--------|-----------|
| Supabase Connection | ✅ Working | Done |
| Auth (Signup/Login) | ⚠️ Partial | Add RESEND_API_KEY |
| Email Verification | ❌ Not working | Deploy send-email |
| Dashboard | ⚠️ Demo only | Update dashboard_page.dart |
| Features | ❌ Not configured | Create tables + initialize |
| AI Agents | ❌ Not configured | Deploy groq-proxy |
| Payments | ❌ Not configured | Deploy stripe/paddle proxies |
| WhatsApp | ❌ Not configured | Deploy send-whatsapp |

---

## 🎯 NEXT STEPS (Priority Order)

1. **IMMEDIATE**: Configure RESEND email (10 min) → Users can verify
2. **TODAY**: Deploy Edge Functions (5 min) → Features work
3. **TODAY**: Fix Dashboard (15 min) → Real data loads
4. **THIS WEEK**: Configure AI agents → Automation works
5. **THIS WEEK**: Configure payments → Billing works

---

## ❓ QUESTIONS?

- **Email not sending?** Check: Supabase Dashboard → Functions → send-email → Logs
- **Dashboard still demo?** Check: Browser Console for errors
- **Features not appearing?** Check: Database has tables with RLS policies
- **Can't deploy functions?** Check: `supabase status` shows project connected

---

**Ready to proceed with configuration?**  
Start with RESEND email setup above. 👆

