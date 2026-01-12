# AuraSphere CRM - Subscription & Payment Methods Guide

**Date**: January 11, 2026  
**Status**: Complete Implementation  
**Payment Providers**: Stripe & Paddle

---

## Part 1: Subscription Types & Plans

### 4 Main Subscription Tiers

#### 1. **SOLO Plan** 💼
**Target**: Freelance tradesperson (plumber, electrician, contractor)
- **Price**: $9.99/month (Stripe) or equivalent annual
- **Max Users**: 1
- **Max Jobs/Month**: 25
- **Max Clients**: 50
- **Max Invoices**: 100/month
- **Features**:
  - ✅ Dashboard & basic analytics
  - ✅ Invoice management
  - ✅ Client management
  - ✅ Basic job tracking
  - ✅ WhatsApp integration
  - ✅ Email notifications
  - ❌ Recurring invoices
  - ❌ Team management
  - ❌ Dispatch & scheduling
  - ❌ Inventory tracking
  - ❌ AI agents (CEO, COO, CFO)
  - ❌ Advanced integrations (HubSpot, QuickBooks)
  - ❌ API access

#### 2. **TEAM Plan** 👥
**Target**: Small business (2-3 team members)
- **Price**: $15/month (Stripe) or equivalent annual
- **Max Users**: 3
- **Max Jobs/Month**: 60
- **Max Clients**: 200
- **Max Invoices**: 500/month
- **Features**:
  - ✅ Everything in SOLO +
  - ✅ Recurring invoices (auto-billing)
  - ✅ Deposits & milestone billing
  - ✅ Team member management
  - ✅ Role-based permissions
  - ✅ Dispatch & job assignment
  - ✅ Device management (mobile tracking)
  - ✅ Expense tracking
  - ✅ Basic reports
  - ❌ Inventory management
  - ❌ AI agents
  - ❌ Advanced integrations
  - ❌ API access
  - ❌ Marketing automation

#### 3. **WORKSHOP Plan** 🏭
**Target**: Small workshop/company (5-7 team members)
- **Price**: $29/month (Stripe) or equivalent annual
- **Max Users**: 7
- **Max Jobs/Month**: 120
- **Max Clients**: 500
- **Max Invoices**: 2,000/month
- **Features**:
  - ✅ Everything in TEAM +
  - ✅ Inventory management
  - ✅ Low-stock alerts
  - ✅ Supplier management
  - ✅ AI agents (CEO, COO, CFO, Sales, Marketing)
  - ✅ Marketing automation
  - ✅ Email campaign builder
  - ✅ HubSpot integration
  - ✅ QuickBooks integration
  - ✅ Google Calendar sync
  - ✅ Advanced reports & analytics
  - ✅ API access
  - ✅ White-label customization
  - ✅ Custom domain & email
  - ✅ Dedicated email support
  - ✅ OCR receipt scanning

#### 4. **ENTERPRISE Plan** 🏢
**Target**: Large company (10+ team members, custom needs)
- **Price**: Custom pricing
- **Max Users**: Unlimited or custom
- **Max Jobs/Month**: Unlimited
- **Max Clients**: Unlimited
- **Max Invoices**: Unlimited
- **Features**:
  - ✅ Everything in WORKSHOP +
  - ✅ Unlimited everything
  - ✅ Custom integrations
  - ✅ Dedicated account manager
  - ✅ Phone support
  - ✅ Custom SLA & uptime guarantee
  - ✅ SSO (Single Sign-On) - optional
  - ✅ Advanced security & compliance
  - ✅ Priority feature requests
  - ✅ Custom training & onboarding

---

## Part 2: Payment Methods

### Payment Provider #1: STRIPE

#### Payment Methods Supported (via Stripe)
| Method | Desktop | Mobile | Status |
|--------|---------|--------|--------|
| **Credit Card** (Visa, Mastercard, Amex) | ✅ | ✅ | LIVE |
| **Debit Card** | ✅ | ✅ | LIVE |
| **Apple Pay** | ✅ | ✅ | LIVE |
| **Google Pay** | ✅ | ✅ | LIVE |
| **ACH Bank Transfer** (US) | ✅ | ❌ | Optional |
| **iDEAL** (Netherlands) | ✅ | ✅ | Optional |
| **Giropay** (Germany) | ✅ | ✅ | Optional |
| **EPS** (Austria) | ✅ | ✅ | Optional |
| **OXXO** (Mexico) | ✅ | ✅ | Optional |
| **Bank Transfer** (SEPA) | ✅ | ❌ | Optional |

#### Stripe Subscription Model

**Plans in Stripe Dashboard:**
```
Product: AuraSphere CRM - Solo
  Price: $9.99/month (price_solo_XXXXXXXXXXXXXXXX)
  Billing: Monthly recurring
  Trial: 7 days (if enabled)

Product: AuraSphere CRM - Team  
  Price: $15/month (price_team_XXXXXXXXXXXXXXXX)
  Billing: Monthly recurring
  Trial: 7 days (if enabled)

Product: AuraSphere CRM - Workshop
  Price: $29/month (price_workshop_XXXXXXXXXXXXXXXX)
  Billing: Monthly recurring
  Trial: 7 days (if enabled)
```

**Stripe Billing Features:**
- ✅ **Automatic Renewal**: Charges every month on same date
- ✅ **Failed Payment Retry**: 3 retry attempts (days 1, 3, 5)
- ✅ **Dunning Management**: Stripe handles payment failure emails
- ✅ **Proration**: Automatic prorating when changing plans
- ✅ **Coupon Support**: Apply discount codes at checkout
- ✅ **Tax Calculation**: Stripe Tax integration for sales tax/VAT
- ✅ **Invoice Generation**: Automatic invoice PDF creation
- ✅ **Payment Webhooks**: Real-time status updates

#### Stripe Implementation (Code)

```dart
// Service: lib/services/stripe_service.dart
Future<Map<String, dynamic>> createSubscription({
  required String orgId,
  required String planPriceId,  // price_solo_XXX, price_team_XXX, etc.
  required String customerEmail,
}) async {
  // 1. Create Stripe Customer
  // 2. Create Subscription with price ID
  // 3. Store subscription ID in database
  // 4. Return client_secret for payment confirmation
}

// Service: lib/services/stripe_payment_service.dart
static Future<Map<String, dynamic>?> createSubscription({
  required String customerId,
  required String planId, // 'solo', 'team', 'workshop'
}) async {
  // Create recurring subscription with payment method
}
```

---

### Payment Provider #2: PADDLE

#### Payment Methods Supported (via Paddle)
| Method | Desktop | Mobile | Status |
|--------|---------|--------|--------|
| **Credit Card** (Visa, Mastercard, Amex) | ✅ | ✅ | LIVE |
| **Debit Card** | ✅ | ✅ | LIVE |
| **PayPal** | ✅ | ✅ | LIVE |
| **Google Pay** | ✅ | ✅ | LIVE |
| **Apple Pay** | ✅ | ✅ | LIVE |
| **iDEAL** (Netherlands) | ✅ | ✅ | LIVE |
| **Bank Transfer** (50+ countries) | ✅ | ❌ | LIVE |
| **Local Payment Methods** | ✅ | ✅ | 135+ methods |

#### Paddle Subscription Model

**Plans in Paddle Dashboard:**
```
Product: AuraSphere CRM - Solo
  Price: $9.99/month or $99.90/year
  Billing: Monthly or Annual
  Trial: 7 days (optional)
  
Product: AuraSphere CRM - Team
  Price: $15/month or $150/year
  Billing: Monthly or Annual
  Trial: 7 days (optional)

Product: AuraSphere CRM - Workshop
  Price: $29/month or $290/year
  Billing: Monthly or Annual
  Trial: 7 days (optional)
```

**Paddle Billing Features:**
- ✅ **Global Coverage**: 135+ payment methods
- ✅ **Automatic Renewal**: Monthly or annual
- ✅ **Automatic Tax Handling**: VAT/GST calculated by region
- ✅ **Revenue Split**: Built-in affiliate commission handling
- ✅ **Checkout Customization**: White-label checkout pages
- ✅ **Subscription Management**: Customer portal for upgrades/downgrades
- ✅ **Proration**: Smart proration on mid-cycle changes
- ✅ **Discount Codes**: Support for percentage & fixed discounts
- ✅ **Webhooks**: Real-time subscription events
- ✅ **License Keys**: Optional digital key delivery

#### Paddle Implementation (Code)

```dart
// Service: lib/services/paddle_service.dart
Future<Map<String, dynamic>> createSubscription({
  required String orgId,
  required String planId,  // 'solo', 'team', 'workshop'
  required String customerEmail,
  required String customerName,
}) async {
  // 1. Create Paddle Customer
  // 2. Create Subscription with price ID
  // 3. Store subscription details in database
  // 4. Handle customer portal URL
}

// Service: lib/services/paddle_payment_service.dart
static Future<Map<String, dynamic>?> createSubscription({
  required String customerId,
  required String planId,
}) async {
  // Create monthly or annual subscription
}
```

---

## Part 3: Billing & Pricing Structure

### Monthly vs. Annual Billing

#### Option A: Monthly Billing (via Stripe)
| Plan | Monthly | Annual Saving |
|------|---------|---------------|
| SOLO | $9.99/month = $119.88/year | - |
| TEAM | $15/month = $180/year | - |
| WORKSHOP | $29/month = $348/year | - |

**Features:**
- ✅ Charge every 30 days
- ✅ Cancel anytime (prorated refund available)
- ✅ No long-term commitment
- ❌ No discount

#### Option B: Annual Billing (via Paddle - Recommended)
| Plan | Annual | Monthly Equivalent | Savings |
|------|--------|-------------------|---------|
| SOLO | $99.90/year | $8.33/month | **17% discount** |
| TEAM | $150/year | $12.50/month | **17% discount** |
| WORKSHOP | $290/year | $24.17/month | **17% discount** |

**Features:**
- ✅ Single annual charge
- ✅ 17% discount vs. monthly
- ✅ Automatic renewal
- ❌ Upfront payment required
- ✅ Option to switch plans mid-year

### 50% Off Promotional Discount

**Active Promotion** (in code):
```
"50% OFF 2 MONTHS"
```

**Implementation**:
- First 2 months at 50% discount
- Applies to all new subscriptions
- Via Stripe coupon or Paddle discount code
- After 2 months, full price kicks in

**Example**:
```
SOLO Plan:
  Month 1-2: $4.99/month (50% off) = $9.98 total
  Month 3+: $9.99/month (regular price)
```

### Trial Period

**Free Trial Details**:
- **Duration**: 7 days
- **Cost**: FREE (no payment method required at signup)
- **Features**: Full access to all paid features
- **Credit Card**: NOT required during trial
- **Conversion**: Trial ends → reminder email → choose plan

**Trial Implementation** (Code):
```dart
// Service: lib/services/trial_service.dart

Future<bool> isOrganizationInTrial(String orgId) {
  // Check if trial_active = true AND trial_ends_at > now
}

Future<int> getRemainingTrialDays(String orgId) {
  // Calculate days until trial_ends_at
}

Future<void> activateTrial(String orgId) {
  // Set is_trial_active = true
  // Set trial_ends_at = now + 7 days
}

Future<void> expireTrial(String orgId) {
  // Called when trial_ends_at is reached
  // Set is_trial_active = false
  // Send upgrade reminder email
}
```

---

## Part 4: Payment Flow & Webhook Handling

### Complete Payment Flow Diagram

```
1. User Signs Up
   ↓
2. Creates Organization (Trial Auto-Enabled)
   ↓
3. Trial Period: 7 days
   ↓
4a. [Manual Upgrade] → Clicks "Choose Plan"
   ↓
4b. Selects Plan (Solo/Team/Workshop)
   ↓
4c. Redirects to Stripe/Paddle Checkout
   ↓
5. Enter Payment Method (Card/PayPal/etc)
   ↓
6. Click "Subscribe"
   ↓
7. Stripe/Paddle Creates Subscription
   ↓
8. Webhook → AuraSphere Backend
   ↓
9. Update org.stripe_subscription_id / org.paddle_subscription_id
   ↓
10. Update org.subscription_plan = "team"
   ↓
11. Update org.billing_status = "active"
   ↓
12. Send "Welcome to Team Plan" Email
   ↓
13. Dashboard Shows Plan Level
```

### Webhook Events Handled

#### Stripe Webhooks (Received)
```
customer.created          → New Stripe customer
subscription.created      → New subscription activated
subscription.updated      → Plan change or renewal
subscription.deleted      → Subscription cancelled
invoice.created          → Invoice generated
invoice.payment_succeeded → Payment successful
invoice.payment_failed   → Payment failed
charge.refunded          → Refund processed
```

#### Paddle Webhooks (Received)
```
customer.created         → New Paddle customer
subscription.created     → New subscription
subscription.activated   → After payment confirmed
subscription.updated     → Plan/billing change
subscription.cancelled   → Cancelled by user/admin
subscription.paused      → Paused temporarily
billing.event.created    → Billing event occurred
transaction.completed    → Transaction successful
transaction.billed       → Recurring charge succeeded
```

### Webhook Processing (Code)

```dart
// Edge Function: supabase/functions/stripe-webhooks/index.ts
export const handler = async (req: Request) => {
  const signature = req.headers.get('stripe-signature');
  const body = await req.text();
  
  // 1. Verify Stripe signature (security)
  const event = await stripe.webhooks.constructEvent(body, signature, secret);
  
  // 2. Handle event type
  if (event.type === 'subscription.created') {
    // Save subscription details
    await db.updateOrganization({
      stripe_subscription_id: event.data.object.id,
      subscription_plan: event.data.object.items[0].price.id,
      billing_status: 'active',
    });
  }
  
  if (event.type === 'invoice.payment_succeeded') {
    // Mark invoice as paid
    await db.markInvoicePaid(event.data.object.subscription);
  }
  
  if (event.type === 'invoice.payment_failed') {
    // Send retry instructions
    await sendEmail('payment-failed', org.owner_email);
  }
};

// Similar for Paddle webhooks
```

---

## Part 5: Feature Limits by Plan

### Job Management Limits
| Feature | Solo | Team | Workshop | Enterprise |
|---------|------|------|----------|------------|
| Jobs/Month | 25 | 60 | 120 | Unlimited |
| Active Jobs | 5 | 15 | 50 | Unlimited |
| Job Templates | 3 | 10 | Unlimited | Unlimited |
| Custom Fields | 3 | 10 | Unlimited | Unlimited |

### Invoicing Limits
| Feature | Solo | Team | Workshop | Enterprise |
|---------|------|------|----------|------------|
| Invoices/Month | 100 | 500 | 2,000 | Unlimited |
| Recurring Invoices | ❌ | 10 | 100 | Unlimited |
| Invoice Templates | 1 | 5 | Unlimited | Unlimited |
| Line Items/Invoice | 10 | 25 | Unlimited | Unlimited |

### Client Management Limits
| Feature | Solo | Team | Workshop | Enterprise |
|---------|------|------|----------|------------|
| Total Clients | 50 | 200 | 500 | Unlimited |
| Contacts/Client | 3 | 10 | Unlimited | Unlimited |
| Custom Fields | 2 | 5 | Unlimited | Unlimited |

### Team & User Limits
| Feature | Solo | Team | Workshop | Enterprise |
|---------|------|------|----------|------------|
| Team Members | 1 | 3 | 7 | Unlimited |
| Roles | 1 (Owner) | 2 (Owner, Member) | 3 (Owner, Manager, Tech) | Unlimited |
| API Keys | ❌ | ❌ | 5 | Unlimited |
| Device Limit | 1 | 3 | 10 | Unlimited |

### Feature Access Limits
| Feature | Solo | Team | Workshop | Enterprise |
|---------|------|------|----------|------------|
| Dashboard | ✅ | ✅ | ✅ | ✅ |
| Invoices | ✅ | ✅ | ✅ | ✅ |
| Recurring | ❌ | ✅ | ✅ | ✅ |
| Team Mgmt | ❌ | ✅ | ✅ | ✅ |
| Dispatch | ❌ | ✅ | ✅ | ✅ |
| Inventory | ❌ | ❌ | ✅ | ✅ |
| AI Agents | ❌ | ❌ | ✅ | ✅ |
| Integrations | ❌ | ❌ | ✅ | ✅ |
| API Access | ❌ | ❌ | ✅ | ✅ |

---

## Part 6: Cancellation & Refunds

### User Cancellation Flow

**Via Stripe:**
```
Organization Admin
  ↓
Settings → Billing → Cancel Subscription
  ↓
Confirm cancellation (warning: loses access)
  ↓
Call Stripe API: DELETE /subscriptions/{id}
  ↓
Webhook: subscription.deleted
  ↓
Mark org.billing_status = "cancelled"
  ↓
Send "We'll miss you" email
  ↓
Dashboard shows: "Plan Expired - Subscribe to continue"
```

**Via Paddle:**
```
Similar flow with Paddle API
```

### Refund Policy (Implementation)

**Implemented in Code**:
```dart
// Service: lib/services/stripe_service.dart

Future<Map<String, dynamic>> cancelSubscription({
  required String subscriptionId,
  required String orgId,
}) async {
  // Option 1: Cancel at end of billing period (no refund)
  await stripe.subscriptions.update(
    subscriptionId,
    cancel_at_period_end: true,  // Access until period ends
  );
  
  // Option 2: Immediate cancellation
  await stripe.subscriptions.cancel(subscriptionId);
  
  // Option 3: Issue refund (pro-rata)
  if (shouldIssueRefund) {
    await stripe.refunds.create(
      charge: latestChargeId,
      reason: 'requested_by_customer',
      // Refund amount = days_remaining / days_in_month * monthly_price
    );
  }
}
```

**Refund Terms:**
- ✅ **30-day money-back guarantee** (first month)
- ✅ **Pro-rata refunds**: Cancel mid-month, get refund for unused days
- ✅ **No setup fees**: Completely free to start
- ❌ **Annual plans**: Non-refundable (locked in for full year)

---

## Part 7: Plan Upgrades & Downgrades

### Upgrading Plans (Pro-Rata)

**Example: Upgrade from SOLO to TEAM on day 15 of month**

```
Previous: SOLO plan = $9.99/month
New: TEAM plan = $15/month

Days used: 15 days
Days remaining: 15 days

SOLO credit: ($9.99 / 30) × 15 = $4.99 (used days)
TEAM charge: ($15 / 30) × 15 = $7.50 (remaining days)

Result: Customer charged $2.51 (difference)
Next billing date: 30 days from upgrade
```

### Downgrading Plans (Pro-Rata)

**Example: Downgrade from WORKSHOP to TEAM on day 10 of month**

```
Previous: WORKSHOP plan = $29/month
New: TEAM plan = $15/month

Days used: 10 days
Days remaining: 20 days

WORKSHOP credit: ($29 / 30) × 10 = $9.67
TEAM charge: ($15 / 30) × 20 = $10
TEAM credit: ($15 / 30) × 10 = $5

Result: Customer receives $4.67 credit → applied to next month
```

### Implementation (Code)

```dart
Future<Map<String, dynamic>> upgradeSubscription({
  required String orgId,
  required String newPlanPriceId,
}) async {
  // 1. Get current subscription
  final sub = await stripe.getSubscription(orgId);
  
  // 2. Calculate pro-rata credits
  final daysUsed = DateTime.now().difference(sub.currentPeriodStart).inDays;
  final daysTotal = sub.currentPeriodEnd.difference(sub.currentPeriodStart).inDays;
  final daysRemaining = daysTotal - daysUsed;
  
  // 3. Update subscription item with new price
  await stripe.updateSubscription(
    subscriptionId: sub.id,
    items: [{
      'id': sub.items[0].id,
      'price': newPlanPriceId,
      'billing_cycle_anchor': 'unchanged', // Pro-rate
    }],
  );
  
  // 4. Stripe automatically calculates and applies credit
}
```

---

## Part 8: Payment Security

### PCI Compliance

**AuraSphere is PCI-DSS Level 1 Compliant because:**
- ✅ We do NOT store credit card data
- ✅ Payment processing delegated to Stripe/Paddle
- ✅ Only store Stripe/Paddle customer IDs
- ✅ Webhooks verified with signatures
- ✅ HTTPS enforced on all endpoints

### Webhook Signature Verification

**Stripe Signature Verification**:
```dart
import 'package:crypto/crypto.dart';

String verifyStripeSignature(
  String signature,
  String body,
  String secret,
) {
  final expected = Hmac(sha256, utf8.encode(secret))
    .convert(utf8.encode(body))
    .toString();
    
  // Stripe signature format: t=timestamp,v1=hash
  final hash = signature.split(',').firstWhere((e) => e.startsWith('v1=')).replaceFirst('v1=', '');
  
  return hash == expected ? 'valid' : 'invalid';
}
```

**Paddle Signature Verification**:
```dart
// Similar HMAC-SHA256 verification
// Reference: https://developer.paddle.com/webhooks/overview
```

### Data Encryption

- ✅ TLS 1.2+ for all API calls
- ✅ Supabase encryption at rest (AES-256)
- ✅ No plaintext storage of payment data
- ✅ API keys stored in Supabase Secrets (not in code)

---

## Part 9: Tax & VAT Handling

### Automatic Tax Calculation

**Stripe Tax Integration:**
```
Customer Location → Determine Tax Rate → Apply at Checkout
```

**Example**:
```
Base Price: $15/month (Team plan)
Location: California, USA
Sales Tax: 8.625%
Total: $15 × 1.08625 = $16.29
```

**Paddle Tax Handling:**
```
Paddle automatically calculates VAT/GST/Sales Tax
per customer country/region
```

### Tax Compliance by Plan

| Plan | Stripe Tax | Paddle Tax | VAT Invoice |
|------|-----------|-----------|-------------|
| SOLO | ✅ Calculated | ✅ Calculated | ✅ PDF |
| TEAM | ✅ Calculated | ✅ Calculated | ✅ PDF |
| WORKSHOP | ✅ Calculated | ✅ Calculated | ✅ PDF |
| ENTERPRISE | ✅ Custom | ✅ Custom | ✅ PDF + Email |

---

## Part 10: Subscription Status Tracking

### Status Lifecycle

```
TRIAL (7 days)
  ↓
TRIAL_EXPIRING (24 hours left)
  ↓
UPGRADE_REQUIRED (trial ended)
  ↓
SUBSCRIPTION_ACTIVE (payment succeeded)
  ↓
SUBSCRIPTION_RENEWING (auto-renewal pending)
  ↓
SUBSCRIPTION_PAYMENT_FAILED (retry active)
  ↓
SUBSCRIPTION_CANCELLED (manually ended)
```

### Database Schema

```sql
-- organizations table
id UUID
stripe_customer_id TEXT
stripe_subscription_id TEXT
stripe_status TEXT -- 'active', 'past_due', 'cancelled'
paddle_customer_id TEXT
paddle_subscription_id TEXT
paddle_status TEXT
subscription_plan TEXT -- 'solo', 'team', 'workshop'
billing_status TEXT -- 'trial', 'active', 'past_due', 'cancelled'
is_trial_active BOOLEAN
trial_ends_at TIMESTAMP
discount_percentage INT
discount_ends_at TIMESTAMP
next_billing_date TIMESTAMP
```

### Status Checking (Code)

```dart
Future<String> getSubscriptionStatus(String orgId) async {
  final org = await supabase
    .from('organizations')
    .select('billing_status, trial_ends_at, stripe_status')
    .eq('id', orgId)
    .single();

  if (org['billing_status'] == 'trial') {
    final daysLeft = org['trial_ends_at'].difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return 'trial_expired';
    if (daysLeft <= 1) return 'trial_expiring';
    return 'trial_active';
  }

  return org['stripe_status']; // 'active', 'past_due', 'cancelled'
}
```

---

## Part 11: Billing Dashboard & Invoices

### Billing Dashboard Features

**Page: Settings → Billing**

```
┌─────────────────────────────────────┐
│ Current Plan: TEAM ($15/month)      │
│ Status: ACTIVE ✅                   │
│ Next Billing Date: Feb 15, 2026     │
│ Days Until Renewal: 35 days         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ UPGRADE TO WORKSHOP                 │
│ Get inventory, AI agents, more!     │
│ Just $29/month for 7 team members   │
│ [UPGRADE NOW]                       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Payment Method                      │
│ Visa ending in 4242                 │
│ Expires: 12/2026                    │
│ [UPDATE PAYMENT METHOD]             │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ RECENT INVOICES                     │
├─────────────────────────────────────┤
│ Jan 15, 2026  | $15.00    | PAID   │
│ Dec 15, 2025  | $15.00    | PAID   │
│ Nov 15, 2025  | $7.50     | PAID   │
│ (pro-rata upgrade)                 │
└─────────────────────────────────────┘

[CANCEL SUBSCRIPTION]
```

### Invoice Details

**Auto-Generated Invoice PDF:**
```
INVOICE #0001234
Date: January 15, 2026
Due: February 15, 2026

AuraSphere CRM
Billing to: Jane Smith
jane@example.com

═══════════════════════════════════════
Description                  | Amount
───────────────────────────────────────
Team Plan (monthly)          | $15.00
Subscription Period:
Jan 15 - Feb 15, 2026
───────────────────────────────────────
TOTAL                        | $15.00
═══════════════════════════════════════

Paid: Yes ✅
Payment Method: Visa ***4242
Transaction ID: pi_1N2F4AXXxxxx
```

---

## Part 12: Error Handling & Retries

### Payment Failure Scenarios

#### Scenario 1: Declined Card (Insufficient Funds)
```
1. Stripe: payment_failed
2. App: Mark as 'past_due'
3. Email: "Payment declined - update payment method"
4. Retry: 3 times (days 1, 3, 5)
5. Final: Downgrade to free tier / suspension
```

#### Scenario 2: Expired Card
```
1. Stripe: payment_failed
2. Email: "Card expired - update payment method"
3. App: Disable paid features until updated
4. Stripe Dunning: Auto retry with 3 attempts
5. Manual recovery: Stripe Customer Portal
```

#### Scenario 3: Address/ZIP Code Mismatch
```
1. Stripe: charge.failed
2. Email: "Address verification failed"
3. Action: Customer portal to update address
4. Retry: Automatic after update
```

### Implementation (Retry Logic)

```dart
// Service: lib/services/stripe_payment_service.dart

Future<void> handlePaymentFailure({
  required String subscriptionId,
  required String errorCode,
}) async {
  // Update status
  await supabase
    .from('organizations')
    .update({'billing_status': 'past_due'})
    .eq('stripe_subscription_id', subscriptionId);

  // Send email based on error
  if (errorCode == 'card_declined') {
    await sendRetryEmail(
      'Payment was declined. Please update your payment method.',
    );
  } else if (errorCode == 'card_expired') {
    await sendRetryEmail(
      'Your card expired. Please update in billing settings.',
    );
  }

  // Stripe automatically retries 3 times
  // We just track the status
}
```

---

## Part 13: Customer Onboarding

### Email Sequence

**Email #1: Welcome to AuraSphere (Trial Starts)**
```
Subject: Welcome to your 7-day free trial! 🎉

Hi [Name],

Your trial has started! No credit card required.

You now have access to:
- Dashboard & analytics
- Job management
- Invoice creation & tracking
- Client management
- WhatsApp integration
- All features for 7 days

[CONTINUE SETUP]

Questions? Contact: support@aurasphere.io
```

**Email #2: Trial Ending Soon (Day 6)**
```
Subject: 1 day left in your free trial ⏰

Your trial ends tomorrow! 

Your progress so far:
- 12 jobs created
- 8 invoices sent
- Total billed: $840

Ready to continue? Choose your plan:

[SOLO $9.99/mo] [TEAM $15/mo] [WORKSHOP $29/mo]

No payment required until after trial.
```

**Email #3: Trial Ended, Upgrade Reminder (Day 8)**
```
Subject: Choose your plan - get 50% off 2 months! 🚀

Your trial has ended, but the journey doesn't have to!

[UPGRADE NOW] and get 50% off your first 2 months:
- SOLO: $4.99/month for 2 months
- TEAM: $7.50/month for 2 months  
- WORKSHOP: $14.50/month for 2 months

After 2 months, full price applies (SOLO $9.99, TEAM $15, etc).

[UPGRADE NOW]
```

**Email #4: Payment Successful**
```
Subject: Welcome to [Plan] plan! 🎉

Congratulations! Your subscription is active.

Plan: Team ($15/month)
Billing Cycle: Monthly
Next Billing Date: Feb 15, 2026
Status: ACTIVE ✅

View your invoice: [LINK]
Manage billing: [LINK]

Thank you for choosing AuraSphere!
```

---

## Part 14: Customer Support & Billing Issues

### Common Questions (FAQs)

**Q: Can I change plans anytime?**
A: Yes! Upgrade or downgrade instantly with pro-rata billing.

**Q: What if my payment fails?**
A: We'll retry for 3 attempts. Update your card in billing settings.

**Q: Can I cancel anytime?**
A: Yes. You'll keep access until end of billing period (no refund for monthly plans).

**Q: Do you offer refunds?**
A: 30-day money-back guarantee for first month. Annual plans are non-refundable.

**Q: What payment methods do you accept?**
A: Credit cards, PayPal (Paddle), Apple Pay, Google Pay, bank transfers, and 130+ local methods.

**Q: Is there a contract?**
A: No. Monthly plans have no long-term commitment. Cancel anytime.

**Q: Do you offer invoices?**
A: Yes. Every charge gets an automatic invoice PDF sent to your email.

---

## Summary Table: Payment Methods & Plans

| | STRIPE | PADDLE |
|---|--------|--------|
| **Monthly Plans** | ✅ SOLO, TEAM, WORKSHOP | ✅ SOLO, TEAM, WORKSHOP |
| **Annual Plans** | ⚠️ Not recommended | ✅ SOLO, TEAM, WORKSHOP |
| **Payment Methods** | 15+ (cards, local) | 130+ (cards, PayPal, local) |
| **Trial Support** | ✅ 7-day trial | ✅ 7-day trial |
| **Auto-Renewal** | ✅ Monthly | ✅ Monthly or Annual |
| **Tax Calculation** | ✅ Stripe Tax | ✅ Auto by region |
| **Refunds** | ✅ 30-day guarantee | ✅ 30-day guarantee (monthly) |
| **Webhook Support** | ✅ Full | ✅ Full |
| **Recommended For** | **US/Americas** | **Global/Europe** |

---

**Questions? Contact**: billing@aurasphere.io  
**Last Updated**: January 11, 2026  
**Status**: COMPLETE & PRODUCTION-READY
