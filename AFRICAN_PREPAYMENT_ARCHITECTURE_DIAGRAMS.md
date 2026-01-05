# African Prepayment Code System - Architecture & Diagrams

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AURA SPHERE CRM - AFRICAN MARKET                 │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                           FLUTTER FRONTEND                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────┐    ┌──────────────────────────┐       │
│  │  Admin Dashboard        │    │  Customer Signup         │       │
│  │  (Code Generation)      │    │  (Code Redemption)       │       │
│  │                         │    │                          │       │
│  │ • Generate codes        │    │ • Step 1: Enter code     │       │
│  │ • Select plan           │    │ • Step 2: Verify code    │       │
│  │ • Select regions        │    │ • Step 3: Confirm        │       │
│  │ • View statistics       │    │ • Step 4: Complete       │       │
│  │ • Download codes        │    │ • Real-time validation   │       │
│  └─────────────────────────┘    └──────────────────────────┘       │
│           │                                    │                    │
│           │ POST /generate                     │ POST /redeem       │
│           └────────────────┬────────────────────┘                   │
│                            │                                        │
└─────────────────────────────┼────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER (Dart)                            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│     AfricanPrepaymentCodeService                                   │
│     ├─ generateAfricanCodes()        [Admin only]                  │
│     ├─ redeemAfricanCode()           [Authenticated]               │
│     ├─ getCodeStatus()               [Public]                      │
│     ├─ getCodesByRegion()            [Admin]                       │
│     ├─ getCodesByPlan()              [Admin]                       │
│     ├─ getActiveCodes()              [Admin]                       │
│     ├─ getAfricanCodeStats()         [Admin]                       │
│     ├─ isValidCodeFormat()           [Public]                      │
│     ├─ parseCode()                   [Public]                      │
│     ├─ exportCodesAsCSV()            [Admin]                       │
│     └─ getAllSupportedCountries()    [Public]                      │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND (PostgreSQL)                     │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────┐  ┌──────────────────────────┐     │
│  │  african_prepayment_codes   │  │  Audit Trail             │     │
│  │                             │  │  & Distribution          │     │
│  │ Fields:                     │  │                          │     │
│  │ • id (UUID)                 │  │ • Redemption audit       │     │
│  │ • code (VARCHAR)            │  │ • Batch distribution     │     │
│  │ • region (VARCHAR(2))       │  │ • Admin logs             │     │
│  │ • plan_id (VARCHAR)         │  │                          │     │
│  │ • duration (VARCHAR)        │  │ Tables:                  │     │
│  │ • status (active/redeemed)  │  │ • african_code_..._audit │     │
│  │ • created_at                │  │ • african_code_dist...   │     │
│  │ • expires_at                │  │                          │     │
│  │ • redeemed_by               │  │                          │     │
│  │ • redeemed_at               │  │                          │     │
│  │ • metadata (JSONB)          │  │                          │     │
│  │                             │  │                          │     │
│  │ Indexes: 6                  │  │ Indexes: 7               │     │
│  │ RLS: 3 policies             │  │ RLS: 2 policies          │     │
│  └─────────────────────────────┘  └──────────────────────────┘     │
│                                                                      │
│  All tables with RLS enabled:                                       │
│  • Row Level Security policies enforce auth                         │
│  • Admins can generate/view all codes                               │
│  • Users can view only their redemptions                            │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Code Generation Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   ADMIN: GENERATE CODES FLOW                    │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│  Admin navigates to /admin/african-codes     │
│  (Must be authenticated & admin role)        │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Loads Dashboard:                            │
│  • Total codes: 5000                         │
│  • Active codes: 3200                        │
│  • Redeemed: 1800                            │
│  • Redemption rate: 36%                      │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Fills Generation Form:                      │
│  1. Select Plan                              │
│     - Solo Trades ($9.99/mo)                 │
│     - Small Team ($15/mo)                    │
│     - Workshop ($29/mo)                      │
│  2. Select Duration                          │
│     - 1M (30 days)                           │
│     - 3M (90 days)                           │
│     - 6M (180 days)                          │
│     - 1Y (365 days)                          │
│  3. Select Regions (Multi-select)            │
│     - 54 African countries available         │
│  4. Enter Quantity                           │
│     - 1-1000 codes                           │
│  5. Add Description (Optional)               │
│     - Campaign name or purpose               │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Click "Generate Codes" Button               │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Service: generateAfricanCodes()             │
│                                              │
│  For each code:                              │
│  1. Generate random 6-char suffix            │
│     - Cryptographically secure               │
│     - A-Z, 0-9 only                          │
│  2. Create code: AURA-XX-YYYY-XM-ABC123     │
│  3. Calculate expiry: NOW + (12 × duration)  │
│  4. Set status: 'active'                     │
│  5. Store metadata                           │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Database Insert:                            │
│  INSERT INTO african_prepayment_codes        │
│    (code, region, plan_id, duration,         │
│     status, created_at, expires_at, ...)     │
│                                              │
│  Validation:                                 │
│  - UNIQUE constraint on code                 │
│  - Region must be in 54 supported            │
│  - Status in (active, redeemed, expired)     │
│  - Duration in (1M, 3M, 6M, 1Y)              │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Return Success Response:                    │
│  {                                           │
│    "success": true,                          │
│    "codes_generated": 50,                    │
│    "sample_code": "AURA-NG-2026-3M-ABC123", │
│    "codes": [... array of 50 codes ...]      │
│  }                                           │
└─────────────────┬──────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  Display Generated Codes:                    │
│  • Show list of codes                        │
│  • "Copy to Clipboard" button                │
│  • "Download as CSV" button                  │
│  • Success message                           │
│  • Next steps guide                          │
└──────────────────────────────────────────────┘
```

---

## Code Redemption Flow

```
┌──────────────────────────────────────────────────────────────┐
│              CUSTOMER: REDEEM CODE FLOW                      │
└──────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Customer visits /african-code-redemption   │
│  (Can be logged in or new)                  │
└────────────┬────────────────────────────────┘
             │
             ▼
    ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
    │ STEP 1: ENTER CODE                  │
    └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘
             │
             ├─ Form Elements:
             │  • Text input field
             │  • Format example: AURA-XX-YYYY-XM-XXXXXX
             │  • Character counter
             │  • Error display area
             │  • Validate button
             │
             ▼
    ┌──────────────────────────────────────┐
    │  Validation (Client-side):           │
    │  • Check format: isValidCodeFormat() │
    │  • Show error if invalid             │
    │  • Block submission if invalid       │
    └────────┬─────────────────────────────┘
             │
             ▼ Valid
    ┌──────────────────────────────────────┐
    │  Call: getCodeStatus(code)           │
    │                                      │
    │  Checks:                             │
    │  • Code exists in database           │
    │  • Status is 'active' (not redeemed) │
    │  • Not expired (expires_at > NOW)    │
    └────────┬─────────────────────────────┘
             │
             ├─ Valid ──────────────────┐
             │                          │
             │  Invalid ────────────┐   │
             │                      │   │
             ▼                      ▼   ▼
    ┌────────────────────┐  ┌──────────────────┐
    │ STEP 2: VERIFY     │  │ Show Error Msg   │
    │                    │  │ & Clear Form     │
    │ Details & Country  │  └──────────────────┘
    │ Selection          │
    └────┬───────────────┘
         │
         ├─ Display:
         │  • Code: AURA-NG-2026-3M-ABC123
         │  • Country: Nigeria ✓
         │  • Plan: Solo Trades
         │  • Duration: 3 months
         │  • Valid Until: [date]
         │  • Status badge: "Code is valid"
         │
         ├─ User selects country:
         │  • Quick select buttons (NG, KE, ZA, etc.)
         │  • Or manual selection
         │
         ▼
    ┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
    │ STEP 3: CONFIRM DETAILS             │
    └─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘
         │
         ├─ Display Summary:
         │  • Code: AURA-NG-2026-3M-ABC123
         │  • Country: Nigeria
         │  • Plan: Solo Trades ($9.99/mo)
         │  • Duration: 3 months (90 days)
         │  • Subscription Start: Today
         │  • Subscription End: 3 months from today
         │  • Agree to Terms ✓
         │
         ▼
    ┌──────────────────────────────────────┐
    │ Click "Activate Subscription"        │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ Authenticate User (if needed):       │
    │ • Login if not authenticated         │
    │ • Create account if new user         │
    │ • Get user ID for audit trail        │
    └────────┬─────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────────────┐
    │ Service: redeemAfricanCode()         │
    │                                      │
    │ Database Transaction:                │
    │ 1. Lock code row                     │
    │ 2. Verify still active               │
    │ 3. Update status → 'redeemed'        │
    │ 4. Set redeemed_by = user_id         │
    │ 5. Set redeemed_at = NOW             │
    │ 6. Insert audit log entry            │
    │ 7. Unlock row                        │
    └────────┬─────────────────────────────┘
             │
             ├─ Success ──────┐
             │                │
             │  Error ─────┐  │
             │             │  │
             ▼             ▼  ▼
    ┌──────────────┐ ┌──────────────┐
    │ STEP 4:      │ │ Show Error   │
    │ SUCCESS      │ │ & Retry      │
    │ ✅ Confirm   │ └──────────────┘
    │ • Animation  │
    │ • Dates      │
    │ • Redirect   │
    └──────────────┘
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPLETE DATA FLOW                               │
└─────────────────────────────────────────────────────────────────────┘

GENERATION SIDE                              REDEMPTION SIDE
──────────────────────────────────────────────────────────────────

Admin                                         Customer
  │                                             │
  ├─ Plan selection                            ├─ Code entry
  ├─ Region selection                          ├─ Country detection
  ├─ Duration choice                           └─ Form submission
  ├─ Quantity input                                    │
  └─ Description (optional)                          ▼
         │                                    Validation Layer
         ▼                                     ├─ Format check
  Validation Layer                            ├─ Database lookup
  ├─ Quantity range (1-1000)                 ├─ Status check
  ├─ Duration valid (1M/3M/6M/1Y)            ├─ Expiry check
  ├─ Regions all exist (54)                  └─ Region check
  └─ Plan ID valid (3 plans)                        │
         │                                          ▼
         ▼                                    ┌──────────────────┐
  Code Generation                             │  DECISION POINT   │
  ├─ Random suffix (6 chars)                 │  Code Valid?      │
  ├─ Format: AURA-XX-YYYY-XM-XX...          ├─ Yes → Proceed   │
  ├─ Expiry = NOW + 12x duration             └─ No → Error msg  │
  ├─ Status = 'active'                              │
  └─ Metadata creation                             ▼
         │                                   Redemption Process
         ▼                                   ├─ Authenticate user
  Database Insert                            ├─ Lock code row
  ├─ african_prepayment_codes                ├─ Verify status
  ├─ Validate constraints                    ├─ Update status
  ├─ Check UNIQUE on code                    ├─ Log user ID
  └─ Create indexes                          └─ Insert audit entry
         │                                          │
         ▼                                          ▼
  Success Response                           Subscription Created
  ├─ codes_generated                         ├─ org created
  ├─ sample_code                             ├─ plan set
  ├─ codes array                             ├─ expires_at set
  └─ Return to UI                            └─ User redirected
         │                                          │
         ▼                                          ▼
  Admin Display                               Customer Dashboard
  ├─ List of codes                           ├─ Subscription active
  ├─ Copy button                             ├─ Expiry date shown
  ├─ Download CSV                            └─ Features enabled
  └─ Send to customers
```

---

## Database Schema Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                  AFRICAN PREPAYMENT CODES SCHEMA                │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  african_prepayment_codes (MAIN TABLE)           │
├──────────────────────────────────────────────────┤
│ PK: id (UUID)                                    │
│ UQ: code                                         │
├──────────────────────────────────────────────────┤
│ Code Identity:                                   │
│ ├─ code (VARCHAR) - AURA-XX-YYYY-XM-XXXXXX      │
│ ├─ region (VARCHAR(2)) - Country code           │
│ ├─ country_name (VARCHAR) - Full name           │
│ ├─ year (computed from code)                    │
│ └─ metadata (JSONB) - Custom data               │
│                                                  │
│ Plan & Duration:                                │
│ ├─ plan_id (VARCHAR) - solo_trades,             │
│ │                      small_team,              │
│ │                      workshop                 │
│ ├─ duration (VARCHAR) - 1M/3M/6M/1Y             │
│ └─ duration_days (INT) - 30/90/180/365          │
│                                                  │
│ Lifecycle:                                      │
│ ├─ status (VARCHAR) - active/redeemed/expired   │
│ ├─ created_at (TIMESTAMP) - Generation time     │
│ ├─ expires_at (TIMESTAMP) - 12x duration        │
│ ├─ redeemed_by (UUID) - User who redeemed       │
│ └─ redeemed_at (TIMESTAMP) - Redemption time    │
│                                                  │
│ Administration:                                 │
│ ├─ generated_by (UUID) - Admin user             │
│ └─ description (TEXT) - Campaign name           │
│                                                  │
│ Indexes (6 total):                             │
│ ├─ idx_african_codes_code (code)                │
│ ├─ idx_african_codes_status (status)            │
│ ├─ idx_african_codes_region (region)            │
│ ├─ idx_african_codes_plan (plan_id)             │
│ ├─ idx_african_codes_redeemed_by (redeemed_by) │
│ └─ idx_african_codes_expires_at (expires_at)   │
│                                                  │
│ Constraints (3 total):                         │
│ ├─ valid_region (54 country codes)              │
│ ├─ valid_duration (1M|3M|6M|1Y)                 │
│ └─ valid_status (active|redeemed|expired)       │
└──────────────────────────────────────────────────┘
         │                    │
         │ References         │ Referenced by
         │                    │
         ▼                    ▼
┌──────────────────────────┐ ┌──────────────────────────────┐
│ Auth Users (foreign key) │ │ african_code_redemption_audit│
└──────────────────────────┘ ├──────────────────────────────┤
                              │ PK: id (UUID)                │
                              │ FK: code_id → codes.id       │
                              │ FK: redeemed_by → users.id   │
                              │ FK: org_id → orgs.id         │
                              ├──────────────────────────────┤
                              │ • code (VARCHAR)              │
                              │ • region (VARCHAR(2))         │
                              │ • plan_id (VARCHAR)           │
                              │ • subscription_start (TS)     │
                              │ • subscription_end (TS)       │
                              │ • ip_address (INET)           │
                              │ • user_agent (TEXT)           │
                              │ • status (success/failed)     │
                              │ • error_message (TEXT)        │
                              │ • created_at (TIMESTAMP)      │
                              │                              │
                              │ Indexes (5):                 │
                              │ ├─ idx_audit_code_id         │
                              │ ├─ idx_audit_redeemed_by     │
                              │ ├─ idx_audit_org_id          │
                              │ ├─ idx_audit_region          │
                              │ └─ idx_audit_created_at      │
                              └──────────────────────────────┘

┌──────────────────────────────────────────────────┐
│  african_code_distribution (BATCH TRACKING)      │
├──────────────────────────────────────────────────┤
│ PK: id (UUID)                                    │
│ UQ: batch_id                                     │
├──────────────────────────────────────────────────┤
│ • batch_id (VARCHAR) - Unique batch ID           │
│ • generated_by (UUID) - Admin user               │
│ • plan_id (VARCHAR) - Plan for batch             │
│ • regions (TEXT[]) - ['NG', 'KE', ...]          │
│ • duration (VARCHAR) - 1M/3M/6M/1Y               │
│ • quantity (INT) - Number of codes               │
│ • created_at (TIMESTAMP)                         │
│ • description (TEXT)                             │
│ • distribution_method (VARCHAR)                  │
│ • distributed_at (TIMESTAMP)                     │
│ • distributed_by (UUID)                          │
│                                                  │
│ Indexes (3):                                     │
│ ├─ idx_distribution_batch_id                    │
│ ├─ idx_distribution_generated_by                │
│ └─ idx_distribution_created_at                  │
└──────────────────────────────────────────────────┘
```

---

## State Machine Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                  CODE STATUS STATE MACHINE                       │
└──────────────────────────────────────────────────────────────────┘

                       ┌─────────────┐
                       │   CREATED   │ (Initial state)
                       └──────┬──────┘
                              │
                    Generated by admin
                    (inserted in DB)
                              │
                              ▼
                    ┌──────────────────┐
                    │     ACTIVE       │ ✓ Available for redemption
                    │  (status=active) │
                    └────────┬─────────┘
                             │
                 ┌───────────┼───────────┐
                 │           │           │
            Redeemed    Expiry time    Manual revoke
             by user     reached        (future feature)
                 │           │           │
                 ▼           ▼           ▼
            ┌────────┐ ┌────────┐ ┌────────┐
            │REDEEMED│ │EXPIRED │ │REVOKED │ ✗ No longer usable
            │(final) │ │(final) │ │(future)│
            └────────┘ └────────┘ └────────┘


┌──────────────────────────────────────────────────────────────────┐
│           REDEMPTION PROCESS STATE MACHINE                       │
└──────────────────────────────────────────────────────────────────┘

    Entry ──┐
            │
            ▼
    ┌──────────────┐
    │   PENDING    │ (User entering code)
    └──────┬───────┘
           │
     Format │ Validate
      Check │
           │
     ┌─────┴─────┐
     │           │
   Valid      Invalid
     │           │
     ▼           ▼
  ┌────┐    ┌──────┐
  │OK  │    │Error │ ──────┐
  └─┬──┘    └──────┘       │
    │                      │
    │                      ▼
    │                  ┌─────────┐
    │                  │ RESET   │
    │                  │ (retry) │
    │                  └─────────┘
    │
 Database │ Lookup
    │
    ├─ Not found ──────────┐
    │                      │
    ├─ Already redeemed ───┼─────┐
    │                      │     │
    ├─ Expired ────────────┤     │
    │                      │     │
    └─ Status ≠ active ────┤     │
                           │     │
                    ┌──────┘     │
                    │            │
                    ▼            │
            ┌────────────┐       │
            │ERROR SHOWN │       │
            └────────────┘       │
                                 │
                         ┌───────┘
                         │
                         ▼
                    ┌──────────┐
                    │  RETRY   │
                    └──────────┘


            ┌─────────────┐
            │   VALID     │ (Code can be redeemed)
            └──────┬──────┘
                   │
          User     │
        Confirms   │
                   │
                   ▼
            ┌─────────────────┐
            │ UPDATING DATABASE │
            └────────┬─────────┘
                     │
           ┌─────────┴─────────┐
           │                   │
       Success             Failure
           │                   │
           ▼                   ▼
       ┌────────┐         ┌─────────┐
       │SUCCESS │         │ ERROR   │
       │SHOWING │         │ SHOWN   │
       │SCREEN  │         └─────────┘
       └────┬───┘
            │
     Redirect to
      Dashboard
            │
            ▼
       ┌──────────┐
       │ COMPLETE │
       └──────────┘
```

---

## Integration Points

```
┌─────────────────────────────────────────────────────────────────┐
│        INTEGRATION WITH MAIN AURA CRM SYSTEM                   │
└─────────────────────────────────────────────────────────────────┘

┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│ LANDING PAGE                                                   │
│                                                                │
│  "Sign Up" ──────────────┐                                    │
│                          │                                    │
│  "Have an activation     │                                    │
│   code?" ────────────────┼─→ /african-code-redemption        │
│                          │                                    │
│                          ▼                                    │
│                   ┌──────────────────┐                        │
│                   │ Code Redemption  │                        │
│                   │ Page (4-step)    │                        │
│                   └────────┬─────────┘                        │
│                            │                                  │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
                             │
                    SUCCESS ──┴─→ ┌────────────────────┐
                                  │ Create Org Record: │
                    FAILURE ──────→│ • user_id          │
                                  │ • plan (from code) │
                                  │ • expires_at       │
                                  │ • payment_method   │
                                  │   = 'african_code' │
                                  └────────┬───────────┘
                                           │
                                           ▼
                                  ┌──────────────────┐
                                  │ Redirect to      │
                                  │ Home Dashboard   │
                                  └──────────────────┘


┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│ ADMIN DASHBOARD                                                │
│                                                                │
│  Settings → African Codes ─────→ /admin/african-codes         │
│                                                                │
│                                  ┌──────────────────────────┐ │
│                                  │ Admin Page:              │ │
│                                  │ • Statistics dashboard   │ │
│                                  │ • Code generation form   │ │
│                                  │ • Region multi-select    │ │
│                                  │ • Duration selector      │ │
│                                  │ • View active codes      │ │
│                                  │ • Export as CSV          │ │
│                                  └──────────────────────────┘ │
│                                                                │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘


┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│ DATABASE INTEGRATION                                           │
│                                                                │
│  organizations table:                                          │
│  ├─ user_id (auth.users)                                      │
│  ├─ plan (solo_trades, small_team, workshop)                  │
│  ├─ subscription_end (DATE) ◄─── From code redemption        │
│  ├─ payment_method ('african_code') ◄─── New field           │
│  └─ status (active, cancelled, expired)                       │
│                                                                │
│  auth.users table:                                             │
│  └─ id (UUID) ──────────────────────→ redeemed_by in codes   │
│                                                                │
│  african_code_redemption_audit:                               │
│  ├─ org_id ─────→ organizations.id                            │
│  ├─ redeemed_by ─→ auth.users.id                              │
│  └─ code_id ────→ african_prepayment_codes.id                 │
│                                                                │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘


┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┐
│ ROUTES IN main.dart                                            │
│                                                                │
│  routes: {                                                     │
│    '/african-code-redemption': (context) =>                   │
│      const AfricanCodeRedemptionSignupPage(),                 │
│    '/admin/african-codes': (context) =>                       │
│      const AfricanCodeGenerationPage(),                       │
│    // ... other existing routes ...                           │
│  }                                                             │
│                                                                │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┘
```

---

## Deployment Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│               DEPLOYMENT ARCHITECTURE                           │
└──────────────────────────────────────────────────────────────────┘

LOCAL DEVELOPMENT
────────────────────────────
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Flutter CLI              │
│ └─ flutter run -d chrome │
│                          │
│ Hot Reload Enabled ✓     │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
         │
         │ (localhost:54321)
         ▼
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Supabase Local           │
│ (Dev environment)        │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘


STAGING ENVIRONMENT
────────────────────────────
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Flutter Web Build        │
│ (flutter build web)      │
│                          │
│ Output: build/web/       │
└─────┬────────────────────┘
      │
      ▼
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Firebase Hosting         │
│ (Staging Bucket)         │
└─────┬────────────────────┘
      │ (staging URL)
      ▼
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Supabase Staging DB      │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘


PRODUCTION ENVIRONMENT
────────────────────────────
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Flutter Web Build        │
│ --release                │
│ (optimized/minified)     │
│                          │
│ Output: build/web/       │
│ Size: ~12-15 MB          │
└─────┬────────────────────┘
      │
      ▼
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Firebase Hosting         │
│ (Production)             │
│ or Vercel, Netlify, etc  │
└─────┬────────────────────┘
      │ (production URL)
      ▼
┌─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│ Supabase Production DB   │
│                          │
│ • Automatic backups      │
│ • Point-in-time restore  │
│ • 99.99% uptime SLA      │
│ • SSL encryption         │
└─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘


DEPLOYMENT PIPELINE
────────────────────────────────────────────
    Code Commit
         │
         ▼
    Run Tests (CI)
         │
    ┌────┴────┐
    │          │
  Pass      Fail
    │          │
    ▼          ▼
  Build   Show Error
    │
    ▼
  Deploy to Staging
    │
    ▼
  Manual Testing
    │
    ├── Approve
    │   │
    │   ▼
    │ Deploy to Production
    │
    └── Reject
        │
        ▼
      Fix Issues
      (Back to Commit)
```

---

**Diagrams Created:** January 5, 2026  
**Status:** Complete ✅  
**Total Diagrams:** 8 (System Architecture, Flows, State Machines, Integration, Deployment)
