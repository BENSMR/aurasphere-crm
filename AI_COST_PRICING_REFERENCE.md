# AI Cost Control - Plan Pricing & Calculation Reference

**Last Updated**: January 2025
**Feature**: Subscription-based cost limiting for AI agents

---

## Plan Pricing Matrix

### Subscription Tiers

```
┌──────────────┬──────────────────┬──────────────────┬─────────────────────┐
│ Plan         │ Monthly Cost Cap  │ Monthly API Calls │ Best For            │
├──────────────┼──────────────────┼──────────────────┼─────────────────────┤
│ Solo         │ $2.00             │ 500 calls        │ Single owner        │
│ Team         │ $4.00             │ 1,000 calls      │ 2-3 person business │
│ Workshop     │ $6.00             │ 1,500 calls      │ 7+ person business  │
│ Trial/Free   │ $2.00             │ 500 calls        │ Evaluation          │
└──────────────┴──────────────────┴──────────────────┴─────────────────────┘
```

---

## Groq API Pricing Model

### Per Million Tokens Pricing

```
Groq API Costs (as of Jan 2025):
├── Input tokens:  $0.05 per 1M tokens
├── Output tokens: $0.15 per 1M tokens
└── Average call: 2,000-4,000 total tokens

Cost per token (average):
├── Input only ($0.05 per 1M): $0.00000005 per input token
├── Output only ($0.15 per 1M): $0.00000015 per output token
└── Mixed (input + output):
    - 2,000 token call (1500 input, 500 output):
      Cost = (1500 × $0.00000005) + (500 × $0.00000015)
           = $0.000075 + $0.000075 = $0.00015 (very cheap!)
    
    - 4,000 token call (2000 input, 2000 output):
      Cost = (2000 × $0.00000005) + (2000 × $0.00000015)
           = $0.0001 + $0.0003 = $0.0004
```

### Cost Per API Call Examples

```
Small call (1,500 tokens):
├── Input: 1,000 tokens × $0.00000005 = $0.00005
├── Output: 500 tokens × $0.00000015 = $0.000075
└── Total: $0.000125 per call

Medium call (3,000 tokens):
├── Input: 1,500 tokens × $0.00000005 = $0.000075
├── Output: 1,500 tokens × $0.00000015 = $0.000225
└── Total: $0.0003 per call

Large call (5,000 tokens):
├── Input: 2,500 tokens × $0.00000005 = $0.000125
├── Output: 2,500 tokens × $0.00000015 = $0.000375
└── Total: $0.0005 per call
```

---

## Plan Capacity Analysis

### Solo Plan: $2.00/month Budget

```
Budget: $2.00
Limit: 500 API calls

Scenario 1: Small calls (avg $0.0002/call)
├── 500 calls × $0.0002 = $0.10 spent
├── Budget remaining: $1.90
└── Can make: ~10,000 total calls theoretically

Scenario 2: Medium calls (avg $0.0005/call)
├── 500 calls × $0.0005 = $0.25 spent
├── Budget remaining: $1.75
└── Realistic: 500 calls = 1 month of usage

Scenario 3: Large calls (avg $0.001/call)
├── 500 calls × $0.001 = $0.50 spent
├── Budget remaining: $1.50
└── Still within budget for heavier usage

Summary:
└── 500 calls/month is MORE than enough for Solo tier
    (hits call limit before cost limit in most cases)
```

### Team Plan: $4.00/month Budget

```
Budget: $4.00
Limit: 1,000 API calls

Scenario 1: Small calls (avg $0.0002/call)
├── 1,000 calls × $0.0002 = $0.20 spent
├── Budget remaining: $3.80
└── Heavy usage possible

Scenario 2: Medium calls (avg $0.0005/call)
├── 1,000 calls × $0.0005 = $0.50 spent
├── Budget remaining: $3.50
└── Good balance for growing teams

Scenario 3: Large calls (avg $0.001/call)
├── 1,000 calls × $0.001 = $1.00 spent
├── Budget remaining: $3.00
└── Supports multiple agents actively

Summary:
└── 1,000 calls/month suitable for 2-3 person teams
    with moderate to high AI usage
```

### Workshop Plan: $6.00/month Budget

```
Budget: $6.00
Limit: 1,500 API calls

Scenario 1: Heavy usage (avg $0.001-$0.002/call)
├── 1,500 calls × $0.0015 = $2.25 spent
├── Budget remaining: $3.75
└── Room for additional usage

Scenario 2: Very heavy usage (avg $0.003/call)
├── 1,500 calls × $0.003 = $4.50 spent
├── Budget remaining: $1.50
└── Still under budget

Scenario 3: Extreme usage (avg $0.004/call)
├── 1,500 calls × $0.004 = $6.00 spent
├── Budget remaining: $0.00
└── Hits cost limit at call limit

Summary:
└── 1,500 calls/month supports:
    - All 5 agents running actively
    - Multiple daily calls per agent
    - Automation + proactive features
    - Peak usage patterns for 7+ person teams
```

---

## Monthly Usage Projections

### Agent Usage Patterns

```
Agent Behavior:
├── CFO Agent
│   ├── Frequency: Daily 1-2 times (analytics, forecasting)
│   ├── Avg call cost: $0.0005
│   └── Monthly: ~30-60 calls = $0.015-$0.030
│
├── CEO Agent
│   ├── Frequency: Daily 1-2 times (summaries, decisions)
│   ├── Avg call cost: $0.0005
│   └── Monthly: ~30-60 calls = $0.015-$0.030
│
├── Marketing Agent
│   ├── Frequency: 2-3x per week (campaign ideas, copy)
│   ├── Avg call cost: $0.0003
│   └── Monthly: ~20-30 calls = $0.006-$0.009
│
├── Sales Agent
│   ├── Frequency: 2-3x per week (follow-ups, strategies)
│   ├── Avg call cost: $0.0003
│   └── Monthly: ~20-30 calls = $0.006-$0.009
│
└── Admin Agent
    ├── Frequency: As needed (~1x per week)
    ├── Avg call cost: $0.0005
    └── Monthly: ~4-8 calls = $0.002-$0.004
```

### Plan Usage Examples

#### Solo User (Light Usage)
```
Month Profile: Solo business owner, occasional AI usage
├── CFO: 2x/week = 8-10 calls = $0.005
├── CEO: 2x/week = 8-10 calls = $0.005
├── Marketing: 0 (manual)
├── Sales: 0 (manual)
└── Admin: 0 (manual)

Total: ~16-20 calls/month, $0.010 spent
Result: ✅ Plenty of budget left ($1.99 remaining)
        ✅ Call limit not reached (480 remaining)
```

#### Team User (Moderate Usage)
```
Month Profile: 3-person team, active AI usage
├── CFO: 2-3x/week = 30-40 calls = $0.015-$0.020
├── CEO: 2-3x/week = 30-40 calls = $0.015-$0.020
├── Marketing: 2x/week = 15-20 calls = $0.005-$0.007
├── Sales: 2x/week = 15-20 calls = $0.005-$0.007
└── Admin: 1x/week = 5 calls = $0.003

Total: ~100-120 calls/month, $0.050-$0.065 spent
Result: ✅ Plenty of budget left ($3.94 remaining)
        ✅ 880-900 calls remaining
        ✅ Good headroom for spikes
```

#### Workshop User (Heavy Usage)
```
Month Profile: 7-person team, heavy/automated AI usage
├── CFO: Daily = 100-150 calls = $0.050-$0.075
├── CEO: Daily = 100-150 calls = $0.050-$0.075
├── Marketing: Daily = 50-100 calls = $0.015-$0.030
├── Sales: Daily = 50-100 calls = $0.015-$0.030
├── Admin: 3x/week = 15-20 calls = $0.008-$0.010
└── Automation: Proactive = 100-200 calls = $0.050-$0.100

Total: ~450-750 calls/month, $0.200-$0.400 spent
Result: ✅ Well under budget ($5.60+ remaining)
        ✅ 750-1,050 calls remaining
        ✅ Can burst when needed (sales event, audit, etc.)
```

---

## Daily Budget Usage Breakdown

### Solo Plan ($2.00 monthly = $0.067 daily)

```
Daily Budget: ~$0.067
Daily Calls: ~16-17 calls allowed (if spread evenly)

Usage Pattern:
├── Day 1: 0 calls ($0.00) ✅
├── Day 2: 10 calls ($0.005) ✅
├── Day 3: 15 calls ($0.008) ✅
├── Day 4: 0 calls ($0.00) ✅
├── Day 5: 20 calls ($0.010) ✅
├── ...repeating pattern...
└── Month total: ~500 calls, $2.00

Limits prevent: Running 100+ calls/day for 20 days
Result: Safe for typical Solo usage patterns
```

### Team Plan ($4.00 monthly = $0.133 daily)

```
Daily Budget: ~$0.133
Daily Calls: ~33 calls allowed (if spread evenly)

Usage Pattern:
├── Day 1: 25 calls ($0.013) ✅
├── Day 2: 40 calls ($0.020) ✅
├── Day 3: 30 calls ($0.015) ✅
├── Day 4: 35 calls ($0.018) ✅
├── ...repeating pattern...
└── Month total: ~1,000 calls, $4.00

Limits prevent: Running 200+ calls/day consistently
Result: Safe for Team team collaboration patterns
```

### Workshop Plan ($6.00 monthly = $0.20 daily)

```
Daily Budget: ~$0.20
Daily Calls: ~50 calls allowed (if spread evenly)

Usage Pattern:
├── Day 1: 60 calls ($0.030) ✅
├── Day 2: 50 calls ($0.025) ✅
├── Day 3: 80 calls ($0.040) ✅
├── Day 4: 45 calls ($0.023) ✅
├── ...repeating pattern...
└── Month total: ~1,500 calls, $6.00

Limits prevent: Nothing reasonable - allows heavy usage
Result: Safe for all automated/proactive scenarios
```

---

## Cost Alert Thresholds

### Automatic Alerts at 80% of Limit

```
Solo Plan ($2.00):
├── Alert threshold: $1.60 (80%)
├── Warning message: "⚠️ 80% of SOLO plan limit used"
├── Action: Review usage, consider upgrading

Team Plan ($4.00):
├── Alert threshold: $3.20 (80%)
├── Warning message: "⚠️ 80% of TEAM plan limit used"
├── Action: Monitor usage, prepare for upgrade if needed

Workshop Plan ($6.00):
├── Alert threshold: $4.80 (80%)
├── Warning message: "⚠️ 80% of WORKSHOP plan limit used"
├── Action: Contact support for optimization
```

### Auto-Pause at 100% of Limit

```
Solo Plan ($2.00):
├── Hard limit: $2.00
├── Exceeded message: "💰 SOLO plan cost limit ($2.00) reached"
├── Action: Automation paused, user notified
└── Recovery: Wait for month reset or upgrade

Team Plan ($4.00):
├── Hard limit: $4.00
├── Exceeded message: "💰 TEAM plan cost limit ($4.00) reached"
├── Action: Automation paused, user notified
└── Recovery: Wait for month reset or upgrade

Workshop Plan ($6.00):
├── Hard limit: $6.00
├── Exceeded message: "💰 WORKSHOP plan cost limit ($6.00) reached"
├── Action: Automation paused, user notified
└── Recovery: Wait for month reset or upgrade
```

---

## Cost Optimization Strategies

### For Solo Users (Maximize $2.00 Budget)

```
✅ Recommended:
├── Use CFO agent for daily financial review (1 call/day)
├── Use CEO agent for weekly summaries (1-2 calls/week)
├── Disable proactive features (save ~60% cost)
└── Disable Admin agent (not needed for 1 person)

Result: ~30 calls/month = $0.015 spent
        Leaves $1.985 buffer for ad-hoc usage

❌ Avoid:
├── Enabling all agents with proactive ON
├── Automated daily summaries for all agents
├── Enabling Admin agent (rarely needed)
└── Large batches of historical analysis
```

### For Team Users (Maximize $4.00 Budget)

```
✅ Recommended:
├── Enable CFO + CEO agents (heavy daily)
├── Use Marketing for campaign planning (2x/week)
├── Use Sales for follow-up strategies (2x/week)
├── Proactive for CFO/CEO only (80% usage)
└── Disable Admin agent (use only when needed)

Result: ~150-200 calls/month = $0.075-$0.100 spent
        Leaves $3.90+ buffer for peaks

❌ Avoid:
├── Enabling all agents with all proactive
├── Continuous automation loops
├── Redundant calls (multiple agents doing same task)
└── Inefficient prompts (more tokens = more cost)
```

### For Workshop Users (Maximize $6.00 Budget)

```
✅ Recommended:
├── Enable ALL agents with proactive ON
├── Daily calls for CFO, CEO, Sales, Marketing
├── Enable automation for repetitive tasks
├── Admin for compliance + reporting
└── Use full potential of subscription

Result: ~600-800 calls/month = $0.300-$0.400 spent
        Leaves $5.60+ for bursts/spikes

✅ No restrictions - full automation possible
└── Supports any business scenario
```

---

## Pricing Scenarios & ROI

### Question: "Is AI worth $2.00/month for Solo?"

```
Solo ROI Analysis:
├── AI Cost: $2.00/month
├── Time saved per call: 10-15 minutes (AI does analysis)
├── Typical usage: 20-30 calls/month
├── Total time saved: 200-450 minutes = 3-7.5 hours
├── Value of time: $20-50/hour (professional rate)
└── Monthly value: $60-375 saved

Return: 30-187x return on investment ✅

Conclusion: Even small businesses see 30x+ ROI
            ($2 spent → $60+ value gained)
```

### Question: "Is AI worth $4.00/month for Teams?"

```
Team ROI Analysis:
├── AI Cost: $4.00/month
├── Time saved per call: 10-15 minutes
├── Typical usage: 150-200 calls/month
├── Total time saved: 1,500-3,000 minutes = 25-50 hours
├── Value of 3 people's time: $60-150/hour total
└── Monthly value: $1,500-7,500 saved

Return: 375-1,875x return on investment ✅✅

Conclusion: Teams save 25-50 hours/month
            Perfect for scaling operations
```

### Question: "Is AI worth $6.00/month for Workshops?"

```
Workshop ROI Analysis:
├── AI Cost: $6.00/month
├── Time saved per call: 10-15 minutes
├── Typical usage: 600-800 calls/month
├── Total time saved: 6,000-12,000 minutes = 100-200 hours
├── Value of 7 people's time: $120-300/hour total
└── Monthly value: $12,000-60,000 saved

Return: 2,000-10,000x return on investment ✅✅✅

Conclusion: Large teams save 100-200 hours/month
            Massive productivity multiplier
```

---

## Summary Table

```
┌──────────────────────────────────────────────────────────────┐
│ PLAN PRICING SUMMARY                                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ Solo Plan:      $2.00/month  + 500 calls                   │
│ └─ Good for:    Single owner, light usage                  │
│                                                              │
│ Team Plan:      $4.00/month  + 1000 calls                  │
│ └─ Good for:    2-3 people, moderate usage                 │
│                                                              │
│ Workshop Plan:  $6.00/month  + 1500 calls                  │
│ └─ Good for:    7+ people, heavy usage                     │
│                                                              │
│ COST CALCULATION:                                           │
│ ├─ Groq Input:  $0.05 per 1M tokens                       │
│ ├─ Groq Output: $0.15 per 1M tokens                       │
│ └─ Avg call:    $0.0002-$0.0005 per call                  │
│                                                              │
│ ROI:                                                        │
│ ├─ Solo:        30x ($2 → $60 value)                      │
│ ├─ Team:        375x ($4 → $1,500 value)                  │
│ └─ Workshop:    2000x ($6 → $12,000 value)                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## Conclusion

✅ **Plan pricing is optimized for ROI**:
- All tiers show positive ROI (30x minimum)
- Costs predictable and transparent
- Unlimited potential for productivity gains
- Suitable for businesses of all sizes
