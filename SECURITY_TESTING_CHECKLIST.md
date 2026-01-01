# Security Features Testing Checklist

## Pre-Test Setup

- [ ] Build the app: `flutter clean ; flutter pub get ; flutter build web --release`
- [ ] Verify build succeeds: `flutter build web 2>&1 | grep "Built"`
- [ ] Open the app in browser: `http://localhost:8080`
- [ ] Open Developer Tools: Press `F12`

---

## 1. Input Validation Tests

### 1.1 Email Validation
- [ ] Go to Sign In page
- [ ] Try invalid emails and verify error messages appear:
  - [ ] `invalid` → Error: "Invalid email format"
  - [ ] `user@` → Error: "Invalid email format"
  - [ ] `@domain.com` → Error: "Invalid email format"
  - [ ] `user @domain.com` (with space) → Error: "Invalid email format"
- [ ] Try valid email: `test@example.com` → No error, form accepts it

### 1.2 Password Validation (Sign Up)
- [ ] Go to Sign Up page
- [ ] Try weak passwords and verify error messages:
  - [ ] `weak` → Error: "Password must be at least 8 characters"
  - [ ] `NoNumbers!` → Error: "Password must contain at least one number"
  - [ ] `nocaps123!` → Error: "Password must contain uppercase letters"
  - [ ] `NOLOWER123!` → Error: "Password must contain lowercase letters"
  - [ ] `NoSpecial123` → Error: "Password must contain special characters (!@#$%^&*)"
- [ ] Try strong password: `SecurePass123!` → No error, form accepts it

### 1.3 Password Strength Indicator (Sign Up)
- [ ] Observe password strength meter while typing:
  - [ ] Weak password (< 8 chars) → Red indicator
  - [ ] Medium password (8+ chars, 2-3 requirements) → Yellow indicator
  - [ ] Strong password (all requirements) → Green indicator

### 1.4 Phone Number Validation
- [ ] If app has phone field, try:
  - [ ] `12345` → Error: "Invalid phone number"
  - [ ] `abc123456789` → Error: "Invalid phone number"
  - [ ] `1234567890` (no +) → Error: "Invalid phone number"
  - [ ] `+1234567890` → Accepted ✅

### 1.5 Name Validation
- [ ] If app has name field, try:
  - [ ] `John123` → Error: "Name can only contain letters, spaces, hyphens, and apostrophes"
  - [ ] `Jane@Doe` → Error: "Name can only contain letters, spaces, hyphens, and apostrophes"
  - [ ] `John Doe` → Accepted ✅
  - [ ] `Mary-Jane` → Accepted ✅
  - [ ] `O'Brien` → Accepted ✅

---

## 2. Rate Limiting Tests

### 2.1 Email-Based Rate Limiting
1. Go to Sign In page
2. Try to login with a test email (e.g., `ratetest@example.com`) with wrong password
3. **Count failed attempts**:
   - [ ] Attempt 1 (wrong password) → Login fails, error message appears
   - [ ] Attempt 2 (wrong password) → Login fails
   - [ ] Attempt 3 (wrong password) → Login fails
   - [ ] Attempt 4 (wrong password) → Login fails
   - [ ] Attempt 5 (wrong password) → Login fails
   - [ ] **Attempt 6 (wrong password)** → 🔒 **ERROR**: "Too many login attempts. Try again in 5 minutes."

### 2.2 Clearing Rate Limit on Success
1. Create an account: `newuser123@example.com` / `SecurePass123!`
2. Login successfully with the new account
3. Logout
4. **Attempt 5 failed logins** with this email
5. **On 6th attempt** → Should be blocked as usual ✅

### 2.3 IP-Based Rate Limiting
1. Try logging in from the same browser IP address with **10 different email addresses** using wrong passwords
2. **On the 11th attempt** → 🔒 **ERROR**: "Too many login attempts from this location. Try again in 5 minutes."

### 2.4 Rate Limit Recovery
1. Trigger rate limit (block email or IP)
2. Wait 5 minutes
3. Try logging in again with correct credentials
4. Should succeed ✅

---

## 3. Authentication State Checking

### 3.1 Auth State in Protected Pages
1. **Without logging in**:
   - [ ] Go directly to `/dashboard` → Redirects to `/` (sign in page) ✅
   - [ ] Go directly to `/jobs` → Redirects to `/` ✅
   - [ ] Go directly to `/invoices` → Redirects to `/` ✅
   - [ ] Go directly to `/clients` → Redirects to `/` ✅
   - [ ] Go directly to `/team` → Redirects to `/` ✅

2. **After logging in**:
   - [ ] Go to `/dashboard` → Shows dashboard (no redirect) ✅
   - [ ] Go to `/jobs` → Shows jobs list ✅
   - [ ] Go to `/invoices` → Shows invoices ✅
   - [ ] Navigate between pages → No redirects (auth state verified) ✅

### 3.2 Session Persistence
1. Login to the app
2. Refresh the page (F5)
3. Should remain logged in ✅ (not redirected to sign in)
4. Check browser localStorage: `Inspect → Application → Local Storage`
   - [ ] Should contain Supabase session token
   - [ ] Token should NOT contain raw API keys ✅

### 3.3 Logout Functionality
1. Login to the app
2. Click Logout (typically in menu)
3. Should redirect to sign in page (`/`)
4. Go back to protected page (e.g., `/dashboard`)
5. Should redirect to `/` (not authenticated) ✅

---

## 4. API Key Security Tests

### 4.1 Frontend Code Verification
1. Go to browser Developer Tools (F12)
2. **Check Network tab**:
   - [ ] Filter for "groq" → No requests with GROQ_API_KEY in URL
   - [ ] Filter for "resend" → No requests with RESEND_API_KEY in URL
   - [ ] Filter for "ocr" → No requests with OCR_API_KEY in URL
   - [ ] Filter for "supabase" → Should see calls to `supabase.co` domain ✅

3. **Check Console**:
   - [ ] No error messages showing "API key"
   - [ ] No warnings about exposed secrets

### 4.2 Local Storage Inspection
1. Open Developer Tools → **Application** tab
2. Go to **Local Storage** → Select your domain
3. Check `GROQ_API_KEY` in storage:
   - [ ] Should NOT exist ✅
   - [ ] Should NOT contain raw key ✅
4. Check `RESEND_API_KEY`:
   - [ ] Should NOT exist ✅
5. Check `OCR_API_KEY`:
   - [ ] Should NOT exist ✅

### 4.3 Git History Check
1. Open terminal in project folder
2. Search git history for exposed keys:
   ```bash
   git log --all --full-history -p | grep -i "GROQ_API_KEY\|RESEND_API_KEY\|OCR_API_KEY" | head -5
   ```
3. Should show **removed** entries (keys were deleted) ✅

---

## 5. Backend API Proxy Tests

### 5.1 Groq LLM Integration
1. Go to **Dashboard** → **Aura Chat** (if available)
2. Type command: `Send invoice to John Doe`
3. **Expected behavior**:
   - [ ] No API errors in console
   - [ ] Command parsed correctly
   - [ ] Response generated ✅
4. Check browser console: `Ctrl+Shift+K`
   - [ ] No 401/403 errors ✅
   - [ ] No "Unauthorized" messages ✅

### 5.2 Email Sending
1. Go to **Invoices** → Select an invoice
2. Click **"Send Invoice"** button
3. Enter recipient email (can be your own test email)
4. Click **"Send"**
5. **Expected behavior**:
   - [ ] Form submits without errors
   - [ ] Success message: "Invoice sent successfully"
   - [ ] Email arrives within 60 seconds ✅
6. Check browser console:
   - [ ] No 401/403 errors ✅
   - [ ] No "API key" errors ✅

### 5.3 Receipt OCR (If Available)
1. Go to **Expenses** → **Add Expense**
2. Click **"Scan Receipt"** button
3. Upload an image of a receipt (or test image)
4. **Expected behavior**:
   - [ ] Image processes without errors
   - [ ] Extracted data shows in form (amount, date, vendor, etc.)
   - [ ] No OCR-related errors ✅
5. Check browser console:
   - [ ] No 401/403 errors ✅
   - [ ] No "API key" errors ✅

---

## 6. Row-Level Security (RLS) Tests

### 6.1 Organization Data Isolation
1. Create two test accounts:
   - Account A: `usera@example.com` / `SecurePass123!`
   - Account B: `userb@example.com` / `SecurePass123!`

2. **Login as Account A**:
   - [ ] Create a client named "Client A"
   - [ ] Create an invoice for Client A
   - [ ] Go to Clients page → Should see "Client A" ✅

3. **Logout, then login as Account B**:
   - [ ] Go to Clients page
   - [ ] Should NOT see "Client A" (belongs to Account A's org) ✅
   - [ ] Create your own client: "Client B"
   - [ ] Go to Clients page → Should see only "Client B" ✅

4. **Check browser DevTools → Network**:
   - [ ] Database queries show no error messages
   - [ ] RLS policies are silently enforcing access ✅

### 6.2 Job Assignment Isolation
1. Using Account A:
   - [ ] Create a job "Job A"
   - [ ] View job list → Should see "Job A" ✅

2. Login as Account B:
   - [ ] View job list → Should NOT see "Job A" ✅
   - [ ] Create "Job B"

3. Go back to Account A:
   - [ ] Refresh job list → Still only sees "Job A" ✅

---

## 7. XSS Protection Tests

### 7.1 Script Injection Prevention
1. Go to any form that accepts text (e.g., client name)
2. Try to enter: `<script>alert('XSS')</script>`
3. **Expected behavior**:
   - [ ] Script tags are removed or escaped
   - [ ] No alert box appears ✅
   - [ ] Form shows sanitized text

### 7.2 Event Handler Injection
1. Try to enter: `<img src=x onerror="alert('XSS')">`
2. **Expected behavior**:
   - [ ] Event handler is removed
   - [ ] No alert box appears ✅
   - [ ] HTML is sanitized

### 7.3 Comment Injection
1. Try to enter: `<!-- comment -->`
2. Should be sanitized and stored safely ✅

---

## 8. Encryption Tests

### 8.1 Data Encryption in Transit
1. Go to network tab in DevTools
2. Perform any login or data submission
3. **Check HTTPS**:
   - [ ] All requests to `supabase.co` use HTTPS ✅
   - [ ] All requests to Edge Functions use HTTPS ✅
   - [ ] Padlock icon shows in browser address bar ✅

### 8.2 Sensitive Data Not in Logs
1. Open browser console: `F12 → Console`
2. Perform a login
3. Check console output:
   - [ ] No password visible in logs ✅
   - [ ] No API keys visible ✅
   - [ ] Only safe debug messages visible ✅

---

## 9. End-to-End Security Flow Test

### Complete Scenario
1. **Sign Up** with strong password
   - [ ] Email validation ✅
   - [ ] Password strength validation ✅
   - [ ] Account created ✅

2. **Login with Rate Limiting**
   - [ ] Try wrong password 5 times
   - [ ] 6th attempt blocked ✅
   - [ ] Login with correct password ✅

3. **Access Protected Pages**
   - [ ] Dashboard loads without redirect ✅
   - [ ] Can access Jobs, Invoices, Clients ✅

4. **Create Data with RLS**
   - [ ] Create a client
   - [ ] Create an invoice
   - [ ] Data belongs to your organization ✅

5. **Use LLM Features** (if available)
   - [ ] Chat with Aura AI ✅
   - [ ] No API errors ✅

6. **Logout and Verify Auth State**
   - [ ] Logout successful
   - [ ] Cannot access protected pages without re-login ✅
   - [ ] Redirected to sign in page ✅

---

## 10. Performance & Load Tests

### 10.1 Build Performance
```bash
flutter build web --release
```
- [ ] Build completes successfully
- [ ] Build time: < 3 minutes
- [ ] Output size: < 20MB

### 10.2 App Performance
1. Open app in browser
2. Check Performance tab (DevTools):
   - [ ] First Meaningful Paint (FMP): < 3 seconds
   - [ ] Time to Interactive (TTI): < 5 seconds

### 10.3 Network Performance
1. Open Network tab (DevTools)
2. Login and navigate through app
3. Check:
   - [ ] API responses: < 500ms average
   - [ ] Edge Function calls: < 1000ms average

---

## Reporting Issues

If any test **FAILS**, document:

```markdown
### Failed Test Report

**Date**: [Date]
**Test Name**: [Which test failed]
**Steps to Reproduce**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happened]
**Error Message**: [Any console errors]
**Severity**: [Critical/High/Medium/Low]
**Recommendation**: [How to fix]
```

---

## Sign-Off Checklist

All tests completed? Fill in:

```
SECURITY TESTING COMPLETION SIGN-OFF
=====================================

Date Completed: _______________
Tester Name: _______________
Test Environment: _______________

Test Results:
☐ Input Validation: PASS
☐ Rate Limiting: PASS
☐ Auth State Checking: PASS
☐ API Key Security: PASS
☐ Backend Proxy: PASS
☐ Row-Level Security: PASS
☐ XSS Protection: PASS
☐ Encryption: PASS
☐ End-to-End Flow: PASS
☐ Performance: PASS

Overall Status: ✅ ALL TESTS PASSED
Production Ready: YES ✅

Signed By: _______________
Date: _______________
```

---

**Test Suite Version**: 1.0
**Last Updated**: January 1, 2026
**Framework**: Flutter Web
**Build Version**: Production Release
