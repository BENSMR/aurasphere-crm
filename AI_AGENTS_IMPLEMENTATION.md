# 🤖 AI Agents Implementation - Plan-Based Architecture

**Version**: 2.0 | **Updated**: January 14, 2026

## Overview

All AuraSphere subscription plans now have access to **the same AI agent types**, with execution capabilities scaling by plan tier.

---

## Agent Availability Matrix

| Agent | Solo | Team | Workshop |
|-------|------|------|----------|
| **Job Automation** | ✅ Full | ✅ Full | ✅ Full |
| **CFO Agent** | ❌ | 🟡 Limited | ✅ Full |
| **CEO Agent** | ❌ | 🟡 Limited | ✅ Full |
| **Marketing Agent** | ❌ | 🟡 Limited | ✅ Full |
| **Sales Agent** | ❌ | 🟡 Limited | ✅ Full |

---

## Implementation Details

### Service: `autonomous_ai_agents_service.dart`

#### Plan-Based Execution Logic
```dart
// Plan-based agent execution in runAutonomousAgents()
if (plan == 'solo_trades') {
  // Solo: Job automation only
  await jobAutomationAgentLimited(orgId: orgId);
} else if (plan == 'small_team') {
  // Team: All agents with basic features
  await jobAutomationAgentLimited(orgId: orgId);
  await cfoAgentLimited(orgId: orgId);
  await ceoAgentLimited(orgId: orgId);
  await marketingAgentLimited(orgId: orgId);
  await salesAgentLimited(orgId: orgId);
} else if (plan == 'workshop' || plan == 'enterprise') {
  // Workshop/Enterprise: Full agent suite
  await jobAutomationAgentLimited(orgId: orgId);
  await cfoAgentAutonomous(orgId: orgId);
  await ceoAgentAutonomous(orgId: orgId);
  await marketingAgentAutonomous(orgId: orgId);
  await salesAgentAutonomous(orgId: orgId);
}
```

#### New Methods Added

**1. `getAvailableAgentsForPlan()` - Helper Method**
- Returns list of available agents for org's plan
- Shows feature limitations for Team plan
- Helps UI display agent capabilities

**2. `jobAutomationAgentLimited()` - Available All Plans**
- Auto-assign jobs to team members (round-robin)
- Job status notifications
- Used in all plans with same functionality

**3. `cfoAgentLimited()` - Team Plan Only**
- Overdue invoice reminders (auto-sent daily)
- Prevents duplicate reminders (24-hour cooldown)
- **Not included**: Budget management, invoice generation, advanced forecasting

**4. `ceoAgentLimited()` - Team Plan Only**
- Monthly revenue summaries
- Paid vs. pending invoice breakdown
- **Not included**: Strategic planning, growth forecasts, recommendations

**5. `marketingAgentLimited()` - Team Plan Only**
- Identifies inactive clients (30+ days no activity)
- Auto-sends re-engagement emails monthly
- **Not included**: Campaign automation, lead nurturing, segmentation

**6. `salesAgentLimited()` - Team Plan Only**
- Client value scoring (0-100 scale)
- Identifies high-value vs. low-value clients
- Helps prioritize follow-ups
- **Not included**: Lead pipeline, sales forecasting, opportunity management

---

## Features Comparison

### SOLO: Job Automation Only 🟦
```
✅ Auto-assign jobs (round-robin)
✅ Job status notifications
✅ Job completion automation
```

### TEAM: Enhanced AI Suite 🟩
All Solo features +
```
💰 CFO (Limited)
   ✅ Overdue invoice reminders
   ❌ Budget management
   ❌ Invoice generation
   ❌ Advanced forecasting

🎯 CEO (Limited)
   ✅ Monthly revenue summaries
   ❌ Strategic planning
   ❌ Growth forecasts
   ❌ Recommendations

📢 Marketing (Limited)
   ✅ Inactive client re-engagement
   ❌ Campaign automation
   ❌ Lead nurturing
   ❌ Segmentation

💼 Sales (Limited)
   ✅ Client value scoring
   ❌ Lead pipeline
   ❌ Sales forecasting
   ❌ Opportunity management
```

### WORKSHOP: Full Agent Suite 🟪
All Team features +
```
💰 CFO (Full)
   ✅ Advanced financial management
   ✅ Recurring invoice generation
   ✅ Cash flow optimization
   ✅ Budget & forecasting
   ✅ Payment term optimization
   ✅ Slow-paying client alerts

🎯 CEO (Full)
   ✅ Business performance analytics
   ✅ Strategic recommendations
   ✅ Growth planning
   ✅ Quarterly goal tracking
   ✅ Team performance insights

📢 Marketing (Full)
   ✅ Multi-step email campaigns
   ✅ Seasonal marketing
   ✅ Lead nurturing sequences
   ✅ Birthday/anniversary offers
   ✅ Personalized recommendations

💼 Sales (Full)
   ✅ Lead scoring & ranking
   ✅ Pipeline management
   ✅ Sales forecasting
   ✅ Opportunity tracking
   ✅ Win/loss analysis
```

---

## Code Architecture

### Service Singleton Pattern
```dart
class AutonomousAIAgentsService {
  static final AutonomousAIAgentsService _instance = 
      AutonomousAIAgentsService._internal();
  
  factory AutonomousAIAgentsService() => _instance;
  
  AutonomousAIAgentsService._internal();
  
  // Main scheduler
  Future<void> runAutonomousAgents() async { ... }
  
  // Helper
  Future<Map<String, dynamic>> getAvailableAgentsForPlan({
    required String orgId,
  }) async { ... }
  
  // Shared job automation
  Future<void> jobAutomationAgentLimited({required String orgId}) async { ... }
  
  // Limited agents (Team plan)
  Future<void> cfoAgentLimited({required String orgId}) async { ... }
  Future<void> ceoAgentLimited({required String orgId}) async { ... }
  Future<void> marketingAgentLimited({required String orgId}) async { ... }
  Future<void> salesAgentLimited({required String orgId}) async { ... }
  
  // Full agents (Workshop+ plans)
  Future<void> cfoAgentAutonomous({required String orgId}) async { ... }
  Future<void> ceoAgentAutonomous({required String orgId}) async { ... }
  Future<void> marketingAgentAutonomous({required String orgId}) async { ... }
  Future<void> salesAgentAutonomous({required String orgId}) async { ... }
}
```

---

## Execution Flow

### By Plan

**SOLO (Monthly Execution)**
```
organizations[plan='solo_trades'] 
  → runAutonomousAgents()
    → jobAutomationAgentLimited()
      ✅ Auto-assign pending jobs
      ✅ Send job notifications
```

**TEAM (Daily Execution)**
```
organizations[plan='small_team']
  → runAutonomousAgents()
    → jobAutomationAgentLimited()
    → cfoAgentLimited()         (Overdue reminders, 24h cooldown)
    → ceoAgentLimited()         (Monthly summaries)
    → marketingAgentLimited()   (Inactive client emails)
    → salesAgentLimited()       (Client value scoring)
```

**WORKSHOP (Continuous Execution)**
```
organizations[plan='workshop' OR 'enterprise']
  → runAutonomousAgents()
    → jobAutomationAgentLimited() (All agents)
    → cfoAgentAutonomous()        (Full CFO: recurring invoices, budgets, etc.)
    → ceoAgentAutonomous()        (Full CEO: strategic planning, analytics)
    → marketingAgentAutonomous()  (Full Marketing: campaigns, nurturing)
    → salesAgentAutonomous()      (Full Sales: pipeline, forecasting)
```

---

## Database Integration

### Supabase Tables Used

**organizations**
- `plan` - Determines available agents
- `billing_status` - Only 'active' orgs run agents
- `created_at` - Used for feature personalization

**invoices**
- `org_id, client_id, amount, due_date`
- `status` - Check for overdue (sent but past due_date)
- `reminder_sent_at` - Track reminder history (no spam)

**clients**
- `org_id, email, name, total_spent, invoice_count`
- `last_invoice_date` - Identify inactive clients (30+ days)
- `last_engagement_email` - Track re-engagement (max 1/month)
- `client_value_score` - Store agent-calculated score

**org_members**
- `org_id, user_id, email, role`
- Used for job assignment round-robin

---

## Edge Functions

### Email Delivery

**send-email** Edge Function
- **Templates**: `overdue_reminder`, `reengagement`, `monthly_summary`
- **Parameters**: `to`, `subject`, `template`, `data`
- **Status**: Called by all CFO/Marketing agents

Example:
```dart
await supabase.functions.invoke('send-email', body: {
  'to': client['email'],
  'subject': '⏰ Invoice Overdue Reminder',
  'template': 'overdue_reminder',
  'data': {
    'client_name': client['name'],
    'invoice_number': invoice['id'],
    'amount': invoice['amount'],
  }
});
```

---

## Deployment & Scheduling

### Backend Scheduler (TBD)
- **Frequency**: Hourly, daily, weekly check
- **Trigger**: Supabase scheduled function or external cron (e.g., GitHub Actions)
- **Processing**: Filter by plan, execute appropriate agents
- **Error Handling**: Log failures, continue processing other orgs

### Current Status
- ✅ Service methods implemented
- ✅ Plan-based logic configured
- ⏳ Backend scheduler integration pending
- ⏳ Email templates pending
- ⏳ Database schema updates pending (client_value_score column)

---

## User Experience

### Team Plan Benefits Over Solo
- ✅ See same agents as Workshop
- ✅ Get limited AI benefits (overdue reminders, etc.)
- ✅ Option to upgrade to Workshop for full features
- ✅ No price increase from previous version

### Workshop Plan Upgrade Path
- Unlock all agent features with single upgrade
- All limitations removed
- Full CFO, CEO, Marketing, Sales capabilities
- Continuous execution (not daily/monthly)

---

## Logging & Monitoring

### Log Prefixes Used
```
🤖 - Main scheduler start/end
💰 - CFO agent operations
🎯 - CEO agent operations
📢 - Marketing agent operations
💼 - Sales agent operations
📧 - Email send confirmations
⭐ - Client scoring
❌ - Error conditions
✅ - Operation success
⚠️ - Warnings (non-fatal)
📋 - Data counts
```

### Example Logs
```
🤖 Starting autonomous agent suite...
🔄 Running agents for org: [orgId] (Plan: small_team)
💰 CFO Agent (Limited): Starting for org: [orgId]
💳 Found 3 overdue invoices
📧 Reminder sent to client@email.com
✅ Limited CFO agent completed (overdue reminders only)
```

---

## Future Enhancements

### Phase 2: COO Agent
- Operations optimization
- Inventory management automation
- Resource utilization analysis

### Phase 3: Advanced Analytics
- Predictive revenue modeling
- Churn prediction
- Opportunity scoring (ML-based)

### Phase 4: Custom Agents
- Workshop+ plans can create custom automation rules
- Workflow builder UI
- Conditional logic engine

---

## Testing Checklist

- [ ] Solo plan only runs job automation
- [ ] Team plan runs all agents with Limited versions
- [ ] Workshop plan runs all agents with Full versions
- [ ] Overdue reminder doesn't spam (24h cooldown)
- [ ] Inactive client emails don't repeat monthly
- [ ] Client value scores update correctly
- [ ] Monthly revenue summaries calculate accurately
- [ ] Edge Function email delivery succeeds
- [ ] Logs contain proper emoji prefixes
- [ ] Database transactions rollback on errors

---

**Commit**: feat: AI agents available in all plans with plan-based limitations
**Date**: January 14, 2026
