# AuraSphere CRM - Supabase-Only Deployment Guide

## Architecture
```
┌─────────────────────────────────────────┐
│   AuraSphere CRM Landing Page (Flutter) │
│   📂 build/web/ (static files)          │
└──────────────┬──────────────────────────┘
               │ API Calls
               ▼
┌─────────────────────────────────────────┐
│        Supabase Backend                 │
│  ├─ PostgreSQL Database                │
│  ├─ JWT Authentication                 │
│  ├─ Row Level Security (RLS)           │
│  └─ Storage Bucket                     │
└─────────────────────────────────────────┘
```

---

## 🚀 Deploy to Vercel (Recommended - Free, Zero-Config)

**Why Vercel?** Perfect for Flutter web + Supabase, auto-deploys from Git, free tier includes custom domain.

### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

### Step 2: Login to Vercel
```bash
vercel login
# Opens browser for OAuth login
```

### Step 3: Deploy
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm
vercel --prod
```

**During deployment, Vercel will ask:**
- Project name: `aurasphere-crm`
- Root directory: `build/web`
- Build settings: None (static files, no build needed)

### Step 4: Connect Domain
1. Go to Vercel dashboard → Settings → Domains
2. Add `yourbusiness.online`
3. Update DNS records (Vercel shows exact records)
4. SSL auto-enables (free Let's Encrypt)

**Live in 5 minutes!** ✅

---

## 🌐 Deploy to Netlify (Easy Drag & Drop)

### Option A: CLI
```bash
npm install -g netlify-cli
cd c:\Users\PC\AuraSphere\crm\aura_crm\build\web
netlify deploy --prod --dir=.
```

### Option B: Web UI (Easiest)
1. Visit [Netlify Drop](https://app.netlify.com/drop)
2. Drag & drop `build/web/` folder
3. Done! (automatic deployment)

### Connect Domain
1. Netlify Dashboard → Domain Management
2. Add custom domain `yourbusiness.online`
3. Update DNS (Netlify provides records)
4. HTTPS auto-enabled

---

## 💻 Deploy to Your Own Server (Advanced)

### Option: Nginx + Ubuntu Server

```bash
# On your server (Ubuntu 20.04+)
sudo apt update
sudo apt install -y nginx

# Create app directory
sudo mkdir -p /var/www/aurasphere-crm
sudo chown -R $USER:$USER /var/www/aurasphere-crm

# Upload build/web/* to server
rsync -avz build/web/ user@server:/var/www/aurasphere-crm/
```

### Nginx Configuration
Create `/etc/nginx/sites-available/aurasphere`:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name yourbusiness.online www.yourbusiness.online;
    
    root /var/www/aurasphere-crm;
    index index.html;
    
    # SPA routing - all routes serve index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Cache busting for versioned assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript;
    gzip_min_length 1000;
    
    # Redirect to HTTPS
    redirect_from http:// https:// permanent;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name yourbusiness.online www.yourbusiness.online;
    
    root /var/www/aurasphere-crm;
    index index.html;
    
    # SSL certs (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/yourbusiness.online/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourbusiness.online/privkey.pem;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    gzip on;
    gzip_types text/plain text/css text/javascript application/javascript;
    gzip_min_length 1000;
}
```

### Enable & Restart
```bash
sudo ln -s /etc/nginx/sites-available/aurasphere /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# Setup SSL with Certbot
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourbusiness.online -d www.yourbusiness.online
```

---

## 🔧 Supabase Configuration Checklist

### Database
- [x] PostgreSQL database initialized
- [x] Tables created (organizations, users, clients, jobs, invoices, etc.)
- [x] Row Level Security (RLS) policies enabled
- [ ] Backup scheduled (Supabase → Settings → Backups)

### Authentication
- [x] Email auth enabled
- [x] JWT secret configured
- [x] Redirect URLs configured
- [ ] Email templates customized (optional)

### Environment Variables
Store in your hosting platform:

```env
SUPABASE_URL=https://fppmvibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...  # Keep secret! Only for backend
```

**For Flutter Web (public):**
```dart
const supabaseUrl = 'https://fppmvibvpxrkwmymszhd.supabase.co';
const supabaseAnonKey = 'eyJ...';  // Public key only
```

---

## 📊 Pre-Deployment Checklist

### Frontend
- [x] Landing page tested and responsive
- [x] Pricing tiers configured (Solo $9.99, Team $15, Workshop $29.99)
- [x] WhatsApp integration ready
- [x] Zero compilation errors
- [x] Production build optimized (`flutter build web --release`)

### Backend (Supabase)
- [x] PostgreSQL database ready
- [x] JWT auth configured
- [x] RLS policies enabled
- [x] Anon key configured in code
- [x] API endpoints tested

### Security
- [ ] HTTPS/SSL enabled (auto on Vercel/Netlify)
- [ ] RLS policies restrict data access
- [ ] Environment variables NOT in code
- [ ] Supabase API keys rotated (if needed)
- [ ] CORS headers configured

---

## 🌐 DNS Configuration

### For `yourbusiness.online`

**If using Vercel:**
```
CNAME: yourbusiness.online → cname.vercel-dns.com.
```

**If using Netlify:**
```
CNAME: yourbusiness.online → yourbusiness-xxxx.netlify.app
```

**If using own server:**
```
A Record: yourbusiness.online → [Your Server IP]
A Record: www.yourbusiness.online → [Your Server IP]
```

---

## 🔄 Update & Redeploy

### After Making Changes

```bash
# Locally
flutter build web --release

# Vercel
vercel --prod

# Netlify
netlify deploy --prod --dir=build/web
```

---

## 📊 Monitoring & Logs

### Supabase Dashboard
- Visit: https://app.supabase.com
- View: Database, Auth users, API logs, Errors
- Backups: Settings → Backup

### Vercel Dashboard
- Visit: https://vercel.com/dashboard
- View: Deployments, analytics, errors
- Custom domain status

### Netlify Dashboard
- Visit: https://app.netlify.com
- View: Deployments, analytics, form submissions
- Custom domain status

---

## 🚨 Troubleshooting

### App loads but no data
**Cause:** CORS not configured or Supabase keys missing
**Fix:**
1. Check browser console (F12)
2. Verify `main.dart` has correct Supabase URL & key
3. Check Supabase RLS policies allow anonymous access

### Blank white page
**Cause:** Router issue or index.html not served
**Fix:**
1. Ensure `build/web/index.html` exists
2. Configure hosting to serve index.html for all routes
3. Check Vercel/Netlify build settings

### Database not connecting
**Cause:** Wrong Supabase credentials
**Fix:**
1. Verify credentials in `main.dart`
2. Go to Supabase → Settings → API
3. Copy correct URL & Anon Key
4. Rebuild: `flutter build web --release`

---

## 💰 Cost Breakdown

| Service | Cost | Notes |
|---------|------|-------|
| **Vercel** | Free | Perfect for this project |
| **Netlify** | Free | Drag & drop deployment |
| **Supabase** | Free tier | Up to 50k DB records |
| **Domain** | $10/year | yourbusiness.online |
| **SSL/HTTPS** | Free | Auto on Vercel/Netlify |
| **Total** | ~$10/year | 🎉 |

---

## 🎯 Next Steps

### Immediate (Choose One)
1. **Vercel** (recommended): `npm install -g vercel` → `vercel --prod`
2. **Netlify**: Drag & drop `build/web/` to https://app.netlify.com/drop
3. **Own Server**: Upload files via SFTP/SSH

### Within 1 Hour
- [ ] Choose hosting platform
- [ ] Deploy build/web/
- [ ] Configure custom domain
- [ ] Test live app

### Within 24 Hours
- [ ] Share link with team
- [ ] Test WhatsApp integration
- [ ] Monitor Supabase logs

---

**Status:** Ready for production deployment! 🚀

**Recommended:** Vercel (simplest, fastest, free)

**Last Updated:** January 4, 2026
