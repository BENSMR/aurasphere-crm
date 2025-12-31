# 💳 PRICING & COMPLIANCE GUIDE

**Effective Date:** December 30, 2025  
**Currency:** USD (all prices listed)

---

## 1️⃣ PRICING TABLE (PADDLE INTEGRATION)

### Live Pricing Plans

| Feature | Solo | Small Team | Workshop | Enterprise |
|---------|------|-----------|----------|------------|
| **Monthly Price** | $4.99 | $7.50 | $14.50 | Custom |
| **Annual Price** | $59.88 (20% off) | $90 (20% off) | $174 (20% off) | Custom |
| **Users Included** | 1 | 3 | 7 | Unlimited |
| **Jobs/Month** | 20 | Unlimited | Unlimited | Unlimited |
| **AI Invoicing** | ✅ | ✅ | ✅ | ✅ |
| **Core CRM** | ✅ | ✅ | ✅ | ✅ |
| **Team Collaboration** | ❌ | ✅ | ✅ | ✅ |
| **Job Dispatch** | ❌ | ✅ | ✅ | ✅ |
| **Inventory** | ❌ | ❌ | ✅ | ✅ |
| **Advanced Analytics** | ❌ | ❌ | ✅ | ✅ |
| **Tax Reporting** | ❌ | ❌ | ✅ | ✅ |
| **API Access** | ❌ | ❌ | ❌ | ✅ |
| **Dedicated Support** | Email | Email | Priority | 24/7 Phone |

---

## 2️⃣ PROMOTIONAL OFFERS

### New User Promotion
```
Offer:             50% off first 2 months
Applies to:        All new accounts (first-time users)
Terms:
  ├── One per email address
  ├── Valid for first 60 days only
  ├── Applies to monthly or annual plans
  ├── Cannot be combined with other offers
  └── Automatic application at checkout
Example:
  ├── Solo: $2.49/mo × 2 = $4.98
  ├── Small Team: $3.75/mo × 2 = $7.50
  └── Workshop: $7.25/mo × 2 = $14.50
```

### Annual Billing Discount
```
Offer:             20% discount (pay annually)
Savings:
  ├── Solo: Save $14.38/year
  ├── Small Team: Save $18/year
  └── Workshop: Save $43.80/year
Payment:
  ├── Full annual payment upfront
  ├── Automatic renewal on anniversary
  ├── Cancellation allowed before renewal
  └── Prorated refund if cancel within 30 days
```

### Team Discount
```
Offer:             Additional 10% off with 5+ user licenses
Minimum:           5 paid users
Example:
  ├── 5 users × $7.50 = $37.50/mo
  ├── With 10% team discount = $33.75/mo
  ├── Annual: $405 (instead of $450)
  └── Saves: $45/year
```

### Non-Profit Program
```
Offer:             50% discount for registered 501(c)(3) orgs
Verification:      Upload IRS documentation
Duration:          Annual, must re-verify
Plans Included:
  ├── Eligible: Solo, Small Team, Workshop
  ├── Not eligible: Enterprise (contact sales)
  └── Support: Email support included
```

---

## 3️⃣ TAX CALCULATION & INVOICING

### Automatic Tax Calculation

**By Region:**

#### 🇪🇺 European Union (VAT)
```
VAT Rates:
  ├── Austria: 20%
  ├── Belgium: 21%
  ├── Bulgaria: 20%
  ├── Croatia: 25%
  ├── Cyprus: 19%
  ├── Czech Republic: 21%
  ├── Denmark: 25%
  ├── Estonia: 20%
  ├── Finland: 24%
  ├── France: 20%
  ├── Germany: 19%
  ├── Greece: 24%
  ├── Hungary: 27%
  ├── Ireland: 23%
  ├── Italy: 22%
  ├── Latvia: 21%
  ├── Lithuania: 21%
  ├── Luxembourg: 17%
  ├── Malta: 18%
  ├── Netherlands: 21%
  ├── Poland: 23%
  ├── Portugal: 23%
  ├── Romania: 19%
  ├── Slovakia: 20%
  ├── Slovenia: 22%
  ├── Spain: 21%
  ├── Sweden: 25%
  └── UK: 20%
```

#### 🇦🇪 Middle East & GCC
```
VAT/Tax Rates:
  ├── United Arab Emirates: 5% VAT
  ├── Saudi Arabia: 15% VAT
  ├── Bahrain: 12% VAT
  ├── Qatar: 0% (no VAT)
  ├── Kuwait: 0% (no VAT)
  ├── Oman: 0% (no VAT)
  └── Other: Custom configurable
```

#### 🇺🇸 United States (Sales Tax - by state)
```
Federal:           No federal sales tax
State Rates:       0% (Montana, Alaska) to 10% (varies)
Registration:      Required per state where customers located
Note:              AuraSphere can calculate but doesn't collect
                   Remittance is seller responsibility
```

#### 🇨🇦 Canada (GST/HST)
```
Federal GST:       5%
Provincial HST:    8-15% (varies by province)
Example - Ontario:
  ├── GST: 5%
  ├── PST: 8%
  └── Combined HST: 13%
```

### Invoice Tax Calculation Formula
```
Step 1: Calculate Subtotal
  Subtotal = Σ(Quantity × Unit Price) for all items

Step 2: Get Tax Rate
  Tax Rate = getVatRate(customerCountry)
  OR
  Tax Rate = organizationTaxRate (if auto-tax enabled)

Step 3: Calculate Tax Amount
  Tax Amount = Subtotal × Tax Rate

Step 4: Calculate Total
  Total = Subtotal + Tax Amount

Example (Bulgaria, 20% VAT):
  ├── Item 1: 3 × 100 BGN = 300 BGN
  ├── Item 2: 2 × 75 BGN = 150 BGN
  ├── Subtotal: 450 BGN
  ├── VAT (20%): 90 BGN
  └── Total: 540 BGN
```

### Tax-Exempt Customers
```
Setting in:       Organization Settings > Tax
Feature:
  ├── Mark specific clients as tax-exempt
  ├── Common use: Government orgs, international
  ├── Invoices show: "VAT Not Applicable"
  ├── Zero tax amount on invoice
  └── Tracked for tax reports
```

---

## 4️⃣ COMPLIANCE & LEGAL

### 🔒 GDPR Compliance (EU)

**User Rights:**
```
Right to Access:
  ├── Settings > Privacy > Download Your Data
  ├── Provides ZIP with all personal data
  ├── JSON format, machine-readable
  ├── Processed within 30 days
  └── Free of charge

Right to Rectification:
  ├── Edit own profile anytime
  ├── Auto-sync to all documents
  ├── History retained (audit trail)
  └── No charge

Right to Erasure ("Right to be Forgotten"):
  ├── Settings > Privacy > Delete Account
  ├── Irreversible action
  ├── 30-day waiting period (can cancel)
  ├── Data deleted after 90 days
  ├── Some data retained for legal/tax (anonymized)
  └── Free of charge

Right to Data Portability:
  ├── Export in standard JSON format
  ├── Works with competing services
  ├── Available on request
  └── Free of charge

Right to Restrict Processing:
  ├── Disable specific features (e.g., analytics)
  ├── Opt-out of marketing emails
  ├── Settings > Privacy > Preferences
  └── No charge
```

**Data Protection:**
```
Data Location:        Netherlands (EU region)
Data Center:          Supabase-managed facility
Encryption:           AES-256 at rest, TLS 1.3 in transit
Backups:              Daily, 30-day retention
Disaster Recovery:    RTO < 1 hour, RPO < 15 min
DPIA:                 Completed (Data Protection Impact Assessment)
DPA:                  Signed with Supabase
Sub-processors:
  ├── Supabase (database, auth)
  ├── Groq AI (invoice parsing)
  ├── OCR.Space (receipt scanning)
  ├── Paddle (payments)
  └── Sentry (error monitoring)
```

### 🇧🇬 Bulgaria-Specific Compliance

**Tax Identification:**
```
Company:              Black Diamond LTD
VAT ID:               BG 207807571
Tax Authority:        Bulgarian Tax Agency
Jurisdiction:         Sofia
Tax Year:             Calendar year (Jan 1 - Dec 31)
```

**Accounting Requirements:**
```
Record Keeping:       7 years (legal requirement)
Invoice Format:       Must include VAT ID, issue date
Invoice Numbers:      Sequential, uninterrupted
Retention:            Digital or paper, tamper-proof
Audit:                Subject to annual tax audit
```

### 🌍 International Compliance

**GDPR:**
- ✅ EU Data Hosting (Netherlands)
- ✅ Data Processing Agreement signed
- ✅ Privacy Policy in 18 languages
- ✅ Cookie consent management
- ✅ Right to erasure implemented

**ISO 27001 (Supabase):**
- ✅ Information Security Management
- ✅ Access controls
- ✅ Incident response plan
- ✅ Annual audits

**SOC 2 Type II (Supabase):**
- ✅ Security controls verified
- ✅ Availability & performance
- ✅ Confidentiality maintained
- ✅ Integrity of data

**PCI DSS Level 1 (Paddle):**
- ✅ All payment processing via Paddle
- ✅ No credit card data stored locally
- ✅ Encryption enforced
- ✅ Regular security assessments

---

## 5️⃣ PAYMENT TERMS & CONDITIONS

### Billing & Invoicing

**Billing Cycle:**
```
Monthly Plan:
  ├── Charged on same date each month
  ├── Access continues through billing date
  ├── Cancel anytime, no early termination fee
  └── Refund prorated if cancel mid-month

Annual Plan:
  ├── Charged once per year
  ├── Full year access
  ├── Automatically renews (reminder sent)
  ├── Cancel 30 days before renewal
  └── Refund prorated if cancel within 30 days
```

**Invoice Details:**
```
Provided By:         Paddle (our payment processor)
Format:              PDF email receipt
Includes:
  ├── Invoice number
  ├── Issue date
  ├── Customer tax ID (if provided)
  ├── Amount, tax, total
  ├── Payment method
  └── Due date (typically immediate)
```

**Failed Payments:**
```
Retry Schedule:
  ├── 1st attempt: Immediately
  ├── 2nd attempt: 3 days later
  ├── 3rd attempt: 5 days later
  ├── 4th attempt: 7 days later
  └── After 4 failures: Account suspended
Suspension:
  ├── Features disabled (read-only access)
  ├── Data preserved
  ├── 30-day recovery period
  ├── Reactivation fee: None (reactivate on successful payment)
  └── Account deletion: After 90 days
```

### Refund Policy

**Refund Eligibility:**
```
Full Refund (30 days):
  ├── Requested within 30 days of purchase
  ├── No usage restrictions
  ├── Automatic processing
  └── Refund to original payment method
Partial Refund (After 30 days):
  ├── Prorated based on unused days
  ├── Manual request required
  ├── Processed within 5 business days
  └── Refund to original payment method
No Refund:
  ├── Annual plans used for 60+ days
  ├── Free trials converted to paid
  ├── Promotional credits used
  └── After dispute resolution
```

---

## 6️⃣ DATA & PRIVACY

### Privacy Policy Summary
```
Data Collected:
  ├── Account info (name, email, password hash)
  ├── Company info (name, address, VAT ID)
  ├── Customer data (invoiced clients)
  ├── Job & invoice data
  ├── Analytics (page views, features used)
  └── Technical (IP, browser, device type)
Data Usage:
  ├── Service provision (required)
  ├── Billing & payments (required)
  ├── Support & customer service
  ├── Product improvement (analytics)
  ├── Legal obligations (tax, fraud)
  └── Marketing (only with opt-in)
Data Sharing:
  ├── Supabase (database hosting)
  ├── Paddle (payment processing)
  ├── Groq/OCR.Space (AI services)
  ├── Sentry (error monitoring)
  ├── Email provider (notifications)
  └── NO third-party marketing
Data Retention:
  ├── Active accounts: Full retention
  ├── After deletion: 90-day grace period
  ├── Tax records: 7 years (legal requirement)
  ├── Backups: 30-day retention
  └── Anonymized analytics: Indefinite
```

### Cookie Policy
```
Essential Cookies:
  ├── Session token (authentication)
  ├── Language preference
  ├── Theme preference (light/dark)
  └── Automatically set, non-removable
Analytics Cookies:
  ├── Google Analytics (anonymized)
  ├── Can be disabled in Privacy Settings
  ├── No personal identification
  └── No tracking across sites
Marketing Cookies:
  ├── None (we don't use marketing cookies)
  └── Policy: Privacy-first approach
```

---

## 7️⃣ SUPPORT & SERVICE LEVEL

### Support by Plan

| Tier | Solo | Small Team | Workshop | Enterprise |
|------|------|-----------|----------|-----------|
| **Response Time** | 24 hrs | 12 hrs | 4 hrs | < 1 hr |
| **Channel** | Email | Email | Email/Chat | Phone/Chat/Email |
| **Hours** | Business | Business | Business + Weekend | 24/7 |
| **Knowledge Base** | ✅ | ✅ | ✅ | ✅ |
| **Video Tutorials** | ✅ | ✅ | ✅ | ✅ |
| **Community Forum** | ✅ | ✅ | ✅ | ✅ |
| **Priority Support** | ❌ | ❌ | ✅ | ✅ |
| **Training Calls** | ❌ | ❌ | Quarterly | Monthly |
| **Custom Dev** | ❌ | ❌ | Contact | ✅ |

### Service Level Agreement (SLA)
```
Uptime Guarantee:     99.9% (maximum 46 min/month downtime)
Maintenance Windows:  Sunday 2-4 AM CET (48 hrs notice)
Incident Response:
  ├── P1 (Critical): 15 min initial response
  ├── P2 (High): 1 hour initial response
  ├── P3 (Medium): 4 hours initial response
  └── P4 (Low): 1 business day
Backups:              Daily, tested weekly
Disaster Recovery:    RTO < 1 hour
Status Page:          status.aura-sphere.app
```

---

**Document Version:** 1.0  
**Last Updated:** December 30, 2025  
**Next Review:** March 30, 2026
