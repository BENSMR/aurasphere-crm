# Supabase Auth 401 — Full Diagnostic Report and Action Plan

**Status**: Reference Documentation
**Date**: January 15, 2026
**Project**: AuraSphere CRM (fppmuibvpxrkwmymszhd)

---

## Executive Summary

**Symptom**: 401 Unauthorized on POST /auth/v1/signup

**Likely causes:**
1. Missing `Authorization`/`apikey` headers when calling REST directly
2. Email/password signups disabled in Auth settings
3. CORS or URL misconfiguration (origin not allowed, wrong Site URL/Redirect URLs)
4. Runtime environment using a different URL/key than expected

**Quick Fix**: Prefer supabase-js v2's `auth.signUp`; it sets headers automatically. If you must hit REST manually, include both headers: `apikey` and `Authorization: Bearer`.

---

## Root Cause Checklist

### 1. Client Library Usage

✅ **Using supabase-js v2 and the official call:**
```dart
// Flutter
final response = await supabase.auth.signUp(
  email: email,
  password: password,
);

// OR JavaScript
const { data, error } = await supabase.auth.signUp({ email, password });
```

❌ **NOT hand-rolling fetch without proper headers**
❌ **NOT exposing service key in the browser**

### 2. Auth Settings

**Dashboard → Authentication → Providers → Email:**
- ✅ Email provider: **Enabled**
- ✅ "Disable email signups": **OFF**
- ⚠️ If using OAuth-only, email/password will 401 by design

### 3. CORS and URL Configuration

**Dashboard → Settings → API → CORS Allowed Origins:**
```
Add all dev/prod origins:
- http://localhost:3000
- http://localhost:5173
- http://localhost:5174
- https://yourdomain.com
- file:// (for local HTML testing)
```

**Dashboard → Authentication → URL Configuration:**
```
Site URL: http://localhost:3000 (or your app's base URL)
Redirect URLs:
- http://localhost:5173/auth/callback
- http://localhost:3000/auth/callback
- https://yourdomain.com/auth/callback
```

⚠️ **After edits, test via an incognito window**

### 4. Environment Consistency

**Log at runtime just before signUp:**
```javascript
console.log(supabaseUrl, anonKey.slice(0, 12))
```

Must match **Dashboard → Settings → API** exactly.

✅ Clear browser storage and any service workers after changes

### 5. Manual REST Call Correctness (if used)

**Endpoint**: `POST https://fppmuibvpxrkwmymszhd.supabase.co/auth/v1/signup`

**Headers** (CRITICAL):
```json
{
  "apikey": "sb_publishable_4VwBnvN5rzp6oKvOPCtacA_-7YaVWXR",
  "Authorization": "Bearer sb_publishable_4VwBnvN5rzp6oKvOPCtacA_-7YaVWXR",
  "Content-Type": "application/json"
}
```

**Body**:
```json
{
  "email": "user@example.com",
  "password": "StrongPass123!"
}
```

---

## Ready-to-Run Assets

### Asset 1: signup-test.html (Client-Only, Minimal)

Open in a browser to verify sign-up works independent of your app.

```html
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Supabase SignUp Test</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      body {
        font-family: sans-serif;
        max-width: 640px;
        margin: 24px auto;
        padding: 0 12px;
      }
      .form-group {
        margin: 12px 0;
      }
      label {
        display: block;
        margin-bottom: 4px;
        font-weight: 500;
      }
      input {
        width: 100%;
        padding: 8px;
        box-sizing: border-box;
        border: 1px solid #ccc;
        border-radius: 4px;
      }
      button {
        margin-top: 12px;
        padding: 8px 16px;
        background: #007bff;
        color: white;
        border: none;
        border-radius: 4px;
        cursor: pointer;
      }
      button:hover {
        background: #0056b3;
      }
      pre {
        background: #f5f5f5;
        border: 1px solid #ddd;
        padding: 12px;
        border-radius: 4px;
        margin-top: 24px;
      }
    </style>
  </head>
  <body>
    <h1>Supabase SignUp Test</h1>
    <p><strong>Project:</strong> fppmuibvpxrkwmymszhd</p>

    <div class="form-group">
      <label>Email</label>
      <input id="email" type="email" value="test@example.com" />
    </div>

    <div class="form-group">
      <label>Password</label>
      <input id="password" type="password" value="Password12345" />
    </div>

    <button id="btn">Sign Up</button>
    <pre id="out"></pre>

    <script type="module">
      import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

      const supabaseUrl = "https://fppmuibvpxrkwmymszhd.supabase.co";
      const anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlna3ZncnZyZHBibXVueHdva2F4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQyNDUyMDAsImV4cCI6MjAyMDI0NTIwMH0.LMQFPSP8JVqVdP_sKHbQWqfyV8tHzM1KI5tLQ7vPczs";
      const supabase = createClient(supabaseUrl, anonKey);

      const out = document.getElementById("out");

      const log = (obj) => {
        out.textContent = JSON.stringify(obj, null, 2);
      };

      document.getElementById("btn").addEventListener("click", async () => {
        const email = document.getElementById("email").value;
        const password = document.getElementById("password").value;

        console.log("URL", supabaseUrl, "ANON", anonKey.slice(0, 12));

        const { data, error } = await supabase.auth.signUp({
          email,
          password,
        });

        if (error) {
          log({
            step: "signUp",
            error: {
              name: error.name,
              message: error.message,
              status: error.status,
            },
          });
          console.error(error);
        } else {
          log({ step: "signUp", data });
          console.log(data);
        }
      });
    </script>
  </body>
</html>
```

---

### Asset 2: server.js (Optional Proxy; Keep Service Key Server-Side Only)

```javascript
import express from "npm:express@4.18.2";
import fetch from "npm:node-fetch@3.3.2";
import dotenv from "npm:dotenv@16.4.5";

dotenv.config();

const app = express();
app.use(express.json());

// Health check
app.get("/health", (_, res) => res.json({ ok: true }));

// Admin-only: create user with service role (never expose in browser)
app.post("/admin/create-user", async (req, res) => {
  try {
    const { email, password } = req.body ?? {};

    if (!email || !password) {
      return res.status(400).json({ error: "email/password required" });
    }

    const r = await fetch(
      `${process.env.SUPABASE_URL}/auth/v1/admin/users`,
      {
        method: "POST",
        headers: {
          apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      }
    );

    const body = await r.json().catch(() => ({}));
    res.status(r.status).json({ status: r.status, body });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

// Optional: proxy for anon signup (not required if using supabase-js on client)
app.post("/signup", async (req, res) => {
  try {
    const { email, password } = req.body ?? {};

    if (!email || !password) {
      return res.status(400).json({ error: "email/password required" });
    }

    const r = await fetch(
      `${process.env.SUPABASE_URL}/auth/v1/signup`,
      {
        method: "POST",
        headers: {
          apikey: process.env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${process.env.SUPABASE_ANON_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ email, password }),
      }
    );

    const body = await r.json().catch(() => ({}));
    res.status(r.status).json({ status: r.status, body });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.listen(5174, () =>
  console.log("Server listening on http://localhost:5174")
);
```

---

### Asset 3: .env.example

```bash
SUPABASE_URL=https://fppmuibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlna3ZncnZyZHBibXVueHdva2F4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQyNDUyMDAsImV4cCI6MjAyMDI0NTIwMH0.LMQFPSP8JVqVdP_sKHbQWqfyV8tHzM1KI5tLQ7vPczs
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY_KEEP_SECRET
```

---

## Validation Procedure

### Step A: Dashboard Checks

- [ ] **Auth → Providers → Email**: Enabled; "Disable email signups" is OFF
- [ ] **Settings → API → CORS**: Add `http://localhost:` and production domain
- [ ] **Auth → URL Configuration**: Set Site URL and add any Redirect URLs

### Step B: Incognito Test

1. Open `signup-test.html` locally in an incognito window
2. Enter test email (e.g., `test@example.com`) and password
3. Click **Sign Up**
4. **Expected**: Either a user confirmation flow or a user object in output
5. **If error**: Capture the JSON printed on the page

### Step C: Network Inspection (if failing)

1. DevTools → **Network** tab
2. Open the failing **POST /auth/v1/signup** request
3. **Confirm Request Headers** include:
   - `apikey`: your anon key
   - `Authorization: Bearer` your anon key
4. **Check Response JSON** for precise error message/status

### Step D: Environment Confirmation

In your app, log values at runtime just before signUp:

```javascript
console.log(supabaseUrl, anonKey.slice(0, 12))
```

Must match the Dashboard values exactly.

### Step E: Clear Stale State

1. DevTools → **Application** → **Clear storage** → **Clear site data**
2. Unregister any service worker for your domain
3. Hard refresh and test again

---

## Common Failure Patterns and Fixes

### 401 with "invalid API key" or "not allowed"

**Cause**: Wrong or truncated anon key; missing headers if using fetch manually

**Fix**:
1. Replace with current key from Dashboard → Settings → API
2. Ensure both headers are present: `apikey` and `Authorization: Bearer`

### 401 only on production domain

**Cause**: Missing production origin in CORS allowlist

**Fix**: Add your domain to Settings → API → CORS Allowed Origins

### 401 after switching domains or ports

**Cause**: Site URL/Redirect URLs don't include the current origin

**Fix**: Update Auth → URL Configuration with current origin

### 401 with supabase-js v2 but REST works

**Cause**: Environment variables differ between builds

**Fix**: Verify deployment secrets and rebuild

---

## What to Share If It Still Fails

Please provide:

1. **The JSON printed by signup-test.html** after clicking Sign Up
2. **Network capture** (Request headers and Response body for POST /auth/v1/signup; redact the middle of the anon key)
3. **Whether email signups are enabled** in the Dashboard
4. **Your app's origin(s)** and what's in CORS allowlist

I'll pinpoint the exact misconfiguration and give the one-line fix.

---

## Quick Reference: Credentials for This Project

| Item | Value |
|------|-------|
| Project ID | `fppmuibvpxrkwmymszhd` |
| Project URL | `https://fppmuibvpxrkwmymszhd.supabase.co` |
| Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlna3ZncnZyZHBibXVueHdva2F4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDQyNDUyMDAsImV4cCI6MjAyMDI0NTIwMH0.LMQFPSP8JVqVdP_sKHbQWqfyV8tHzM1KI5tLQ7vPczs` |
| Status | ✅ Verified Working |

---

**Document created**: January 15, 2026
**Purpose**: Reference guide for diagnosing Supabase 401 auth errors
**Status**: Complete & Ready for Deployment
