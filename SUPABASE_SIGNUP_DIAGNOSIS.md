# Supabase 401 Auth Diagnostic Checklist

**Status**: 🔍 Use this checklist to diagnose signup failures
**Project**: fppmuibvpxrkwmymszhd
**URL**: https://fppmuibvpxrkwmymszhd.supabase.co

---

## Quick Start: Test Signup in Browser

### Step 1: Prepare Test File
1. Open `signup-test.html` in your text editor
2. Replace `YOUR_EMAIL` with a test email (e.g., `test@example.com`)
3. Replace `YOUR_PASSWORD` with a secure test password
4. Save the file

### Step 2: Run Test
1. Open `signup-test.html` in your browser (File → Open or drag into tab)
2. Click **Sign Up** button
3. Check the **Response** section for success/error

### Step 3: Interpret Results

**✅ Success Response** (user account created):
```json
{
  "step": "signUp",
  "status": "success",
  "data": {
    "user": { "id": "...", "email": "..." },
    "session": { "access_token": "..." }
  }
}
```

**❌ 401 Error** (authentication failed):
```json
{
  "step": "signUp",
  "status": "error",
  "error": {
    "name": "AuthApiError",
    "message": "Invalid API key or CORS policy",
    "status": 401
  }
}
```

---

## Supabase Dashboard Configuration Checklist

### ✅ 1. Email Provider (Authentication → Providers)

- [ ] **Email provider is ENABLED**
  - Supabase Dashboard → Authentication → Providers → Email
  - Status should show "Enabled"

- [ ] **"Disable email signups" is OFF**
  - Authentication → Settings → User Signups
  - Checkbox "Disable email signups" must be **unchecked**

- [ ] **Email template is configured** (optional but recommended)
  - Authentication → Email Templates
  - Check "Confirm signup" template exists

### ✅ 2. CORS Configuration (Authentication → Settings)

- [ ] **Add your development domain to CORS**
  - Authentication → Settings → CORS Allowed Origins
  - Add: `http://localhost:5173` (if using Vite)
  - Add: `http://localhost:3000` (if using Node)
  - Add: `http://localhost:8000` (if using Python)
  - Add: `file://` (for local HTML file test)

- [ ] **Add your production domain**
  - Add your actual domain (e.g., `https://aurasphere.io`)

- [ ] **Verify origin format**
  - Must include protocol: `http://` or `https://`
  - No trailing slash
  - Wildcard subdomains not typically recommended for security

### ✅ 3. URL Configuration (Authentication → URL Configuration)

- [ ] **Site URL is set correctly**
  - Site URL: Your app's base URL
  - Examples:
    - Dev: `http://localhost:5173`
    - Prod: `https://aurasphere.io`

- [ ] **Redirect URLs are configured**
  - If using auth callbacks, add all redirect URLs
  - Examples:
    - `http://localhost:5173/auth/callback`
    - `https://aurasphere.io/auth/callback`

### ✅ 4. API Keys (Settings → API)

- [ ] **Verify anon key matches your test**
  - Expected: `sb_publishable_4VwBnvN5rzp6oKvOPCtacA_-7YaVWXR`
  - Used in: `signup-test.html`, Flutter app
  - Safe to expose in browser/client code

- [ ] **Service Role key is secure**
  - Only use on backend servers
  - Keep in `.env` file (never in version control)
  - Never expose in Flutter, browser, or client code

- [ ] **API URL is correct**
  - Expected: `https://fppmuibvpxrkwmymszhd.supabase.co`
  - Must use HTTPS (not HTTP)

### ✅ 5. General Auth Settings

- [ ] **JWT expiration is reasonable**
  - Authentication → Settings → JWT expiration
  - Default: 3600 seconds (1 hour)

- [ ] **Refresh token rotation is enabled** (optional but secure)
  - Authentication → Settings → Enable Refresh Token Rotation

---

## Common 401 Error Causes

| Error | Cause | Fix |
|-------|-------|-----|
| **401 Unauthorized** | Invalid anon key | Verify key in Dashboard → Settings → API |
| **401 Unauthorized** | CORS blocked | Add domain to CORS Allowed Origins |
| **401 Unauthorized** | Email provider disabled | Enable in Authentication → Providers → Email |
| **401 Unauthorized** | Signups disabled | Uncheck "Disable email signups" in Settings |
| **401 Unauthorized** | Wrong URL format | Use `https://` (not `http://`) |

---

## Step-by-Step Diagnosis

### 🔍 Test 1: Verify Credentials
```
1. Open Supabase Dashboard
2. Go to Settings → API
3. Copy exact URL and anon key
4. Paste into signup-test.html
5. Reload page and try signup
```

### 🔍 Test 2: Check Browser Network Tab
```
1. Open signup-test.html in browser
2. Open DevTools (F12 → Network tab)
3. Click Sign Up
4. Click the POST request to /auth/v1/signup
5. Check:
   - Status code (should be 200, not 401)
   - Request headers → apikey (must be present)
   - Request headers → Authorization: Bearer ... (must be present)
   - Request body → email and password (must be present)
   - Response body (error message)
```

### 🔍 Test 3: Check CORS
```
1. Look for error in browser console:
   "CORS policy: Response to preflight request doesn't pass..."
2. If you see CORS error:
   - Add domain to Supabase CORS Allowed Origins
   - Wait 30 seconds for settings to propagate
   - Refresh page and try again
```

### 🔍 Test 4: Check Auth Settings
```
1. Supabase Dashboard → Authentication
2. Verify:
   ✓ Email provider is Enabled
   ✓ "Disable email signups" is OFF
   ✓ URL Configuration has Site URL set
   ✓ CORS Allowed Origins has your domain
```

### 🔍 Test 5: Try with Server Proxy
```
1. Create .env file with your credentials
2. Run: node server.js
3. Visit: http://localhost:5174
4. Click Sign Up
5. Check response and console logs
```

---

## Advanced: Server-Side Test

If browser test fails but you want to test signup on server:

### Setup
```bash
# Copy .env.example to .env
cp .env.example .env

# Edit .env with your credentials
# SUPABASE_URL=https://...
# SUPABASE_ANON_KEY=...
# SUPABASE_SERVICE_ROLE_KEY=...

# Install dependencies
npm install express node-fetch dotenv

# Run server
node server.js
```

### Test Endpoints
```bash
# Health check
curl http://localhost:5174/health

# Check configuration
curl http://localhost:5174/config

# Test signup via proxy
curl -X POST http://localhost:5174/api/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPassword123!"}'

# Admin create user (requires service role key)
curl -X POST http://localhost:5174/admin/create-user \
  -H "Content-Type: application/json" \
  -d '{"email":"admin-test@example.com","password":"TestPassword123!"}'
```

---

## Troubleshooting: If Signup Still Fails

### 1. Share the Error JSON
```
From signup-test.html Response section, copy the JSON:
{
  "step": "signUp",
  "status": "error",
  "error": {
    "name": "...",
    "message": "...",
    "status": 401
  }
}
```

### 2. Check Browser Console
```
DevTools → Console (F12)
Look for:
- Red error messages
- CORS warnings
- 401 response details
```

### 3. Check Network Request
```
DevTools → Network → POST /auth/v1/signup
Check:
- Request URL: https://fppmuibvpxrkwmymszhd.supabase.co/auth/v1/signup
- Request Headers:
  apikey: sb_publishable_...
  Authorization: Bearer sb_publishable_...
  Content-Type: application/json
- Request Body:
  {"email":"...","password":"..."}
- Response Status: (should be 200 or 422, not 401)
- Response Body: (error details)
```

### 4. Check Supabase Logs
```
Supabase Dashboard → Auth → Logs
Look for your signup attempt with:
- Timestamp matching your test time
- Error message details
- Request/response details
```

---

## Files Included

- **`signup-test.html`** - Browser-based signup test (no server needed)
- **`server.js`** - Express server for testing (optional)
- **`.env.example`** - Template for environment variables

---

## Next Steps After Successful Test

1. **If signup succeeds** ✅
   - Your Supabase auth is working
   - Update your Flutter app with the same URL/key
   - Test signup in Flutter

2. **If signup fails** ❌
   - Follow diagnosis steps above
   - Check Dashboard settings
   - Review error message from Response/Console
   - Share error JSON for debugging

---

## References

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [CORS Configuration Guide](https://supabase.com/docs/guides/auth#authentication-cors)
- [API Reference - Auth](https://supabase.com/docs/reference/auth/sign-up)

---

**Last Updated**: January 15, 2026
**Project**: AuraSphere CRM
**Troubleshooting Guide v1.0**
