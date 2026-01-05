# 🚀 AI Automation & Cost Control - Quick Setup Guide

## Installation & Deployment (5 minutes)

### Step 1: Apply Database Migration
```bash
# In Supabase Dashboard → SQL Editor → New Query

# Paste entire contents of:
# supabase_migrations/ai_automation_and_cost_control.sql

# Click "Run" to create tables, views, and functions
```

### Step 2: Deploy Code Changes
```bash
cd c:\Users\PC\AuraSphere\crm\aura_crm

# Get latest dependencies
flutter pub get

# Build for web (optional, for testing)
flutter build web --release

# Or run on Chrome
flutter run -d chrome
```

### Step 3: Test Settings Page
1. Login to the app
2. Click settings gear icon ⚙️ in top-right
3. Should see "AI Automation Settings" page
4. All toggles should work without errors

---

## User Guide

### For Org Owners

**Access:** Home Page → Settings Icon (⚙️) → AI Automation Settings

### Master Controls

**1. Enable/Disable All Automation**
- Toggle at top of page
- Disables ALL AI agents immediately
- Blue when enabled, Gray when disabled

**2. Set Proactivity Level** (affects automation behavior)
- **🛡️ Conservative** - Manual approval needed, safe, low API usage
- **⚖️ Balanced** - Smart automation, recommended, balanced cost
- **🔥 Aggressive** - Auto-run everything, high API usage, higher cost

**3. Budget Management** (prevent cost overruns)
- Set monthly cost limit in USD
- View current month spending
- Progress bar shows % of budget used
- Auto-pause when limit reached (if enabled)

### Per-Agent Controls

**For each agent (CFO, CEO, Marketing, Sales, Admin):**
1. **Enable Toggle** - Turn agent on/off
2. **Proactive Toggle** - Allow agent to run automatically
3. **Call Limit** - Max API calls per month

### Monitoring

**View Usage Analytics:**
- Total API calls this month
- Total cost in USD
- Breakdown by agent
- Cost per agent

**Budget Status:**
- 🟢 GREEN (0-79%) - Healthy
- 🟠 ORANGE (80-89%) - Warning
- 🔴 RED (90-99%) - Critical
- 🚫 BLOCKED (100%+) - Paused

---

## Cost Estimation

### Per API Call Cost (Groq Pricing)
- Input tokens: $0.05 per 1M
- Output tokens: $0.15 per 1M

### Example Costs
| Action | Tokens | Estimated Cost |
|--------|--------|-----------------|
| Create Invoice | 200 | ~$0.003 |
| Parse Command | 150 | ~$0.002 |
| List Clients | 100 | ~$0.002 |
| Analyze Business | 500 | ~$0.008 |

### Typical Organization Budget

| Plan | Monthly Limit | Typical Usage | Headroom |
|------|--------------|---------------|----------|
| Solo | $50 | $10-20 | 60-80% |
| Team | $100 | $30-50 | 50-70% |
| Workshop | $250 | $80-150 | 40-60% |
| Enterprise | $1000+ | Custom | 40%+ |

**Recommendations:**
- Start with $100/month
- Monitor usage for 2 weeks
- Adjust based on actual spend
- Set alert threshold at 70-80%

---

## Troubleshooting

### Settings page shows "Loading..." forever
**Solution:** 
- Check Supabase connection
- Ensure migration ran successfully
- Check browser console for errors

### Toggles don't save
**Solution:**
- Verify you're the organization owner
- Check RLS policies are active
- Ensure `ai_automation_settings` table exists

### API calls still work when automation disabled
**Solution:**
- Restart app (hard refresh in browser)
- Check `automation_enabled` in Supabase console
- Verify `aura_chat_page.dart` has quota check

### Cost shown as $0
**Solution:**
- API calls logged correctly? Check `ai_usage_log` table
- `estimated_cost` field populated?
- Groq pricing rate correct in `estimateApiCost()`?

### Budget not enforcing limit
**Solution:**
- Check `auto_pause_on_limit` is TRUE
- Verify `monthly_cost_limit` set correctly
- Ensure current cost exceeds limit
- Check automation not already paused

---

## Best Practices

### 🎯 Recommended Configuration

For most teams:
```
✅ Automation: ENABLED
✅ Proactivity: BALANCED
✅ CFO Agent: ENABLED (proactive)
✅ CEO Agent: ENABLED (proactive)
✅ Marketing Agent: ENABLED (not proactive)
✅ Sales Agent: ENABLED (not proactive)
⏸️ Admin Agent: DISABLED (manual only)

💰 Monthly Cost Limit: $100-150
⚠️ Alert Threshold: 80%
🛑 Auto-Pause: ENABLED
```

### Cost Optimization Tips

1. **Disable unused agents** - If you don't use CEO insights, disable it
2. **Use Conservative proactivity** - Manual approval mode reduces costs
3. **Set per-agent limits** - Prevent runaway costs from one agent
4. **Monitor weekly** - Check usage dashboard every Friday
5. **Use alerts** - Get Slack notification at 80% threshold

### Security Best Practices

1. **Only org owners** can change settings
2. **RLS policies** prevent cross-org access
3. **All API keys** stored in Supabase Secrets
4. **Usage logs** readable by org members (for analytics)
5. **Auto-pause** prevents unexpected costs

---

## Monitoring Dashboard

### What to Check Weekly

1. **Current Spend**
   - How much used so far?
   - Trend (increasing or stable)?
   - Days left in month?

2. **Agent Usage**
   - Which agents used most?
   - Are they disabled agents still running?
   - Do calls align with team activity?

3. **Cost Efficiency**
   - Cost per API call (should be ~$0.002-0.010)
   - Are there any expensive calls?
   - Can you optimize prompts to use fewer tokens?

4. **Trend Analysis**
   - Usage trending up or down?
   - Forecast: will you hit limit before month-end?
   - Adjust limits proactively if needed

---

## API Reference

### Set Cost Limit
```dart
await automationService.setMonthlyCostLimit(orgId, 250.0); // $250/month
```

### Enable/Disable Agent
```dart
await automationService.setAgentEnabled(orgId, 'cfo', true);
```

### Get Budget Status
```dart
final budget = await automationService.getRemainingBudget(orgId);
print('${budget['percent_used']}% used');
print('${budget['remaining']} remaining');
```

### Get Usage Statistics
```dart
final usage = await automationService.getCurrentMonthUsage(orgId);
print('${usage['api_calls']} calls');
print('${usage['total_cost']} cost');
```

### Log API Call
```dart
await automationService.logApiCall(
  orgId: orgId,
  agentName: 'cfo',
  action: 'create_invoice',
  tokensUsed: 150,
  estimatedCost: 0.002,
);
```

---

## FAQ

**Q: What happens if I hit my monthly limit?**  
A: If `auto_pause_on_limit` is enabled (default), all automation pauses automatically. You'll see: "💰 Monthly cost limit reached. Automation paused." You can re-enable manually or wait for next month.

**Q: Can I set different limits per agent?**  
A: Currently all agents share the organization limit. Per-agent limits are a future feature.

**Q: How often is usage updated?**  
A: Each API call is logged immediately. Usage analytics update in real-time.

**Q: Can I disable cost tracking?**  
A: No, tracking is always active for security and audit purposes.

**Q: Do disabled agents still count towards the cost limit?**  
A: No, disabled agents can't make API calls, so they have zero cost.

**Q: Can I change limits mid-month?**  
A: Yes, changes apply immediately to new API calls (doesn't reset usage).

**Q: What if proactivity is disabled but agent is enabled?**  
A: Agent can still be used, but won't auto-run. Users must manually invoke it.

**Q: Do failed API calls count towards the limit?**  
A: Only successful API calls are logged and counted.

---

## Support

If you encounter issues:

1. **Check the console** - Browser → F12 → Console tab
2. **Verify Supabase** - Check tables exist and have data
3. **Review migration** - Ensure SQL migration ran without errors
4. **Test quota check** - Try with disabled agent (should be blocked)
5. **Check RLS** - Ensure user is in organization

---

**Setup Time:** 5 minutes  
**Testing Time:** 10 minutes  
**Total Ready:** ~15 minutes  
**Status:** ✅ Production Ready
