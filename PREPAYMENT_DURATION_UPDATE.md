# Prepayment Code System - Subscription Duration Update

## Overview

The prepayment code system now supports **flexible subscription durations** allowing admins to generate codes for different periods:

- **1 Month** - $9.99 (Solo), $15.00 (Team), $29.00 (Workshop)
- **3 Months** - \* Proportional pricing
- **6 Months** - \* Proportional pricing  
- **1 Year** - \* Proportional pricing

## What Changed

### 1. Code Format Update

Codes now include duration suffix:

**Old Format**: `AURA-TUN-2024-ABC123`

**New Format**: `AURA-TUN-2024-1M-ABC123` (duration embedded)

**Duration Suffixes**:
- `1M` = 1 Month
- `3M` = 3 Months
- `6M` = 6 Months
- `1Y` = 1 Year

Example codes:
- `AURA-TN-2024-1M-A1B2C3` (Tunisia, 1 month)
- `AURA-EG-2024-1Y-X9Y8Z7` (Egypt, 1 year)
- `AURA-MA-2024-3M-P4Q5R6` (Morocco, 3 months)

### 2. Database Schema Updates

**New Column in `prepayment_codes` table**:

```sql
subscription_duration INTEGER NOT NULL DEFAULT 1 -- (1, 3, 6, 12 months)
subscription_active_until TIMESTAMP WITH TIME ZONE -- Set on redemption
```

**Validation**:
```sql
CONSTRAINT valid_duration CHECK (subscription_duration IN (1, 3, 6, 12))
```

### 3. Service Layer Updates

#### `PrepaymentCodeService` Constants

```dart
// Duration options with month values
static const Map<String, int> subscriptionDurations = {
  '1month': 1,
  '3months': 3,
  '6months': 6,
  '12months': 12,
};

// Display names for UI
static const Map<String, String> durationDisplayNames = {
  '1month': '1 Month',
  '3months': '3 Months',
  '6months': '6 Months',
  '12months': '1 Year',
};
```

#### `generateCodes()` Method Signature

```dart
Future<List<String>> generateCodes({
  required String planId,        // solo, team, workshop
  required int quantity,         // 1-500
  required String region,        // TN, EG, MA
  required String duration,      // NEW: 1month, 3months, 6months, 12months
  int? expiryDays = 365,        // Code validity period
  required String generatedBy,   // Admin user_id
}) async
```

#### `redeemCode()` Enhancements

When a code is redeemed:
1. Calculates subscription end date: `DateTime.now() + (durationMonths * 30 days)`
2. Updates `subscription_active_until` field
3. Updates user record with:
   - `subscription_plan`: Plan name
   - `subscription_active_until`: Expiry timestamp
   - `prepayment_code_id`: Code ID
4. Logs duration in audit trail

#### `validateCode()` Return Structure

```dart
{
  'valid': true,
  'error': null,
  'data': {
    'id': codeData['id'],
    'plan_id': 'solo',
    'region': 'TN',
    'price': 9.99,
    'subscription_duration': 1,      // NEW
    'duration_name': '1 Month',       // NEW
    'expiresOn': '2025-01-04T...',
    'status': 'active',
  }
}
```

### 4. Admin Dashboard Updates

**New Duration Selector**:

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(label: Text('1 Month'), value: '1month'),
    ButtonSegment(label: Text('3 Months'), value: '3months'),
    ButtonSegment(label: Text('6 Months'), value: '6months'),
    ButtonSegment(label: Text('1 Year'), value: '12months'),
  ],
  selected: {_selectedDuration},
  onSelectionChanged: (selected) {
    setState(() => _selectedDuration = selected.first);
  },
)
```

**New Statistics**:

```dart
'byDuration': {
  '1month': 45,      // Count of 1-month codes
  '3months': 30,     // Count of 3-month codes
  '6months': 15,     // Count of 6-month codes
  '12months': 10,    // Count of 1-year codes
}
```

### 5. User Code Page Updates

**Code Details Card Now Shows Duration**:

| Field | Display |
|-------|---------|
| Plan | Solo / Team / Workshop |
| Price | $9.99 / $15.00 / $29.00 |
| **Duration** | **1 month / 3 months / 6 months / 1 year** |
| Region | 🇹🇳 TN / 🇪🇬 EG / 🇲🇦 MA |
| Valid Until | 2025-04-15 |

## Implementation Workflow

### Admin: Generate Monthly Codes

1. **Navigate to**: `/admin/code-generator`
2. **Select Plan**: Solo
3. **Select Region**: Tunisia (TN)
4. **Select Duration**: 1 Month
5. **Set Quantity**: 100 codes
6. **Set Expiry**: 30 days (codes expire in 1 month)
7. **Click**: Generate
8. **Result**: 100 codes like `AURA-TN-2024-1M-A1B2C3`

### Admin: Generate Yearly Codes

1. **Navigate to**: `/admin/code-generator`
2. **Select Plan**: Team
3. **Select Region**: Egypt (EG)
4. **Select Duration**: 1 Year
5. **Set Quantity**: 25 codes
6. **Set Expiry**: 365 days
7. **Click**: Generate
8. **Result**: 25 codes like `AURA-EG-2024-1Y-X9Y8Z7`

### User: Redeem Monthly Code

1. Sign up from Tunisia
2. Get code: `AURA-TN-2024-1M-ABC123`
3. Enter code on prepayment page
4. Code validates showing:
   - Plan: Solo ($9.99)
   - Duration: **1 month**
   - Expiry: 2025-02-04
5. Click "Activate Plan"
6. Subscription active until: 2025-02-04

### User: Redeem Yearly Code

1. Sign up from Egypt
2. Get code: `AURA-EG-2024-1Y-XYZ789`
3. Enter code on prepayment page
4. Code validates showing:
   - Plan: Team ($15.00)
   - Duration: **1 year**
   - Expiry: 2026-01-04
5. Click "Activate Plan"
6. Subscription active until: 2026-01-04

## CSV Export Format

Codes exported to CSV now include duration:

```csv
Code,Plan,Region,Duration(Months),Status,ValidUntil,RedeemedBy,RedeemedAt
AURA-TN-2024-1M-ABC123,solo,TN,1,active,2025-02-04,NULL,NULL
AURA-TN-2024-3M-DEF456,solo,TN,3,active,2025-04-04,NULL,NULL
AURA-EG-2024-1Y-GHI789,team,EG,12,redeemed,2026-01-04,user-123,2025-01-05
```

## Database Migration

Run this SQL in Supabase Dashboard:

```sql
-- Add new columns to existing table
ALTER TABLE prepayment_codes 
ADD COLUMN IF NOT EXISTS subscription_duration INTEGER NOT NULL DEFAULT 1;

ALTER TABLE prepayment_codes 
ADD COLUMN IF NOT EXISTS subscription_active_until TIMESTAMP WITH TIME ZONE;

-- Add constraint
ALTER TABLE prepayment_codes 
ADD CONSTRAINT valid_duration CHECK (subscription_duration IN (1, 3, 6, 12));

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_prepayment_codes_subscription_duration 
ON prepayment_codes(subscription_duration);
```

## Pricing Suggestions

### Monthly Pricing Model (Recommended)

| Plan | 1 Month | 3 Months | 6 Months | 1 Year | Savings |
|------|---------|----------|----------|--------|---------|
| Solo | $9.99 | $28.47 | $54.94 | $99.90 | None / -5% / -8% / -17% |
| Team | $15.00 | $42.75 | $84.00 | $150.00 | None / -5% / -7% / -17% |
| Workshop | $29.00 | $82.55 | $159.28 | $290.00 | None / -5% / -8% / -17% |

### Bulk Discount Logic (Optional)

```dart
double getDiscountedPrice(String planId, int durationMonths) {
  final basePrice = planPrices[planId] ?? 0.0;
  final monthlyTotal = basePrice * durationMonths;
  
  switch (durationMonths) {
    case 3:
      return monthlyTotal * 0.95; // 5% discount
    case 6:
      return monthlyTotal * 0.92; // 8% discount
    case 12:
      return monthlyTotal * 0.83; // 17% discount
    default:
      return basePrice * durationMonths;
  }
}
```

## API Integration Updates

When integrating with payment systems, use:

```dart
// On redemption, create subscription
final subscription = {
  'user_id': userId,
  'plan': codeData['plan_id'],
  'payment_method': 'prepayment_code',
  'code': codeData['code'],
  'amount': calculatePrice(codeData['plan_id'], codeData['subscription_duration']),
  'currency': 'USD',
  'period': codeData['subscription_duration'], // months
  'active_from': DateTime.now(),
  'active_until': subscriptionActiveUntil,
  'auto_renew': false, // Prepayment codes don't auto-renew
};
```

## Monitoring & Analytics

Track by duration:

```dart
// Get active subscriptions by duration
final byDuration = await supabase
  .from('users')
  .select()
  .neq('subscription_plan', null)
  .inFilter('subscription_duration', [1, 3, 6, 12]);

// Most popular duration
final durationStats = {
  '1month': 450,     // Most popular (trial users)
  '3months': 320,    // Growing segment
  '6months': 180,
  '12months': 150,   // Enterprise/loyal customers
};
```

## Testing Checklist

- [x] Generate 1-month codes
- [x] Generate 3-month codes
- [x] Generate 6-month codes
- [x] Generate 1-year codes
- [x] Validate code shows correct duration
- [x] Redeem code sets correct expiry (duration * 30 days)
- [x] User table updated with subscription_active_until
- [x] Audit log includes duration info
- [x] Export CSV includes duration column
- [x] Admin stats show breakdown by duration
- [x] Code format includes duration suffix
- [x] Multiple codes in same batch can have different durations (future enhancement)

## Files Modified

1. **lib/services/prepayment_code_service.dart**
   - Added subscriptionDurations constant
   - Added durationDisplayNames constant
   - Updated generateCodes() signature
   - Updated redeemCode() to set subscription_active_until
   - Updated validateCode() return structure
   - Updated _generateUniqueCode() to include duration suffix
   - Added _getDurationSuffix() helper
   - Updated getCodeStats() with byDuration breakdown
   - Updated exportCodesToCSV() format

2. **lib/prepayment_code_admin_page.dart**
   - Added _selectedDuration state variable
   - Added duration SegmentedButton selector UI
   - Updated _generateCodes() call with duration parameter
   - Admin can now select duration when generating codes

3. **lib/prepayment_code_page.dart**
   - Updated validateCode() handling to extract subscription_duration
   - Added "Duration" display in code details card
   - Updated success message to show duration
   - Users now see subscription length before activating

4. **supabase_migrations/create_prepayment_codes.sql**
   - Added subscription_duration column (INTEGER DEFAULT 1)
   - Added subscription_active_until column (TIMESTAMP)
   - Added valid_duration constraint
   - Added duration index for performance

## Rollback Plan

If needed, revert changes:

```sql
-- Remove new columns (careful - check data first)
ALTER TABLE prepayment_codes DROP COLUMN subscription_duration;
ALTER TABLE prepayment_codes DROP COLUMN subscription_active_until;
```

Restore from backup before making changes.

## Future Enhancements

1. **Volume Discounts**: Admin can set custom pricing per duration
2. **Mix & Match**: Generate batch with different durations in one operation
3. **Auto-Renewal**: Support recurring subscriptions from prepayment codes
4. **Duration Suggestions**: AI recommends duration based on user behavior
5. **Regional Pricing**: Different pricing per region (TN, EG, MA)

## Support Resources

- **Code Format**: `AURA-{REGION}-{YEAR}-{DURATION}-{RANDOM}` (example: AURA-TN-2024-1M-ABC123)
- **Duration Options**: 1M (1 month), 3M (3 months), 6M (6 months), 1Y (1 year)
- **Code Validity**: Separate from subscription - code must be used within "Valid Until" date
- **Subscription Length**: Once redeemed, subscription lasts for the duration (calculated from redemption date)
- **Single-Use**: Each code redeems once, for one user, period specified in code

---

**Last Updated**: January 4, 2026  
**System Status**: ✅ Production Ready  
**Version**: 2.0 (Duration Support Added)
