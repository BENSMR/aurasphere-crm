# 🧪 AURA SPHERE FEATURE TEST CHECKLIST

**Date**: January 6, 2026  
**Test Environment**: http://localhost:8000/home  
**Status**: LIVE TESTING

---

## ✅ FEATURE 1: REAL-TIME SYNC

### What to Test:
Real-time updates for jobs, invoices, and team activity using Supabase PostgreSQL subscriptions

### How to Test:
1. **Open the app in 2 browser tabs** side-by-side
2. **In Tab 1**: Create a new job or invoice
3. **In Tab 2**: Watch for instant updates without refresh
4. Check browser console (F12) for "listenToJobs" logs

### Expected Results:
- [ ] Job appears in Tab 2 immediately
- [ ] No page refresh needed
- [ ] Console shows subscription active
- [ ] Team activity updates in real-time

---

## ✅ FEATURE 2: WHITE-LABEL CUSTOMIZATION

### What to Test:
Custom domains, branding colors, logos per organization

### How to Test:
1. Look for **Settings** or **Branding** section
2. Try changing:
   - Primary color (currently #007BFF)
   - Logo/Brand image
   - Organization name
3. Check if changes persist

### Expected Results:
- [ ] Color picker shows #007BFF (Electric Blue)
- [ ] Can upload custom logo
- [ ] Changes apply to header/footer
- [ ] Custom domain field visible (for production)

---

## ✅ FEATURE 3: AES-256 ENCRYPTION

### What to Test:
Sensitive data encryption using AES-256-CBC with secure key storage

### How to Test:
1. Create an **Invoice** with sensitive data
2. Open browser DevTools → **Application** tab
3. Check **Local Storage** / **IndexedDB**
4. Look for encrypted data (should be garbled, not readable)

### Expected Results:
- [ ] Sensitive fields are encrypted in storage
- [ ] Data is unreadable in console/storage viewer
- [ ] Invoices display correctly on page (decrypted)
- [ ] No plaintext passwords/API keys in storage

---

## ✅ FEATURE 4: AUTOMATED BACKUPS

### What to Test:
Cloud backups with encryption and retention policies

### How to Test:
1. Look for **Settings** → **Backups** section
2. Click **"Trigger Manual Backup"** if available
3. Check backup history/logs
4. Verify backup appears in list

### Expected Results:
- [ ] Backup button visible and clickable
- [ ] Backup status changes (pending → completed)
- [ ] Backup timestamp shows creation time
- [ ] Can see backup size and retention policy
- [ ] Option to restore from backup visible

---

## ✅ FEATURE 5: RATE LIMITING & BRUTE-FORCE PROTECTION

### What to Test:
Login throttling, IP reputation, 30-min lockout after 5 failed attempts

### How to Test:
1. **Optional**: Try signing in with wrong password 6 times
2. On 6th attempt, should see lockout message
3. Check if you can try again after 30 minutes (or demo bypass)

### Expected Results:
- [ ] Counter shows "Attempt X/5"
- [ ] After 5 failed attempts: "Account locked for 30 minutes"
- [ ] IP reputation checking active (in logs)
- [ ] Lockout persists across page refreshes

---

## 📊 DASHBOARD FEATURES TO CHECK

### Navigation
- [ ] **Dashboard** - Overview metrics visible
- [ ] **Jobs** - Job list loads (create, edit, delete)
- [ ] **Invoices** - Invoice list loads (create, email, download)
- [ ] **Clients** - Client database accessible
- [ ] **Calendar** - Job scheduling view
- [ ] **Team** - Team members list
- [ ] **Dispatch** - Job assignment interface
- [ ] **Inventory** - Stock tracking
- [ ] **Expenses** - Cost tracking
- [ ] **Reports** - Business analytics
- [ ] **Settings** - Account settings accessible

### Responsive Design
- [ ] Desktop view (1200px+) - Full featured
- [ ] Tablet view (600px-1200px) - Optimized layout
- [ ] Mobile view (<600px) - Mobile navigation works
- [ ] Sidebar collapses on mobile
- [ ] All buttons accessible on mobile

### UI/UX Quality
- [ ] Color scheme matches #007BFF (Electric Blue)
- [ ] Material Design 3 components visible
- [ ] Smooth animations between pages
- [ ] No console errors (F12 → Console)
- [ ] Loading states visible
- [ ] Error messages clear and helpful

---

## 🔧 TECHNICAL CHECKS

### Performance
- [ ] Page loads in < 3 seconds
- [ ] Navigation feels smooth (60 FPS)
- [ ] No memory leaks in console
- [ ] Network tab shows minimal requests

### Security
- [ ] No sensitive data in localStorage (plaintext)
- [ ] API calls use HTTPS (in production)
- [ ] RLS policies enforced (org_id filtering)
- [ ] CORS headers correct

### Browser Compatibility
- [ ] Chrome ✅
- [ ] Firefox ✅
- [ ] Safari ✅
- [ ] Edge ✅

---

## 📝 TEST RESULTS

### Date: ___________

### Feature Status:
- [ ] Real-Time Sync: **PASS** / **FAIL** / **PARTIAL**
- [ ] White-Label: **PASS** / **FAIL** / **PARTIAL**
- [ ] Encryption: **PASS** / **FAIL** / **PARTIAL**
- [ ] Backups: **PASS** / **FAIL** / **PARTIAL**
- [ ] Rate Limiting: **PASS** / **FAIL** / **PARTIAL**

### Overall Score: _____ / 5 Features

### Issues Found:
1. _____________________________
2. _____________________________
3. _____________________________

### Ready for Production: **YES** / **NO**

---

## 🚀 NEXT STEPS

### If All Tests Pass ✅
1. Deploy Edge Functions
2. Deploy to production
3. Enable real Supabase auth
4. Enable storage bucket

### If Issues Found ❌
1. Document each issue
2. Provide error details
3. Check browser console (F12)
4. Report back with error messages

---

## 📱 BROWSER CONSOLE COMMANDS

Test features from console (F12 → Console):

```javascript
// Check real-time connection
localStorage.getItem('sb-session')

// Test encryption
console.log(localStorage)

// Check build info
window.version

// Clear all data
localStorage.clear()
```

---

## ✨ SUCCESS CRITERIA

**All 5 Features Working**: 🟢 PRODUCTION READY  
**4 Features Working**: 🟡 STAGING READY  
**< 4 Features**: 🔴 NEEDS FIXES  

---

**Start testing and report findings!**

