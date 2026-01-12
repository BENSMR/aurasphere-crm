# AuraSphere CRM - Netlify Deployment

## Quick Deploy Steps

### Option 1: Drag & Drop Deploy (Easiest)
1. Go to https://app.netlify.com
2. Sign up or log in (free account)
3. Drag `build/web/` folder to the drop zone
4. Netlify auto-deploys and gives you a live URL (e.g., `https://xxxxx.netlify.app`)

### Option 2: Netlify CLI
```bash
npm install -g netlify-cli
cd build/web
netlify deploy --prod
```

### Option 3: GitHub Auto-Deploy
1. Push code to GitHub
2. Connect GitHub to Netlify
3. Auto-deploys on every push

---

## After Deployment

1. **Netlify gives you a URL** (e.g., `https://aura-crm-xyz.netlify.app`)
2. **Copy that URL**
3. **Tell me the URL** and I'll:
   - Configure Supabase for that domain
   - Update your app code
   - Test it live

---

## Current Build Info
- Build Date: January 12, 2026
- Built: `flutter build web --release`
- Location: `c:\Users\PC\AuraSphere\crm\aura_crm\build\web\`
- Supabase Project: `fppmuibvpxrkwmymszhd`
- Anon Key: Configured ✅
