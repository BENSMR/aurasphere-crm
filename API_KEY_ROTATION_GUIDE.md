# API Key Rotation Guide

## ⚠️ CRITICAL: Keys Have Been Exposed

The following API keys were exposed in git history and **MUST be rotated immediately**:
- `GROQ_API_KEY` (Groq LLM API)
- `RESEND_API_KEY` (Email service)
- `OCR_API_KEY` (Receipt scanning service)

**Timeline**: These keys should have been rotated within the first 15 minutes of discovering the exposure.

---

## Step 1: Generate New API Keys (One Per Service)

### 1.1 Rotate Groq API Key

**Duration**: ~5 minutes

1. Go to [Groq Console](https://console.groq.com)
2. Log in with your account credentials
3. Navigate to **API Keys** section
4. Click **"Create New API Key"**
5. Copy the new key (starts with `gsk_`)
6. **Delete the old/exposed key** in the Groq dashboard
7. Keep the new key temporarily (you'll paste it into Supabase next)

**Verification**:
```
New Groq Key Format: gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
Length: ~45 characters
Starts with: gsk_
```

---

### 1.2 Rotate Resend API Key

**Duration**: ~5 minutes

1. Go to [Resend Dashboard](https://resend.com/dashboard)
2. Log in with your account
3. Navigate to **API Keys** (sidebar → "Settings" → "API Keys")
4. Click **"Create API Key"** or **"Generate New Key"**
5. Name it: `AuraSphere-CRM-Rotated-[DATE]` (e.g., `AuraSphere-CRM-Rotated-Jan2026`)
6. Copy the new key (starts with `re_`)
7. **Disable/Delete the old key** in Resend dashboard
8. Keep the new key temporarily

**Verification**:
```
New Resend Key Format: re_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
Length: ~40 characters
Starts with: re_
```

---

### 1.3 Rotate OCR API Key

**Duration**: ~5 minutes

*The exact steps depend on your OCR provider (Google Cloud Vision, Azure Computer Vision, etc.)*

**If using Google Cloud Vision API**:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to **APIs & Services** → **Credentials**
4. Find your existing API key
5. Click **"Create Credentials"** → **"API Key"**
6. Copy the new key
7. **Delete the old key** in Google Cloud
8. Restrict the new key to **Vision API only**

**If using Azure Computer Vision**:
1. Go to [Azure Portal](https://portal.azure.com)
2. Find your Computer Vision resource
3. Navigate to **Keys and Endpoint**
4. Click **"Regenerate Key 1"** or **"Regenerate Key 2"**
5. Copy the new key
6. Update your usage if you were using a specific key

**If using another OCR service**:
- Follow their standard key rotation process
- Revoke/delete the old key immediately

---

## Step 2: Add New Keys to Supabase

**Duration**: ~10 minutes

### 2.1 Access Supabase Secrets

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your **AuraSphere CRM** project
3. Navigate to **Settings** → **Secrets**
4. You should see the old secrets listed (if any are still there)

### 2.2 Add/Update Groq Secret

1. Click **"New Secret"** or **Edit** the existing `GROQ_API_KEY`
2. Set:
   - **Name**: `GROQ_API_KEY`
   - **Value**: `gsk_[YOUR_NEW_KEY]` (the full key from Groq)
   - **Encryption**: Leave as default
3. Click **"Save"**
4. Verify it appears in the secrets list with a green checkmark ✅

### 2.3 Add/Update Resend Secret

1. Click **"New Secret"** or **Edit** the existing `RESEND_API_KEY`
2. Set:
   - **Name**: `RESEND_API_KEY`
   - **Value**: `re_[YOUR_NEW_KEY]` (the full key from Resend)
   - **Encryption**: Leave as default
3. Click **"Save"**
4. Verify it appears in the secrets list with a green checkmark ✅

### 2.4 Add/Update OCR Secret

1. Click **"New Secret"** or **Edit** the existing `OCR_API_KEY`
2. Set:
   - **Name**: `OCR_API_KEY`
   - **Value**: `[YOUR_NEW_OCR_KEY]`
   - **Encryption**: Leave as default
3. Click **"Save"**
4. Verify it appears in the secrets list with a green checkmark ✅

---

## Step 3: Verify Edge Functions Can Access Secrets

**Duration**: ~5 minutes

### 3.1 Check Edge Function Configuration

1. Go to **Edge Functions** in Supabase dashboard
2. For each Edge Function (`groq-proxy`, `email-proxy`, `ocr-proxy`):
   - Click on the function name
   - Check **Secrets** section
   - Verify the new keys are listed as "Available"

### 3.2 Test Secret Access

In your Edge Function code, verify secrets are available:

```typescript
// groq-proxy function
const groqKey = Deno.env.get("GROQ_API_KEY");
if (!groqKey) {
  console.error("GROQ_API_KEY not found in secrets");
  // Handle error
}

// email-proxy function
const resendKey = Deno.env.get("RESEND_API_KEY");
if (!resendKey) {
  console.error("RESEND_API_KEY not found in secrets");
  // Handle error
}

// ocr-proxy function
const ocrKey = Deno.env.get("OCR_API_KEY");
if (!ocrKey) {
  console.error("OCR_API_KEY not found in secrets");
  // Handle error
}
```

---

## Step 4: Test the New Keys

**Duration**: ~10 minutes

### 4.1 Run Unit Tests

```bash
# Run all security tests (includes API key validation)
flutter test test/security_unit_tests.dart

# Run API integration tests (requires Edge Functions deployed)
flutter test test/api_integration_tests.dart
```

**Expected Output**:
```
✓ All security unit tests pass
✓ Input validation tests pass (30/30)
✓ Rate limiting tests pass (6/6)
ℹ️  API integration tests show "Edge Function not deployed" (expected if not deployed yet)
```

### 4.2 Manual Test Checklist

- [ ] **Test Groq LLM**:
  1. Go to **Dashboard** → **Aura Chat**
  2. Type: `Send invoice to client`
  3. Should parse the command using Groq API
  4. Check browser console for no 401/403 errors

- [ ] **Test Email Sending**:
  1. Go to **Invoice Details** → **Send Invoice**
  2. Enter a test email address
  3. Click "Send"
  4. Check console logs: should show `✅ Email sent successfully`

- [ ] **Test OCR (Receipt Scanning)**:
  1. Go to **Expense List** → **Add Expense**
  2. Click "Scan Receipt"
  3. Upload a test image
  4. Should process without API errors

- [ ] **Verify No Exposed Keys**:
  1. Open browser Developer Tools (F12)
  2. Go to **Network** tab
  3. Filter for `groq` / `resend` / `ocr` requests
  4. Should NOT see API keys in request headers or body
  5. Should only see Edge Function calls (to Supabase domain)

---

## Step 5: Verify Old Keys Are Revoked

**Duration**: ~5 minutes

### 5.1 Groq Dashboard
1. Go to [Groq Console](https://console.groq.com) → **API Keys**
2. Verify OLD key is **deleted** or **disabled** ✅
3. Verify NEW key is **active** ✅

### 5.2 Resend Dashboard
1. Go to [Resend](https://resend.com/dashboard) → **Settings** → **API Keys**
2. Verify OLD key is **deleted** or **disabled** ✅
3. Verify NEW key is **active** ✅

### 5.3 OCR Provider Dashboard
1. Go to your OCR provider's dashboard
2. Verify OLD key is **deleted** or **disabled** ✅
3. Verify NEW key is **active** ✅

---

## Step 6: Clean Up Git History (Optional but Recommended)

**Duration**: ~10 minutes

### 6.1 Remove Old Secrets from Git History

If the old keys are in git history, they should be removed:

```bash
# View git history for exposed keys
git log --all --full-history -p -- lib/core/env_loader.dart | grep -i "GROQ_API_KEY\|RESEND_API_KEY\|OCR_API_KEY"

# Use BFG Repo Cleaner to remove secrets from all history
# Download: https://rtyley.github.io/bfg-repo-cleaner/

# Replace with placeholders
bfg --replace-text secrets.txt .

# Force push to remote (ONLY if you control the repository)
git push origin --force --all
```

---

## Step 7: Update Documentation

**Duration**: ~5 minutes

### 7.1 Document the Rotation Date

Create a new file: `SECURITY_INCIDENTS.md`

```markdown
# Security Incidents Log

## Incident 1: API Key Exposure (Jan 2026)

**Date Discovered**: January 1, 2026
**Severity**: CRITICAL
**Keys Exposed**: 
- GROQ_API_KEY
- RESEND_API_KEY  
- OCR_API_KEY

**Remediation**:
- ✅ Rotated all 3 keys (Jan 1, 2026)
- ✅ Updated Supabase secrets (Jan 1, 2026)
- ✅ Verified old keys disabled (Jan 1, 2026)
- ✅ Tested new keys in production (Jan 1, 2026)

**Impact**: No unauthorized access detected
**Lessons Learned**: Use Edge Functions for all secret keys (DONE)
```

---

## Troubleshooting

### Issue: "GROQ_API_KEY not found in Edge Function"
**Solution**: 
1. Verify the secret is in Supabase dashboard
2. Restart Edge Functions: `supabase functions publish groq-proxy`
3. Check Edge Function logs for errors

### Issue: "401 Unauthorized" errors from Groq/Resend/OCR
**Solution**:
1. The new key might be invalid
2. Verify you copied the ENTIRE key (no extra spaces)
3. Verify the key format matches the service's requirements
4. Try regenerating a new key in the provider's dashboard

### Issue: Edge Functions are failing
**Solution**:
1. Go to Edge Functions → Logs
2. Check for error messages about missing secrets
3. Verify secrets are added to the correct Edge Function
4. Redeploy the function: `supabase functions deploy [function-name]`

---

## Security Best Practices

✅ **DO**:
- Store API keys in Supabase Edge Function secrets only
- Rotate keys every 90 days (even if not exposed)
- Monitor API key usage in provider dashboards
- Delete old keys immediately after rotation
- Use different keys for dev/staging/production

❌ **DON'T**:
- Commit keys to git (use `.env.local` ignored files)
- Share keys via email or chat
- Use the same key across multiple services
- Leave old keys active after rotation
- Hardcode keys in frontend code (only Edge Functions)

---

## Timeline Summary

| Step | Action | Duration | Status |
|------|--------|----------|--------|
| 1.1 | Generate new Groq key | 5 min | ⏳ TODO |
| 1.2 | Generate new Resend key | 5 min | ⏳ TODO |
| 1.3 | Generate new OCR key | 5 min | ⏳ TODO |
| 2 | Add secrets to Supabase | 10 min | ⏳ TODO |
| 3 | Verify Edge Functions access | 5 min | ⏳ TODO |
| 4 | Run tests | 10 min | ⏳ TODO |
| 5 | Revoke old keys | 5 min | ⏳ TODO |
| 6 | Clean git history | 10 min | ⏳ TODO |
| 7 | Document incident | 5 min | ⏳ TODO |
| **TOTAL** | **All steps** | **~1 hour** | ⏳ TODO |

---

## Questions?

- **Groq Support**: [support.groq.com](https://support.groq.com)
- **Resend Support**: [support@resend.com](mailto:support@resend.com)
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Flutter Docs**: [flutter.dev/docs](https://flutter.dev/docs)

---

## Completion Checklist

Print this section and check off each step:

```
Key Rotation Completion Checklist
==================================

GENERATION PHASE:
☐ New Groq key generated (gsk_...)
☐ New Resend key generated (re_...)
☐ New OCR key generated
☐ Old keys noted and ready for deletion

DEPLOYMENT PHASE:
☐ Groq key added to Supabase secrets
☐ Resend key added to Supabase secrets
☐ OCR key added to Supabase secrets
☐ All secrets showing green checkmark ✅

VERIFICATION PHASE:
☐ Edge Functions can access secrets
☐ Unit tests passing (flutter test)
☐ Integration tests passing (flutter test)
☐ Groq LLM working in app
☐ Email sending working
☐ OCR receipt scanning working

CLEANUP PHASE:
☐ Old Groq key deleted from Groq dashboard
☐ Old Resend key deleted from Resend dashboard
☐ Old OCR key deleted from OCR provider
☐ Git history cleaned (BFG Repo Cleaner)
☐ Incident documented in SECURITY_INCIDENTS.md

FINAL VERIFICATION:
☐ No API keys visible in browser DevTools
☐ No API keys in git history
☐ All 3 services working with new keys
☐ Team notified of rotation completion
☐ Backup of new keys stored securely

COMPLETION DATE: _______________
COMPLETED BY: _______________
VERIFICATION: _______________
```

**Last Updated**: January 1, 2026
**Next Review**: April 1, 2026 (quarterly security audit)
