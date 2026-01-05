# African Prepayment Code System - Technical Reference

## API Reference

### AfricanPrepaymentCodeService

#### Constructor
```dart
final codeService = AfricanPrepaymentCodeService();
// Singleton pattern - always returns same instance
```

---

## Method Reference

### 1. generateAfricanCodes()
**Purpose:** Generate a batch of prepayment codes for distribution

**Signature:**
```dart
Future<Map<String, dynamic>> generateAfricanCodes({
  required String planId,
  required int quantity,
  required String duration,
  required List<String> regions,
  required String generatedBy,
  String? description,
})
```

**Parameters:**
| Name | Type | Required | Values | Notes |
|------|------|----------|--------|-------|
| `planId` | String | Yes | `solo_trades`, `small_team`, `workshop` | Plan to activate |
| `quantity` | int | Yes | 1-1000 | Number of codes to generate |
| `duration` | String | Yes | `1M`, `3M`, `6M`, `1Y` | Subscription period |
| `regions` | List<String> | Yes | Any of 54 country codes | Distribution regions |
| `generatedBy` | String | Yes | UUID | Admin user ID |
| `description` | String? | No | Any string | Campaign name/notes |

**Return:**
```dart
{
  'success': bool,              // true if successful
  'codes_generated': int,       // Number of codes created
  'regions': List<String>,      // Regions used
  'duration': String,           // Duration used
  'plan_id': String,           // Plan ID
  'sample_code': String,       // Example code
  'codes': List<String>,       // All generated codes
  'error': String?             // Error message if failed
}
```

**Example:**
```dart
final result = await codeService.generateAfricanCodes(
  planId: 'solo_trades',
  quantity: 50,
  duration: '3M',
  regions: ['NG', 'KE', 'ZA'],
  generatedBy: userId,
  description: 'Q1 2026 Campaign - Partnership with XYZ',
);

if (result['success']) {
  print('Generated ${result['codes_generated']} codes');
  result['codes'].forEach((code) => print(code));
} else {
  print('Error: ${result['error']}');
}
```

---

### 2. redeemAfricanCode()
**Purpose:** Validate and redeem a single prepayment code

**Signature:**
```dart
Future<Map<String, dynamic>> redeemAfricanCode({
  required String code,
  required String userId,
  required String userCountry,
})
```

**Parameters:**
| Name | Type | Required | Notes |
|------|------|----------|-------|
| `code` | String | Yes | Full code: AURA-XX-YYYY-XM-XXXXXX |
| `userId` | String | Yes | User UUID redeeming code |
| `userCountry` | String | Yes | 2-letter ISO country code |

**Return:**
```dart
{
  'success': bool,                    // true if redeemed
  'code': String,                     // Code that was redeemed
  'plan_id': String,                  // Activated plan
  'duration': String,                 // Subscription duration
  'duration_days': int,               // Days in subscription
  'region': String,                   // Region code
  'country_name': String,             // Full country name
  'subscription_start': String,       // ISO datetime
  'subscription_end': String,         // ISO datetime
  'message': String,                  // Success message
  'error': String?                    // Error message if failed
}
```

**Example:**
```dart
final result = await codeService.redeemAfricanCode(
  code: 'AURA-NG-2026-3M-ABC123',
  userId: currentUserId,
  userCountry: 'NG',
);

if (result['success']) {
  print('✅ Subscription activated!');
  print('Access until: ${result['subscription_end']}');
  
  // Create organization record
  await supabase.from('organizations').insert({
    'user_id': currentUserId,
    'plan': result['plan_id'],
    'subscription_end': result['subscription_end'],
    'payment_method': 'african_code',
  });
} else {
  print('❌ ${result['error']}');
}
```

---

### 3. getCodeStatus()
**Purpose:** Check status of any code (public method)

**Signature:**
```dart
Future<Map<String, dynamic>> getCodeStatus(String code)
```

**Parameters:**
| Name | Type | Required | Notes |
|------|------|----------|-------|
| `code` | String | Yes | Code to check |

**Return:**
```dart
{
  'found': bool,              // Code exists
  'code': String,             // Code format
  'status': String,           // active, redeemed, expired
  'region': String,           // Country code
  'country_name': String,     // Full country name
  'plan_id': String,          // Plan type
  'duration': String,         // Duration
  'created_at': String,       // Creation timestamp
  'expires_at': String,       // Expiry timestamp
  'is_expired': bool,         // Already expired?
  'redeemed_at': String?,     // When redeemed (null if unused)
  'error': String?            // Error if query failed
}
```

**Example:**
```dart
final status = await codeService.getCodeStatus('AURA-NG-2026-3M-ABC123');

if (status['found']) {
  print('Code Status: ${status['status']}');
  print('Country: ${status['country_name']}');
  print('Expires: ${status['expires_at']}');
} else {
  print('Code not found');
}
```

---

### 4. redeemAfricanCode() - Error Cases

**Possible Errors:**
| Error | Cause | Solution |
|-------|-------|----------|
| "Code not found" | Invalid code or typo | Verify code format |
| "Code has already been redeemed" | Single-use enforced | Cannot reuse codes |
| "Code has expired" | 12x duration passed | Generate new codes |
| "This code is only valid in African countries" | Non-African IP | Check country detection |

---

### 5. getAfricanCodeStats()
**Purpose:** Get comprehensive statistics about all codes

**Signature:**
```dart
Future<Map<String, dynamic>> getAfricanCodeStats()
```

**Return:**
```dart
{
  'total_codes': int,                  // All codes ever generated
  'active_codes': int,                 // Unused codes still valid
  'redeemed_codes': int,               // Codes successfully used
  'redemption_rate': String,           // Percentage format "36.00%"
  'supported_countries': int,          // Total 54
  'codes_per_region': Map<String, int>, // NG: 1200, KE: 800, ...
  'supported_durations': List<String>,  // 1M, 3M, 6M, 1Y
  'supported_plans': List<String>,      // solo_trades, small_team, workshop
  'error': String?                      // Error if query failed
}
```

**Example:**
```dart
final stats = await codeService.getAfricanCodeStats();

print('Total Codes: ${stats['total_codes']}');
print('Active: ${stats['active_codes']}');
print('Redeemed: ${stats['redeemed_codes']}');
print('Redemption Rate: ${stats['redemption_rate']}');

// Top regions
(stats['codes_per_region'] as Map<String, int>)
    .entries
    .take(5)
    .forEach((e) => print('${e.key}: ${e.value}'));
```

---

### 6. getCodesByRegion()
**Purpose:** Get all codes for a specific region (admin)

**Signature:**
```dart
Future<List<Map<String, dynamic>>> getCodesByRegion(
  String region,
  {int limit = 100}
)
```

**Parameters:**
| Name | Type | Default | Notes |
|------|------|---------|-------|
| `region` | String | - | 2-letter country code |
| `limit` | int | 100 | Max results to return |

**Example:**
```dart
final nigerianCodes = await codeService.getCodesByRegion('NG', limit: 500);
print('Found ${nigerianCodes.length} codes in Nigeria');

nigerianCodes.forEach((code) {
  print('${code['code']}: ${code['status']}');
});
```

---

### 7. getActiveCodes()
**Purpose:** Get all currently active (unused) codes

**Signature:**
```dart
Future<List<Map<String, dynamic>>> getActiveCodes({int limit = 500})
```

**Return:** List of code records with status 'active'

**Example:**
```dart
final activeCodes = await codeService.getActiveCodes(limit: 1000);
print('${activeCodes.length} codes available');

// Export to CSV
final csv = codeService.exportCodesAsCSV(activeCodes);
```

---

### 8. getCodesByPlan()
**Purpose:** Get all codes for a specific plan

**Signature:**
```dart
Future<List<Map<String, dynamic>>> getCodesByPlan(
  String planId,
  {int limit = 500}
)
```

**Parameters:**
| Name | Type | Notes |
|------|------|-------|
| `planId` | String | solo_trades, small_team, or workshop |
| `limit` | int | Max results |

**Example:**
```dart
final teamPlanCodes = await codeService.getCodesByPlan('small_team');
print('${teamPlanCodes.length} Small Team codes available');
```

---

### 9. isValidCodeFormat()
**Purpose:** Check if code matches expected format (before DB query)

**Signature:**
```dart
bool isValidCodeFormat(String code)
```

**Return:** true if matches AURA-XX-YYYY-XM-XXXXXX pattern

**Example:**
```dart
if (codeService.isValidCodeFormat(userInput)) {
  // Safe to query database
} else {
  // Show error: Invalid format
}
```

---

### 10. parseCode()
**Purpose:** Extract components from a code

**Signature:**
```dart
Map<String, String>? parseCode(String code)
```

**Return:**
```dart
{
  'region': 'NG',        // 2-letter country code
  'year': '2026',        // 4-digit year
  'duration': '3M',      // 1M, 3M, 6M, or 1Y
  'random': 'ABC123'     // 6-char random suffix
}
// Or null if format invalid
```

**Example:**
```dart
final parts = codeService.parseCode('AURA-NG-2026-3M-ABC123');
if (parts != null) {
  print('Region: ${parts['region']}');
  print('Duration: ${parts['duration']}');
}
```

---

### 11. exportCodesAsCSV()
**Purpose:** Convert code list to CSV format for export

**Signature:**
```dart
String exportCodesAsCSV(List<Map<String, dynamic>> codes)
```

**Return:** CSV string with header and rows

**Format:**
```
Code,Region,Country,Plan,Duration,Status,Created,Expires
AURA-NG-2026-3M-ABC123,NG,Nigeria,solo_trades,3M,active,2026-01-05T10:00:00Z,2027-01-05T10:00:00Z
```

**Example:**
```dart
final activeCodes = await codeService.getActiveCodes();
final csv = codeService.exportCodesAsCSV(activeCodes);

// Save to file
final bytes = utf8.encode(csv);
// Use file_saver or similar to save
```

---

### 12. getCountryDetails()
**Purpose:** Get details about a specific country

**Signature:**
```dart
static Map<String, String> getCountryDetails(String regionCode)
```

**Return:**
```dart
{
  'code': 'NG',
  'name': 'Nigeria',
  'supported': true
}
```

**Example:**
```dart
final country = AfricanPrepaymentCodeService.getCountryDetails('NG');
print('${country['name']} (${country['code']})');
```

---

### 13. getAllSupportedCountries()
**Purpose:** Get list of all 54 supported countries

**Signature:**
```dart
static List<Map<String, String>> getAllSupportedCountries()
```

**Return:**
```dart
[
  {'code': 'EG', 'name': 'Egypt'},
  {'code': 'MA', 'name': 'Morocco'},
  // ... 52 more countries
]
```

**Example:**
```dart
final countries = AfricanPrepaymentCodeService.getAllSupportedCountries();
final dropdown = countries.map((c) => 
  DropdownMenuItem(
    value: c['code'],
    child: Text(c['name']!),
  )
).toList();
```

---

## Constants & Enums

### SUPPORTED_REGIONS
```dart
static const List<String> SUPPORTED_REGIONS = [
  // 54 countries across 5 regions
  'EG', 'MA', 'DZ', 'TN', 'LY', 'SD', 'MR',  // North Africa
  'NG', 'GH', 'CI', 'SN', 'ML', 'BF', 'BJ', 'TG', 'NE', 'GN', 'GW', 'LR', 'SL', 'CV', // West
  'CM', 'GA', 'CG', 'CD', 'TD', 'CF', 'ST', 'GQ', 'AO',  // Central
  'ET', 'KE', 'UG', 'TZ', 'RW', 'BI', 'SO', 'DJ', 'ER', 'SC', 'KM', // East
  'ZA', 'ZM', 'ZW', 'MW', 'MZ', 'NA', 'BW', 'LS', 'SZ', 'MU', 'MG', 'RE', 'YT' // Southern
];
```

### SUPPORTED_DURATIONS
```dart
static const List<String> SUPPORTED_DURATIONS = [
  '1M',  // 1 month (30 days)
  '3M',  // 3 months (90 days)
  '6M',  // 6 months (180 days)
  '1Y'   // 1 year (365 days)
];
```

### DURATION_DAYS
```dart
static const Map<String, int> DURATION_DAYS = {
  '1M': 30,
  '3M': 90,
  '6M': 180,
  '1Y': 365,
};
```

### PLAN_PRICES
```dart
static const Map<String, int> PLAN_PRICES = {
  'solo_trades': 999,    // $9.99
  'small_team': 1500,    // $15.00
  'workshop': 2900,      // $29.00
};
```

### COUNTRY_NAMES
```dart
static const Map<String, String> COUNTRY_NAMES = {
  'EG': 'Egypt',
  'MA': 'Morocco',
  'NG': 'Nigeria',
  'KE': 'Kenya',
  'ZA': 'South Africa',
  // ... all 54 countries
};
```

---

## Database Schema Reference

### african_prepayment_codes Table
```sql
CREATE TABLE african_prepayment_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(255) UNIQUE NOT NULL,
  region VARCHAR(2) NOT NULL,
  country_name VARCHAR(255) NOT NULL,
  plan_id VARCHAR(50) NOT NULL,
  duration VARCHAR(10) NOT NULL,
  duration_days INT NOT NULL,
  generated_by UUID NOT NULL REFERENCES auth.users(id),
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  redeemed_by UUID REFERENCES auth.users(id),
  redeemed_at TIMESTAMP,
  description TEXT,
  metadata JSONB DEFAULT '{}',
  
  CONSTRAINT valid_region CHECK (...),
  CONSTRAINT valid_duration CHECK (duration IN ('1M', '3M', '6M', '1Y')),
  CONSTRAINT valid_status CHECK (status IN ('active', 'redeemed', 'expired'))
);
```

**Query Examples:**
```sql
-- Get active codes for Nigeria
SELECT * FROM african_prepayment_codes 
WHERE region = 'NG' AND status = 'active'
ORDER BY created_at DESC;

-- Get redemption stats
SELECT 
  status,
  COUNT(*) as count,
  COUNT(*) FILTER (WHERE status = 'redeemed') as redeemed
FROM african_prepayment_codes
GROUP BY status;

-- Find codes expiring soon
SELECT code, expires_at FROM african_prepayment_codes
WHERE expires_at < NOW() + INTERVAL '7 days'
AND status != 'redeemed';
```

---

## Error Handling

### Common Error Responses
```dart
// Code not found
{
  'success': false,
  'error': 'Code not found'
}

// Already redeemed
{
  'success': false,
  'error': 'This code has already been redeemed',
  'redeemed_at': '2026-01-05T10:30:00Z'
}

// Code expired
{
  'success': false,
  'error': 'This code has expired'
}

// Invalid format
{
  'success': false,
  'error': 'Invalid code format. Expected: AURA-XX-YYYY-XM-ABC123'
}

// Invalid region
{
  'success': false,
  'error': 'Invalid region: ZZ'
}

// Invalid duration
{
  'success': false,
  'error': 'Invalid duration. Supported: 1M, 3M, 6M, 1Y'
}
```

### Try-Catch Pattern
```dart
try {
  final result = await codeService.redeemAfricanCode(
    code: code,
    userId: userId,
    userCountry: country,
  );
  
  if (result['success']) {
    // Handle success
  } else {
    // Handle failure (error key contains message)
    showError(result['error']);
  }
} catch (e) {
  // Network or database error
  print('❌ Error: $e');
  showError('An error occurred. Please try again.');
}
```

---

## Logging Reference

### Log Prefixes Used
```
🎟️  - Code generation/redemption operations
📋 - Data fetching/listing operations
📊 - Statistics and analytics
✅ - Successful operations
❌ - Errors
⚠️  - Warnings
🔍 - Verification/validation
🔄 - Processing in progress
💾 - Data saving
```

### Viewing Logs
```dart
// Monitor code generation
// grep '🎟️' logs.txt

// Monitor errors
// grep '❌' logs.txt

// Monitor stats queries
// grep '📊' logs.txt
```

---

## Performance Tips

### Optimization
1. **Use limits in queries** - Always specify `limit` parameter
2. **Index on status** - Filter by status first
3. **Cache statistics** - Don't recalculate every request
4. **Batch operations** - Generate 100+ codes at once
5. **Use RLS policies** - Let database handle filtering

### Query Performance
```sql
-- FAST: Uses index on status
SELECT * FROM african_prepayment_codes 
WHERE status = 'active' LIMIT 100;

-- SLOW: Full table scan
SELECT * FROM african_prepayment_codes 
WHERE code LIKE 'AURA-NG%' LIMIT 100;

-- FAST: Direct lookup by code
SELECT * FROM african_prepayment_codes 
WHERE code = 'AURA-NG-2026-3M-ABC123';
```

---

## Testing Reference

### Unit Test Example
```dart
test('generateAfricanCodes creates valid codes', () async {
  final result = await codeService.generateAfricanCodes(
    planId: 'solo_trades',
    quantity: 10,
    duration: '3M',
    regions: ['NG'],
    generatedBy: testUserId,
  );
  
  expect(result['success'], true);
  expect(result['codes_generated'], 10);
  expect(result['codes'], isNotEmpty);
  
  final firstCode = result['codes'][0];
  expect(codeService.isValidCodeFormat(firstCode), true);
});
```

### Integration Test Example
```dart
test('End-to-end code redemption', () async {
  // Generate
  final genResult = await codeService.generateAfricanCodes(
    planId: 'solo_trades',
    quantity: 1,
    duration: '1M',
    regions: ['NG'],
    generatedBy: adminId,
  );
  final code = genResult['codes'][0];
  
  // Redeem
  final redeemResult = await codeService.redeemAfricanCode(
    code: code,
    userId: userId,
    userCountry: 'NG',
  );
  
  expect(redeemResult['success'], true);
  expect(redeemResult['plan_id'], 'solo_trades');
  
  // Verify
  final status = await codeService.getCodeStatus(code);
  expect(status['status'], 'redeemed');
});
```

---

**Last Updated:** January 5, 2026  
**Version:** 1.0  
**Status:** Complete & Production Ready ✅
