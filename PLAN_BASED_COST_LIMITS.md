# Plan-Based AI Cost Limits Implementation

**Status**: ✅ **IMPLEMENTED & INTEGRATED**
**Date**: January 2025
**Updated**: Cost control system now enforces subscription-tier-specific limits

---

## Overview

AuraSphere CRM AI agents are now subject to **plan-based cost caps** that prevent users from exceeding their subscription tier's allocated budget. This prevents abuse and ensures predictable billing.

---

## Plan-Based Cost & API Limits

| Plan | Monthly Cost Limit | Monthly API Calls | Use Case |
|------|------|------|----------|
| **Solo** | $2.00 | 500 calls | Single owner, light AI usage |
| **Team** | $4.00 | 1,000 calls | Small team (2-3 users), moderate AI |
| **Workshop** | $6.00 | 1,500 calls | Larger team (7 users), heavy AI usage |
| **Trial / Free** | $2.00 | 500 calls | Evaluation period |

### Cost Calculation Example

**Groq API Pricing (per million tokens)**:
- Input: $0.05 per 1M tokens
- Output: $0.15 per 1M tokens
- Typical AI agent call: 2,000-4,000 tokens (input + output)
- Average cost per call: **$0.002 - $0.010**

**Solo Plan Example**:
- Monthly limit: $2.00
- Typical calls possible: 200-1,000 calls (depending on complexity)
- API call limit: Hard cap at 500 calls/month

---

## Technical Implementation

### 1. **Service Layer** (`lib/services/ai_automation_service.dart`)

#### Added Methods

**`getPlanCostLimit(String plan) → double`**
```dart
double getPlanCostLimit(String plan) {
  switch (plan.toLowerCase()) {
    case 'solo': return 2.0;         // $2/month
    case 'team': return 4.0;         // $4/month
    case 'workshop': return 6.0;     // $6/month
    case 'trial': 
    case 'free': return 2.0;
    default: return 2.0;
  }
}
```

**`getPlanApiCallLimit(String plan) → int`**
```dart
int getPlanApiCallLimit(String plan) {
  switch (plan.toLowerCase()) {
    case 'solo': return 500;         // 500 calls/month
    case 'team': return 1000;        // 1000 calls/month
    case 'workshop': return 1500;    // 1500 calls/month
    case 'trial': 
    case 'free': return 500;
    default: return 500;
  }
}
```

#### Modified Methods

**`_createDefaultSettings(String orgId)`**
- ✅ Fetches organization's plan from `organizations` table
- ✅ Sets `monthly_cost_limit` based on plan (not hardcoded $100)
- ✅ Sets `monthly_api_limit` based on plan (not hardcoded 2000)
- ✅ Distributes API call quota among 5 agents proportionally:
  - CFO: 25% of plan limit
  - CEO: 20% of plan limit
  - Marketing: 15% of plan limit
  - Sales: 20% of plan limit
  - Admin: 10% of plan limit

Example for Solo Plan (500 calls total):
```dart
'agents': {
  'cfo': {'api_calls_limit': 125},      // 25%
  'ceo': {'api_calls_limit': 100},      // 20%
  'marketing': {'api_calls_limit': 75}, // 15%
  'sales': {'api_calls_limit': 100},    // 20%
  'admin': {'api_calls_limit': 50},     // 10%
}
```

**`checkCallAllowed(orgId, agentName) → Map<String, dynamic>`**
- ✅ Fetches organization's plan on every call
- ✅ Uses plan-based cost limit instead of settings table
- ✅ Uses plan-based API call limit instead of settings table
- ✅ Returns detailed response with plan info:
  ```dart
  {
    'allowed': true,
    'reason': 'OK',
    'plan': 'team',
    'limit': 4.0,
    'usage': {...}
  }
  ```
- ✅ Auto-pauses automation when limit reached
- ✅ Alert at 80% of plan limit
- ✅ Detailed log messages: `"TEAM plan cost limit ($4.00/month) reached"`

### 2. **Settings Page** (`lib/ai_automation_settings_page.dart`)

#### Updated UI

**`_initializePage()` modification**:
```dart
final org = await supabase.from('organizations')
    .select('id, plan').single();

final plan = org['plan'] as String? ?? 'solo';
final planLimit = automationService.getPlanCostLimit(plan);
final planApiLimit = automationService.getPlanApiCallLimit(plan);

budget = await automationService.getRemainingBudget(orgId);
budget['limit'] = planLimit;      // Override with plan limit
budget['plan'] = plan;
budget['api_limit'] = planApiLimit;
```

**`_buildBudgetSection()` modification**:
- Displays plan badge: "SOLO PLAN" / "TEAM PLAN" / "WORKSHOP PLAN"
- Shows cost limit based on plan: `$2.00 / $2.00` (Solo)
- Shows API call limit: `500/month`
- Progress bar color: Green ✅ (under 80%), Orange ⚠️ (80-90%), Red ❌ (>90%)
- Displays remaining budget and remaining API calls

### 3. **Database** (`supabase_migrations/ai_automation_and_cost_control.sql`)

**Existing Tables**:
- `organizations` - Contains `plan` field (solo, team, workshop, trial, free)
- `ai_automation_settings` - Stores monthly_cost_limit (now plan-based)
- `ai_api_usage_log` - Tracks all API calls and costs

**Plan Lookup Flow**:
```
User calls AI agent
  ↓
checkCallAllowed() fetches org.plan
  ↓
Applies getPlanCostLimit(plan)
  ↓
Checks against actual usage this month
  ↓
Allows / Blocks + Auto-pauses if limit reached
```

---

## Enforcement Flow

### Step 1: Organization Created
- Admin specifies plan: Solo / Team / Workshop
- Plan stored in `organizations.plan` field

### Step 2: First AI Agent Call
- Service calls `_createDefaultSettings(orgId)`
- Queries org plan: "Solo"
- Sets monthly_cost_limit = $2.00
- Sets monthly_api_limit = 500
- Settings saved to `ai_automation_settings` table

### Step 3: Subsequent AI Calls
- Chat page calls `checkCallAllowed(orgId, 'cfo')`
- Service fetches org plan directly (not from settings)
- Compares current month usage vs plan limit
- Returns `{allowed: true/false, limit: $X, plan: 'solo'}`
- If reached: `setAutomationEnabled(false)` pauses all agents

### Step 4: User Views Settings
- Settings page loads plan from org
- Calculates plan-based limits
- Displays: "SOLO PLAN - $2.00/month limit - 500 API calls"
- Shows usage bar: "Current: $0.45 / $2.00 (22.5%)"

---

## Usage Scenarios

### Scenario 1: Solo Plan User (Max $2/month)
```
Day 1: Makes 10 AI calls → Cost: $0.08 (4% of limit)
Day 5: Makes 50 AI calls → Cost: $0.65 (32.5% cumulative)
Day 15: Makes 100 AI calls → Cost: $1.55 (77.5% cumulative)
  → ⚠️ ALERT: 77.5% of monthly limit
Day 20: Makes 20 AI calls → Cost: $1.85 (92.5% cumulative)
  → 🔴 ALERT: 92.5% of monthly limit
Day 21: Tries to make AI call
  → ❌ BLOCKED: Solo plan limit ($2.00/month) reached
  → Automation PAUSED
  → User sees: "Monthly cost limit ($2.00) reached. Upgrade plan or wait for reset."
Day 25: Month resets (billing cycle)
  → ✅ Budget reset to $2.00
  → User can make 2+ more calls (within limit)
```

### Scenario 2: Team Plan User (Max $4/month)
```
Day 10: Cost used: $1.20 (30% of limit)
Day 20: Cost used: $3.50 (87.5% of limit)
  → ⚠️ ALERT: 87.5% of monthly limit
Day 22: Tries to make AI call
  → ❌ BLOCKED: Team plan limit ($4.00/month) reached
  → Upgrade to Workshop plan or wait for reset
```

### Scenario 3: Workshop Plan User (Max $6/month)
```
Day 1-30: Can use up to $6.00 worth of API calls
- Budget: $6.00
- API calls: 1,500 limit
- Alerts: 80% ($4.80), 90% ($5.40)
- Auto-pause: At $6.00 spent
```

---

## Error Messages

### When Cost Limit Reached
```
💰 SOLO plan cost limit ($2.00/month) reached. Automation paused.
→ Action: Upgrade plan or wait for monthly reset
```

### When API Call Limit Reached
```
📞 SOLO plan API call limit (500/month) reached. Automation paused.
→ Action: Upgrade plan or wait for monthly reset
```

### Cost Alert (80% threshold)
```
⚠️ COST ALERT: 80.5% of SOLO plan limit used ($1.61/$2.00)
→ Action: Reduce agent proactivity or prepare to upgrade
```

---

## Settings Page Display

```
┌─────────────────────────────────────────────┐
│ 💰 Monthly Budget          [SOLO PLAN]      │
├─────────────────────────────────────────────┤
│ $0.45 / $2.00                        22.5%  │
│ ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░      │
│                                             │
│ Remaining Budget: $1.55                     │
│ API Calls Limit: 500/month                  │
└─────────────────────────────────────────────┘
```

---

## Testing Checklist

### ✅ Test Plan Limits Applied
- [ ] Solo org created → Cost limit set to $2.00
- [ ] Team org created → Cost limit set to $4.00
- [ ] Workshop org created → Cost limit set to $6.00
- [ ] Trial org created → Cost limit set to $2.00

### ✅ Test Cost Enforcement
- [ ] Solo user makes calls under $2.00 → Allowed ✅
- [ ] Solo user reaches $2.00 → Blocked ❌
- [ ] Team user reaches $4.00 → Blocked ❌
- [ ] Workshop user reaches $6.00 → Blocked ❌

### ✅ Test API Call Limits
- [ ] Solo user gets 500 calls/month
- [ ] Team user gets 1000 calls/month
- [ ] Workshop user gets 1500 calls/month

### ✅ Test UI Display
- [ ] Settings page shows "SOLO PLAN"
- [ ] Settings page shows "$2.00" limit
- [ ] Settings page shows "500" API calls
- [ ] Progress bar colors correct (green/orange/red)

### ✅ Test Auto-Pause
- [ ] Cost limit reached → Automation paused ✅
- [ ] API limit reached → Automation paused ✅
- [ ] User can re-enable after manual review

### ✅ Test Monthly Reset
- [ ] Budget resets at month boundary
- [ ] Usage logs clear after month ends
- [ ] User can use new budget next month

---

## Code Files Modified

| File | Changes | Status |
|------|---------|--------|
| `lib/services/ai_automation_service.dart` | Added plan lookup methods, updated _createDefaultSettings(), updated checkCallAllowed() | ✅ Done |
| `lib/ai_automation_settings_page.dart` | Updated _initializePage() to fetch plan, updated _buildBudgetSection() to display plan limits | ✅ Done |
| `supabase_migrations/ai_automation_and_cost_control.sql` | No changes needed (schema already supports) | ✅ Ready |
| `lib/aura_chat_page.dart` | Already has quota check, now uses plan-based limits | ✅ Ready |

---

## Migration Path

### For Existing Orgs
1. Old settings stored: `monthly_cost_limit: 100.0`
2. First AI call triggers `_createDefaultSettings()` via cache miss
3. Plan fetched from `organizations.plan`
4. Settings updated with correct plan limit
5. Future calls use new limit

### For New Orgs
1. Plan set during signup (Solo/Team/Workshop)
2. First settings fetch via `getAutomationSettings()`
3. `_createDefaultSettings()` uses org plan
4. Settings stored with plan-based limit immediately

---

## Upgrading Plans

### Manual Upgrade Process
1. User goes to Pricing page
2. Selects new plan (Team or Workshop)
3. Payment processed via Stripe
4. `organizations.plan` updated
5. Next AI call fetches new plan
6. New higher limit applied automatically
7. Old cost resets (fresh month cycle)

---

## API Reference

### Get Plan Cost Limit
```dart
final service = AIAutomationService();
final solo_limit = service.getPlanCostLimit('solo');      // Returns: 2.0
final team_limit = service.getPlanCostLimit('team');      // Returns: 4.0
final workshop_limit = service.getPlanCostLimit('workshop'); // Returns: 6.0
```

### Get Plan API Call Limit
```dart
final solo_calls = service.getPlanApiCallLimit('solo');      // Returns: 500
final team_calls = service.getPlanApiCallLimit('team');      // Returns: 1000
final workshop_calls = service.getPlanApiCallLimit('workshop'); // Returns: 1500
```

### Check if Call Allowed
```dart
final allowed = await service.checkCallAllowed(
  orgId: 'org-123',
  agentName: 'cfo'
);

if (!allowed['allowed']) {
  print('Blocked: ${allowed['reason']}');
  // "Blocked: SOLO plan cost limit ($2.00/month) reached"
}
```

---

## Future Enhancements

1. **Usage Alerts** - Email notification at 80% of plan limit
2. **Upgrade Prompts** - In-app suggestion to upgrade when hitting limit
3. **Overage Handling** - Option to purchase additional API calls (e.g., $1 for 100 extra calls)
4. **Plan Analytics** - Usage dashboard showing which agents consume most budget
5. **Agent-Level Limits** - Custom limits per agent instead of pool limit
6. **Time-Based Limits** - Different limits for different times (e.g., 2x on weekdays)

---

## Summary

✅ **Plan-based cost limits fully implemented**:
- Solo: $2.00/month, 500 calls
- Team: $4.00/month, 1000 calls
- Workshop: $6.00/month, 1500 calls
- Enforced at quota check time
- UI displays plan limits clearly
- Auto-pause prevents budget overages
- Backward compatible with existing orgs
