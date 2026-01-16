# 🔍 Supabase 401 Error - Diagnostic Checklist

**Updated**: January 15, 2026  
**Status**: Ready for diagnosis

## Step 1: Run the App & Capture Diagnostic Output

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Wait 30 seconds for the app to load, then open **DevTools Console** (F12 → Console tab).

You should see output like:
```
✅ Supabase initialized successfully
🔍 DIAGNOSTIC: Runtime Supabase Config
   URL: https://fppmuibvpxrkwmymszhd.supabase.co
   apikey header (first 12): eyJhbGciOiJI
   Authorization header (first 12): eyJhbGciOiJI
   Expected (first 12): eyJhbGciOiJI
```

---

## Step 2: Get Your Supabase Dashboard Values

1. Go to **Supabase Dashboard** → **Settings** → **API**
2. Find the **Anon key** field
3. Copy the **first 12 characters** (should be: `eyJhbGciOiJI`)
4. Check if it says **"ACTIVE"** or if there's a **warning icon**

---

## Step 3: Compare & Report

**Please reply with these 4 values:**

```
1. Flutter console URL: [paste your URL]
2. Flutter console apikey (first 12): [paste from console]
3. Flutter console Authorization (first 12): [paste from console]
4. Supabase Dashboard anon key (first 12): [paste from dashboard]
```

**Example:**
```
1. https://fppmuibvpxrkwmymszhd.supabase.co
2. eyJhbGciOiJI
3. eyJhbGciOiJI
4. eyJhbGciOiJI  (from dashboard)
```

---

## Likely Scenarios & Fixes

### ✅ Scenario A: All 4 values match (e.g., all show `eyJhbGciOiJI`)
- **Status**: Credentials are correct!
- **Action**: The 401 error is likely from **RLS policies** or **Auth configuration**
- **Next Step**: Check if Supabase auth is enabled (Settings → Authentication)

### ❌ Scenario B: Dashboard value (4) differs from app values (1-3)
- **Status**: Wrong anon key in code
- **Action**: 
  1. Copy the CORRECT anon key from Supabase Dashboard
  2. Update `lib/main.dart` line 17:
     ```dart
     const supabaseAnonKey = '[PASTE NEW KEY HERE]';
     ```
  3. Run: `flutter clean && flutter pub get && flutter run -d chrome`

### ❌ Scenario C: App values (2-3) are empty or show error
- **Status**: Headers not being set properly
- **Action**: 
  1. Make sure `lib/main.dart` has the `headers:` block (lines 33-36)
  2. Run: `flutter clean && flutter run -d chrome`
  3. Check console again

### ❌ Scenario D: Authorization header shows something like `Bearer undefined`
- **Status**: Supabase key variable not loaded
- **Action**: Make sure `const supabaseAnonKey = '...'` is on line 17 in main.dart

---

## If Still Getting 401 After Step 3

Also check:
1. **Is Auth Enabled?** Dashboard → Authentication → Is it turned ON?
2. **Check RLS Policies** → Database → Tables → Select a table → RLS Policies
3. **Check Auth URL Config** → Authentication → URL Configuration (should have your domain)

---

**Once you provide the 4 values from Step 3, I'll give you the exact fix!** ✅
