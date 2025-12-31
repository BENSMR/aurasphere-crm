# 🏢 AuraSphere CRM - Official App Identity

**Last Updated:** December 30, 2025  
**Version:** 1.0.0 (MVP)

---

## 1️⃣ OFFICIAL BRANDING

### Legal Identity
```
Official Name:        AuraSphere CRM
Legal Tagline:        "Sovereign Digital Life for Tradespeople"
Legal Entity:         Black Diamond LTD
UIC (Bulgaria):       207807571
Headquarters:         Sofia, Bulgaria
Jurisdiction:         EU (GDPR Compliant)
```

### Logo & Visual Identity
```
Logo Design:          Circular electric blue + gold gradient
Icon Element:         Work/tools icon (wrench + lightning bolt)
Primary Color:        #007BFF (Electric Blue)
Secondary Color:      #FFD700 (Gold)
Accent Color:         #00FF7F (Neon Green - growth/success)
Background:           #FFFFFF (White) / #F5F5F5 (Light Gray)
```

### Brand Promise
```
Mission:              Eliminate administrative chaos for tradespeople
Vision:               Every tradesperson has enterprise-grade tools
Core Values:
  ✅ Simplicity       (No complex menus)
  ✅ Reliability      (EU-hosted, GDPR compliant)
  ✅ Sovereignty      (Your data is yours)
  ✅ Intelligence     (AI-powered automation)
```

---

## 2️⃣ CORE FEATURES (CODE-CONFIRMED ✅)

### 🎯 Job Management
```
Status Tracking:      New → Quote → Scheduled → In Progress → Completed
Job Details:
  ├── Address & GPS coordinates
  ├── Materials list with costs
  ├── Photo attachments
  ├── Work notes & timeline
  ├── Assigned technician(s)
  └── Labor hours tracking
```

### 📋 Invoicing System
```
PDF Generation:       Multilingual (EN, FR, IT, AR, MT, DE, ES, PT, more)
Invoice Features:
  ├── Auto-generated from jobs
  ├── Line items with tax calculation
  ├── Payment terms & due dates
  ├── Watermark (DRAFT/PAID)
  ├── Custom company branding
  └── Email delivery tracking
AI Voice Commands:    "Create invoice for Ahmed 300 AED"
                     "Mark invoice #123 as paid"
```

### 👥 Client Management
```
Client Profiles:
  ├── Contact information (name, email, phone, address)
  ├── Health Score (1-100, based on payment history)
  ├── Risk Flags (overdue, disputed, high-value)
  ├── Contact History (calls, emails, meetings)
  ├── Job History (count, total value, satisfaction)
  └── Recurring client indicator
```

### 💰 Expense Tracking
```
Receipt OCR:          Automatic extraction via OCR.space API
Extracted Data:
  ├── Vendor name
  ├── Total amount
  ├── Transaction date
  ├── Line items (if detected)
  └── Currency auto-detection
Auto-Categorization:  
  ├── Materials & Supplies
  ├── Labor & Subcontractors
  ├── Transportation & Travel
  ├── Tools & Equipment
  ├── Office & Admin
  └── Other
```

### 📦 Inventory Management
```
Stock Tracking:
  ├── Item name & SKU
  ├── Current quantity
  ├── Unit cost & selling price
  ├── Reorder threshold
  └── Storage location
Low-Stock Alerts:     Automatic notification when below threshold
Inventory History:    Full audit trail of adjustments
```

### 👨‍💼 Team Management
```
User Roles:
  ├── Admin (full access, billing management)
  ├── Manager (team oversight, reporting)
  ├── Technician (assigned jobs, timesheets)
  └── Viewer (read-only access)
Plan-Based Limits:
  ├── Solo: 1 user
  ├── Small Team: 3 users
  └── Workshop: 7 users
Features:
  ├── Invite via email
  ├── Job assignment
  ├── Availability tracking
  ├── Performance metrics
  └── Commission calculation
```

### 📊 Analytics & Reporting
```
Key Performance Indicators (KPIs):
  ├── Revenue (MTD, YTD)
  ├── Profit margin %
  ├── Job completion rate
  ├── Invoice payment rate (paid/overdue)
  ├── Average job value
  ├── Team utilization %
  ├── Client acquisition cost
  └── Customer lifetime value
Dashboard Layouts:
  ├── Mobile (8 core metrics)
  ├── Tablet (12 enhanced metrics)
  └── Desktop (16+ detailed metrics with trends)
Report Export:
  ├── PDF format
  ├── CSV format (for Excel)
  └── Scheduled delivery (email)
```

### 🔄 Offline Mode
```
SQLite Local Database:
  ├── Syncs jobs, invoices, clients offline
  ├── Queue for when connection restored
  ├── Auto-retry failed syncs
  └── Conflict resolution (server wins)
Sync Status:          Visible to user (last sync time)
Background Sync:      Runs when network detected
```

### 🔒 Security
```
Client-Side Encryption:
  ├── Toggle on/off in Settings
  ├── Uses AES-256
  ├── Encryption key stored securely
  └── End-to-end for sensitive data
EU Data Hosting:
  ├── Supabase (PostgreSQL) hosted in Netherlands
  ├── No US servers
  ├── ISO 27001 certified
  └── GDPR compliant
Authentication:
  ├── Supabase Auth (JWT tokens)
  ├── OAuth 2.0 ready (future: Google, Apple)
  ├── Two-factor authentication (future)
  └── Session timeout (30 min)
```

---

## 3️⃣ TAX CALCULATION SYSTEM ✨ NEW

### Automatic Tax Calculation
```
Location-Based Rates:
  ├── EU Countries (VAT 15-27%)
  ├── UAE (5% VAT)
  ├── UK (20% VAT)
  ├── US States (0-10% sales tax)
  ├── Canada (5-15% GST/HST)
  └── Other regions (configurable)

Tax Types Supported:
  ├── VAT (Value Added Tax) - EU
  ├── GST (Goods & Services Tax) - Australia, Canada
  ├── Sales Tax - USA
  ├── Service Tax - Select countries
  └── Custom rates per region
```

### Invoice Tax Calculation
```
Formula:
  Subtotal = Sum of all line items
  Tax Amount = Subtotal × Tax Rate
  Total = Subtotal + Tax Amount

Example (Bulgaria, 20% VAT):
  ├── Materials: 100 BGN
  ├── Labor: 150 BGN
  ├── Subtotal: 250 BGN
  ├── VAT (20%): 50 BGN
  └── Total: 300 BGN
```

### Tax Configuration
```
Settings > Organization > Tax
  ├── Business Tax ID
  ├── Default tax region
  ├── Tax ID format validation
  ├── Exempt customers list
  └── Tax report frequency
```

### Tax Reporting
```
Monthly/Quarterly Reports:
  ├── Total sales by tax category
  ├── Tax collected
  ├── Tax deductions (expenses)
  ├── Net tax payable
  └── Export to local tax authority format

Supported Export Formats:
  ├── Bulgarian NRAI format
  ├── EU VAT MOSS report
  ├── US IRS Form
  ├── CSV (custom field mapping)
  └── PDF (formatted report)
```

### Tax Database
```
Supabase Table: tax_rates
├── id (UUID)
├── country (TEXT)
├── region (TEXT, nullable)
├── tax_type (TEXT: VAT|GST|Sales Tax)
├── rate (DECIMAL: 0.00-1.00)
├── effective_date (TIMESTAMP)
├── last_updated (TIMESTAMP)
└── source (TEXT: OECD|Local Authority)
```

---

## 4️⃣ PERSONALIZATION ENGINE

### Trade-Specific Themes
```
Auto-Apply Based on Business Type Selection:

🔵 PLUMBER (Blue Theme)
  ├── Primary: #0066CC (Dark Blue)
  ├── Accent: #00A8E8 (Light Blue)
  ├── Icons: Water droplets, pipes, wrenches
  └── Common expenses: Pipes, fittings, water tanks

⚡ ELECTRICIAN (Yellow Theme)
  ├── Primary: #FFB81C (Golden Yellow)
  ├── Accent: #FFA500 (Orange)
  ├── Icons: Lightning bolts, switches, cables
  └── Common expenses: Wire, breakers, fixtures

🔥 HVAC (Red Theme)
  ├── Primary: #D32F2F (Red)
  ├── Accent: #FF6F00 (Dark Orange)
  ├── Icons: Air vents, thermometers, fans
  └── Common expenses: Filters, compressors, refrigerant

🏗️ CONSTRUCTION (Green Theme)
  ├── Primary: #1B5E20 (Dark Green)
  ├── Accent: #43A047 (Light Green)
  ├── Icons: Tools, buildings, safety gear
  └── Common expenses: Lumber, concrete, equipment

👷 GENERAL CONTRACTOR (Purple Theme)
  ├── Primary: #6A1B9A (Purple)
  ├── Accent: #AB47BC (Light Purple)
  ├── Icons: Hardhat, blueprint, tools
  └── Common expenses: All categories
```

### Device-Specific Dashboards
```
Mobile (<600px):        8 core KPIs, simple layout
  ├── Total Revenue
  ├── Active Jobs
  ├── Pending Invoices
  ├── Team Members
  ├── Completion Rate
  ├── Average Invoice Value
  ├── New Clients
  └── Upcoming Jobs

Tablet (600-1000px):    12 enhanced KPIs, 2-column grid
  ├── [Same as mobile +]
  ├── Monthly Expenses
  ├── Payment Rate
  ├── Client Satisfaction
  └── Team Utilization

Desktop (>1000px):      16+ detailed KPIs, charts, trends
  ├── [All above +]
  ├── Year-to-date revenue (trend)
  ├── Response time average
  ├── Total projects (all-time)
  ├── Repeat client percentage
  ├── Charts & trend lines
  └── Detailed breakdowns
```

### Language & Localization
```
18 European Languages + Arabic:

Tier 1 (Full Support):
  ├── English (en) ✅
  ├── Bulgarian (bg) ✅
  ├── German (de) ✅
  ├── French (fr) ✅
  ├── Spanish (es) ✅
  ├── Italian (it) ✅
  └── Polish (pl) ✅

Tier 2 (Ready for Translation):
  ├── Greek (el)
  ├── Portuguese (pt)
  ├── Romanian (ro)
  ├── Hungarian (hu)
  ├── Czech (cs)
  ├── Slovak (sk)
  └── Croatian (hr)

Tier 3 (Infrastructure Ready):
  ├── Dutch (nl)
  ├── Swedish (sv)
  └── Danish (da)

Special Support:
  ├── Arabic (ar) - RTL layout, right-aligned UI
  ├── Hebrew (he) - RTL layout
  └── Maltese (mt) - Full support

Auto-Detection:
  ├── Browser locale detection
  ├── System language detection
  ├── Manual override in Settings
  ├── Persistent preference (localStorage)
  └── API requests include lang header
```

---

## 5️⃣ PRICING PLANS (LIVE)

### Tiered Pricing Model
```
┌─────────────────┬──────────────┬──────────┬────────────────────────────────┐
│ Plan            │ Price (USD)  │ Users    │ Key Features                   │
├─────────────────┼──────────────┼──────────┼────────────────────────────────┤
│ Solo            │ $4.99/mo     │ 1        │ • 20 jobs/month                │
│ (Self-employed) │              │          │ • AI invoicing                 │
│                 │              │          │ • Core CRM (clients, expenses) │
│                 │              │          │ • Basic analytics              │
├─────────────────┼──────────────┼──────────┼────────────────────────────────┤
│ Small Team      │ $7.50/mo     │ 3        │ • Unlimited jobs               │
│ (2-3 people)    │              │          │ • Team collaboration           │
│                 │              │          │ • All Solo features +          │
│                 │              │          │ • Job dispatch                 │
│                 │              │          │ • Team member limits           │
├─────────────────┼──────────────┼──────────┼────────────────────────────────┤
│ Workshop        │ $14.50/mo    │ 7        │ • All Small Team features +    │
│ (5-10 people)   │              │          │ • Inventory tracking           │
│                 │              │          │ • Advanced dispatch            │
│                 │              │          │ • Performance analytics        │
│                 │              │          │ • Tax reporting                │
├─────────────────┼──────────────┼──────────┼────────────────────────────────┤
│ Enterprise      │ Custom       │ Unlimited│ • All features                 │
│ (Large orgs)    │ (contact)    │          │ • API access                   │
│                 │              │          │ • Dedicated support            │
│                 │              │          │ • SSO/OAuth                    │
│                 │              │          │ • Custom integrations          │
└─────────────────┴──────────────┴──────────┴────────────────────────────────┘
```

### Trial & Discounts
```
Trial Period:         3 days (72 hours)
Trial Requirements:   No credit card needed
Trial Features:       All features of Small Team plan
Trial Limit:          One trial per email address

Promotional Discounts:
├── New Users:        50% off first 2 months
├── Annual Billing:   20% discount (pay yearly)
├── Team Discount:    Additional 10% if 5+ seats
└── Non-profit:       50% discount (with verification)
```

### Payment Processing
```
Payment Provider:     Paddle (recurring billing)
Payment Methods:
  ├── Credit/Debit cards (Visa, Mastercard, Amex)
  ├── Apple Pay
  ├── Google Pay
  ├── PayPal (via Paddle)
  └── Bank transfers (for Enterprise)

Billing Cycle:
  ├── Monthly (default, cancel anytime)
  ├── Annual (20% discount)
  └── Custom invoicing (Enterprise)

Invoice Details:
  ├── PDF invoice generated immediately
  ├── Tax calculated per customer location
  ├── Invoice number & date tracking
  └── VAT/tax ID support
```

---

## 6️⃣ COMPLIANCE & TECHNICAL STACK

### GDPR Compliance
```
Data Rights (Settings > Privacy):
  ├── ✅ Download your data (ZIP export)
  ├── ✅ Delete your account (irreversible, 30-day wait)
  ├── ✅ Data portability (standard JSON format)
  ├── ✅ Consent management
  └── ✅ Privacy policy & T&Cs in 18 languages

Data Processing:
  ├── EU data center (Netherlands)
  ├── No data sharing with third parties
  ├── 90-day data retention after deletion
  ├── DPIA completed (Data Protection Impact Assessment)
  └── DPA signed with Supabase
```

### Technical Stack
```
Frontend:
  ├── Flutter 3.35.7 (Dart 3.9.2)
  ├── Material Design 3
  ├── Responsive Web (CSS media queries)
  └── Offline-first SQLite

Backend:
  ├── Supabase (PostgreSQL 14+)
  ├── Hosted in Netherlands (EU region)
  ├── Automatic backups (daily)
  └── Point-in-time recovery (30 days)

AI/Intelligence:
  ├── Groq AI (fast inference)
  ├── Voice command processing (speech-to-text)
  ├── Invoice OCR (OCR.space API)
  └── Auto-categorization (rules engine)

Authentication:
  ├── Supabase Auth (JWT tokens)
  ├── OAuth 2.0 ready
  ├── flutter_secure_storage (encrypted)
  └── Biometric auth (future: Face ID, Touch ID)

Monitoring:
  ├── Sentry (error tracking)
  ├── Google Analytics (anonymized)
  ├── Uptime monitoring (Pingdom)
  └── Performance APM (DataDog)
```

### Security Certifications
```
Current:
  ├── ✅ GDPR compliant (EU hosted)
  ├── ✅ ISO 27001 (via Supabase)
  ├── ✅ SOC 2 Type II (via Supabase)
  ├── ✅ HTTPS/TLS 1.3 (encrypted transport)
  └── ✅ Data encryption at rest (AES-256)

Planned:
  ├── 🔄 PCI DSS Level 1 (payment handling)
  ├── 🔄 HIPAA compliant (future: healthcare version)
  └── 🔄 SOC 3 Type II (full transparency)
```

---

## 7️⃣ PLATFORM ACCESS

### Web Platform (Live ✅)
```
URL:                  https://crm.aura-sphere.app
Browser Support:
  ├── Chrome 90+      ✅ Full support
  ├── Firefox 88+     ✅ Full support
  ├── Safari 14+      ✅ Full support
  ├── Edge 90+        ✅ Full support
  └── Mobile browsers ✅ Responsive

Features:
  ├── Responsive design (mobile → desktop)
  ├── Progressive Web App (PWA)
  ├── Offline capability
  └── Home screen install
```

### Mobile Platforms (Coming Q1 2026)
```
iOS App:
  ├── App Store: "AuraSphere CRM"
  ├── Min iOS 13+
  ├── Native performance
  └── Face ID / Touch ID support

Android App:
  ├── Google Play: "AuraSphere CRM"
  ├── Min Android 8.0+
  ├── Native performance
  └── Biometric auth
```

### Desktop Platforms (Coming Q2 2026)
```
Windows:
  ├── Native Windows app
  ├── Windows 10 / 11
  └── Microsoft Store

macOS:
  ├── Native macOS app
  ├── macOS 11+
  └── Mac App Store

Linux:
  ├── Native Linux app
  ├── Snap package available
  └── Flatpak package available
```

---

## 8️⃣ CONTACT & SUPPORT

### Business Contact
```
Company:              Black Diamond LTD
Email:                support@aura-sphere.app
Support Hours:        24/7 (automated) + 9-5 CET (human support)
Response Time:        < 2 hours (priority support)
```

### Help Resources
```
Knowledge Base:       docs.aura-sphere.app
Video Tutorials:      youtube.com/@aurasphere-crm
Community Forum:      forum.aura-sphere.app
Status Page:          status.aura-sphere.app
```

---

**Last Updated:** December 30, 2025  
**Next Review:** March 30, 2026 (Q1 update)  
**Version:** 1.0.0 MVP → 1.1.0 (Q1 2026: Mobile + Tax Reports)
