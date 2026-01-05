# African Prepayment Code System - Quick Reference

## 🚀 At a Glance

**What:** Offline payment activation codes for 54 African countries without Stripe/Paddle access  
**Why:** Expand market reach to underbanked regions  
**How:** Admin generates codes → Customers redeem during signup → Instant access  
**Status:** ✅ Production Ready

---

## 📋 Code Format

```
AURA-{REGION}-{YEAR}-{DURATION}-{RANDOM}
```

**Example:** `AURA-NG-2026-3M-ABC123` = Nigeria, 3 months

| Part | Format | Example |
|------|--------|---------|
| AURA | Fixed prefix | AURA |
| Region | 2-letter ISO | NG, KE, ZA |
| Year | YYYY | 2026 |
| Duration | 1M\|3M\|6M\|1Y | 3M |
| Random | 6 alphanumeric | ABC123 |

---

## 🌍 Supported Countries (54)

**North Africa (7):** EG, MA, DZ, TN, LY, SD, MR

**West Africa (14):** NG, GH, CI, SN, ML, BF, BJ, TG, NE, GN, GW, LR, SL, CV

**Central Africa (9):** CM, GA, CG, CD, TD, CF, ST, GQ, AO

**East Africa (11):** ET, KE, UG, TZ, RW, BI, SO, DJ, ER, SC, KM

**Southern Africa (13):** ZA, ZM, ZW, MW, MZ, NA, BW, LS, SZ, MU, MG, RE, YT

---

## 💰 Plans & Pricing

| Plan | Price | Duration Options | Max Users | Max Jobs |
|------|-------|-------------------|-----------|----------|
| Solo Trades | $9.99/mo | 1M/3M/6M/1Y | 1 | 25 |
| Small Team | $15/mo | 1M/3M/6M/1Y | 3 | 60 |
| Workshop | $29/mo | 1M/3M/6M/1Y | 7 | 120 |

---

## 📁 Files Created

### Service Layer
```
lib/services/african_prepayment_code_service.dart
├── generateAfricanCodes()      → Admin: Create batch
├── redeemAfricanCode()         → Customer: Use code
├── getCodeStatus()             → Public: Verify code
├── getAfricanCodeStats()       → Admin: Analytics
└── ... 10+ more methods
```

### Admin Page
```
lib/african_code_generation_page.dart
├── Dashboard with statistics
├── Batch generation form
├── Region multi-select
├── Duration selector
├── Copy/Download codes
└── Success confirmation
```

### Customer Page
```
lib/african_code_redemption_signup_page.dart
├── Step 1: Code entry
├── Step 2: Verification
├── Step 3: Confirmation
├── Step 4: Completion
└── Real-time validation
```

### Database Schema
```
supabase/migrations/20260105_create_african_prepayment_codes.sql
├── african_prepayment_codes (main table)
├── african_code_redemption_audit (tracking)
└── african_code_distribution (batches)
```

---

## 🔧 Core Methods

### Generate Codes (Admin)
```dart
final result = await codeService.generateAfricanCodes(
  planId: 'solo_trades',              // Required
  quantity: 100,                      // 1-1000
  duration: '3M',                     // 1M, 3M, 6M, 1Y
  regions: ['NG', 'KE', 'ZA'],       // At least 1
  generatedBy: userId,                // Admin ID
  description: 'Q1 Campaign',         // Optional
);

// Returns: { success: true, codes: [...], codes_generated: 100 }
```

### Redeem Code (Customer)
```dart
final result = await codeService.redeemAfricanCode(
  code: 'AURA-NG-2026-3M-ABC123',
  userId: currentUserId,
  userCountry: 'NG',
);

// Returns: {
//   success: true,
//   plan_id: 'solo_trades',
//   subscription_start: '2026-01-05...',
//   subscription_end: '2026-04-05...'
// }
```

### Check Code Status (Public)
```dart
final status = await codeService.getCodeStatus('AURA-NG-2026-3M-ABC123');

// Returns: {
//   found: true,
//   status: 'active' | 'redeemed' | 'expired',
//   country_name: 'Nigeria',
//   duration: '3M',
//   is_expired: false
// }
```

### Get Statistics (Admin)
```dart
final stats = await codeService.getAfricanCodeStats();

// Returns: {
//   total_codes: 5000,
//   active_codes: 3200,
//   redeemed_codes: 1800,
//   redemption_rate: '36.00%',
//   codes_per_region: { NG: 1200, KE: 800, ... }
// }
```

---

## 🔐 Security Features

✅ **Single-use:** Each code works only once  
✅ **Region-locked:** Code valid only in specified country  
✅ **Format validation:** Must match AURA-XX-YYYY-XM-XXXXXX  
✅ **Expiry checking:** 12x duration from generation  
✅ **Admin-only generation:** RLS enforced  
✅ **Audit logging:** Every redemption tracked  
✅ **Cryptographic randomness:** 6-char random suffix

---

## 📊 Database Tables

### african_prepayment_codes
Main table storing all codes:
- `code` - AURA-XX-YYYY-XM-XXXXXX (UNIQUE)
- `status` - active, redeemed, expired
- `region` - 2-letter country code
- `plan_id` - solo_trades, small_team, workshop
- `duration` - 1M, 3M, 6M, 1Y
- `created_at`, `expires_at`
- `redeemed_by`, `redeemed_at`

### african_code_redemption_audit
Tracks every redemption event:
- `code_id` - Reference to code
- `redeemed_by` - User who redeemed
- `org_id` - Organization created
- `subscription_start`, `subscription_end`
- `ip_address`, `user_agent`
- `status` - success, failed, cancelled

### african_code_distribution
Batch tracking:
- `batch_id` - Unique batch identifier
- `generated_by` - Admin user
- `regions[]` - Targeted countries
- `quantity` - Number of codes
- `distribution_method` - email, download, manual, api

---

## 🎯 Workflows

### Admin: Generate Campaign Codes
```
1. Go to /admin/african-codes
2. Select Plan: Solo Trades
3. Select Duration: 3M
4. Select Regions: NG, KE, GH (multi-select)
5. Quantity: 100
6. Description: "Q1 2026 Campaign"
7. Click Generate
8. Copy codes
9. Send via WhatsApp/Email
```

**Result:** 100 unique codes, region-distributed, 3-month access

### Customer: Activate with Code
```
1. Visit landing page
2. Click "Have activation code?"
3. Paste: AURA-NG-2026-3M-ABC123
4. Click Validate
5. Select Country: Nigeria
6. Confirm Details
7. Click Activate
8. Redirected to Dashboard
```

**Result:** Instant access to Solo Trades plan for 3 months

---

## 📱 UI Components

### Admin Dashboard
- Live statistics widget
- Batch generation form
- Responsive region selector
- Generated codes display
- Copy to clipboard button
- Download as CSV button

### Customer Signup Flow
- 4-step progress indicator
- Format validation with examples
- Real-time code verification
- Country quick-select buttons
- Summary confirmation
- Success completion screen

---

## ✨ Features Checklist

- ✅ 54 African countries supported
- ✅ 4 duration options (1M/3M/6M/1Y)
- ✅ 3 subscription plans
- ✅ Batch code generation (1-1000)
- ✅ Single-use enforcement
- ✅ Region locking
- ✅ Expiry validation
- ✅ Admin dashboard
- ✅ Customer redemption flow
- ✅ Audit logging
- ✅ Statistics & analytics
- ✅ CSV export
- ✅ Responsive design
- ✅ Error handling
- ✅ Format validation

---

## 🚢 Deployment

### 1. Database Setup
```bash
# In Supabase SQL Editor, run migration file:
# supabase/migrations/20260105_create_african_prepayment_codes.sql
```

### 2. Add to Routes
```dart
// main.dart
routes: {
  '/african-code-redemption': (context) => const AfricanCodeRedemptionSignupPage(),
  '/admin/african-codes': (context) => const AfricanCodeGenerationPage(),
}
```

### 3. Build & Deploy
```bash
flutter build web --release
# Deploy to hosting
```

---

## 📈 Metrics to Monitor

- **Generation Rate:** Codes per week
- **Redemption Rate:** Redeemed / Total (target: 30-50%)
- **Regional Distribution:** Codes by country
- **Plan Distribution:** Most popular plans
- **Code Expiry:** Monitor unused codes
- **Churn:** Cancelled subscriptions

---

## 🐛 Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Code not found | Typo in code | Check format AURA-XX-YYYY-XM-XXXXXX |
| Already redeemed | Single-use enforcement | Expected - get new code |
| Code expired | 12x duration passed | Generate new codes |
| Format invalid | Wrong characters | Format: AURA-NG-2026-3M-ABC123 |
| Database error | Table not created | Run migration in Supabase |

---

## 📚 Full Documentation

For detailed information, see:
- **[AFRICAN_PREPAYMENT_CODE_SYSTEM.md](AFRICAN_PREPAYMENT_CODE_SYSTEM.md)** - Complete feature guide (15+ sections)
- **[AFRICAN_PREPAYMENT_IMPLEMENTATION.md](AFRICAN_PREPAYMENT_IMPLEMENTATION.md)** - Step-by-step implementation (deployment, testing, troubleshooting)

---

## 💡 Pro Tips

1. **Batch Generation:** Generate codes in region batches for better distribution control
2. **Campaign Tracking:** Use description field to tag campaigns: "Q1 2026", "Partner XYZ"
3. **Bulk Distribution:** Export as CSV and import to email/WhatsApp bulk sender
4. **Monitoring:** Check stats dashboard weekly for redemption trends
5. **Partner Quotas:** Limit codes per partner using admin interface
6. **Seasonal Promotions:** Generate 6M/1Y codes for premium customers
7. **A/B Testing:** Try different region distributions and track redemption rates
8. **Analytics:** Export audit table monthly for subscription analysis

---

## 🆘 Support

**Questions?** Check the documentation or audit logs:
```sql
-- View recent redemptions
SELECT * FROM african_code_redemption_audit 
ORDER BY created_at DESC LIMIT 10;

-- Check code distribution
SELECT region, COUNT(*) FROM african_prepayment_codes 
GROUP BY region ORDER BY COUNT(*) DESC;
```

---

**Last Updated:** January 5, 2026  
**Version:** 1.0  
**Production Ready:** ✅
