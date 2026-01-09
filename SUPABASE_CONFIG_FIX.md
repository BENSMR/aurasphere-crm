# 🔧 Fix Supabase Auth Configuration

## Problem
Getting `authRetryableFetchException` with `xmlhttprequest error statusCode null`

## Root Cause
Your Supabase project **doesn't allow localhost:8000 redirect URLs**

## Solution

### Step 1: Go to Supabase Dashboard
1. Visit: https://app.supabase.com
2. Sign in with your account
3. Select your project: **AuraSphere** (igkvgrvrdpbmunxwhkax)

### Step 2: Configure Redirect URLs
1. Click **Authentication** (left sidebar)
2. Click **URL Configuration**
3. Under **Redirect URLs**, add:
   ```
   http://localhost:8000
   http://localhost:8000/
   http://localhost:3000
   http://localhost:5173
   ```

4. Click **Save**

### Step 3: (Optional) Test with Demo Account
If you don't have a test account:
1. Go back to **Users** tab
2. Click **Invite user**
3. Email: `test@example.com`
4. Click **Send invite**
5. Use that email to sign in

---

## After Fixing Supabase Settings

1. **Refresh the app** in your browser (Ctrl+R or Cmd+R)
2. Try signing in again
3. It should work without "Demo Mode"

---

## Alternative: Use Demo Mode (For Testing)

If you want to test the app without Supabase auth:
- Click **Sign In** again after auth error
- It will auto-enable **Demo Mode** and take you to Dashboard

Demo Mode lets you:
- ✅ View all features
- ✅ Test navigation
- ✅ Check UI/UX

But won't have:
- ❌ Real data persistence
- ❌ Real authentication
- ❌ Database access

---

## Verify Configuration

After adding redirect URLs, you can verify:

```bash
# Check Supabase project details
curl https://igkvgrvrdpbmunxwhkax.supabase.co/rest/v1/health -H "Authorization: Bearer <your_token>"
```

Should return `200 OK`

---

## Still Having Issues?

**Try these steps:**
1. Clear browser cache (Ctrl+Shift+Delete)
2. Clear localStorage: Open DevTools → Console → `localStorage.clear()`
3. Refresh: Ctrl+R
4. Try signing in again

If still failing:
- Check browser console (F12) for exact error
- Share the error message and I'll debug further

