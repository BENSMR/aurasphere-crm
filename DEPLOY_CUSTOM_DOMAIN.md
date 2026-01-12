# AuraSphere CRM - Deploy to aura-sphere.app

## 🚀 Step 1: Deploy to Netlify (2 minutes)

### Option A: Drag & Drop (Easiest)
1. Go to https://app.netlify.com
2. Sign in (free account)
3. Drag `build/web/` folder to deploy zone
4. Netlify gives you a **temporary URL** (e.g., `https://xxx.netlify.app`)
5. **Note this temporary URL** - we'll add your custom domain next

### Option B: Netlify CLI (Fastest)
```bash
npm install -g netlify-cli
cd "c:\Users\PC\AuraSphere\crm\aura_crm\build\web"
netlify deploy --prod
```
Returns a **Netlify site ID** - save it.

---

## 🌐 Step 2: Add Custom Domain to Netlify (3 minutes)

1. Log in to Netlify dashboard
2. Go to your site → **Settings → Domain Management**
3. Click **Add custom domain**
4. Enter: `aura-sphere.app`
5. Netlify shows you **DNS records to add**

---

## 🔗 Step 3: Update DNS at Your Registrar (2 minutes)

Your domain registrar (GoDaddy, Namecheap, etc.):

1. Go to your domain DNS settings for `aura-sphere.app`
2. Find the **DNS records** section
3. Add the records Netlify told you to add (usually 2 CNAME records):
   ```
   www  CNAME  aura-sphere.app.netlify.com
   aura-sphere.app  ALIAS/ANAME  aura-sphere.app.netlify.com
   ```
   *OR* (if no ALIAS/ANAME support):
   ```
   @  A  75.2.60.5  (IP varies - use Netlify's value)
   ```
4. **Save DNS changes** (wait 5-15 minutes for propagation)

---

## ⚙️ Step 4: Configure Supabase (5 minutes)

Once DNS propagates, configure Supabase:

### Supabase Dashboard → Auth

1. Go to https://supabase.com/dashboard
2. Select project `fppmuibvpxrkwmymszhd`
3. Go to **Settings → Authentication**
4. Update:
   - **Site URL**: `https://aura-sphere.app`
   - **Redirect URLs** (add all):
     ```
     https://aura-sphere.app
     https://www.aura-sphere.app
     https://aura-sphere.app/dashboard
     https://aura-sphere.app/home
     ```

### Supabase Dashboard → API

1. Go to **Settings → API**
2. Under **CORS**, add to Allowed Origins:
   ```
   https://aura-sphere.app
   https://www.aura-sphere.app
   ```
3. **Save**

---

## 🧪 Step 5: Test Live (2 minutes)

1. Open `https://aura-sphere.app` in your browser
2. Click **Sign Up**
3. Create test account with email
4. Should work! ✅

---

## Troubleshooting

**"Can't reach aura-sphere.app"**
- DNS not propagated yet (wait 10-15 min)
- Check DNS records at https://dnschecker.org/

**"Auth error / Unauthorized"**
- Supabase redirect URL not configured
- Clear browser cache and try again

**"Origin not allowed"**
- Missing from Supabase CORS settings
- Add to **Settings → API → CORS Allowed Origins**

---

## Project Details
- **Supabase Project**: `fppmuibvpxrkwmymszhd`
- **Supabase URL**: `https://fppmuibvpxrkwmymszhd.supabase.co`
- **Custom Domain**: `aura-sphere.app`
- **Build**: `c:\Users\PC\AuraSphere\crm\aura_crm\build\web\`
