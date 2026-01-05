# AuraSphere CRM - Subscription Tier Limitations

## Overview

Each subscription tier has clear limitations on **team members** and **monthly AI calls** to control usage and prevent abuse while maintaining fair pricing.

---

## Subscription Tiers

### Solo Plan - $9.99/month
- **Users**: 1 user maximum
- **AI Calls**: 500 calls/month
- **Target**: Single owners, freelancers, solo contractors
- **Perfect for**: Electricians, plumbers running solo operations

### Team Plan - $15.00/month
- **Users**: 3 users maximum
- **AI Calls**: 1,000 calls/month
- **Target**: 2-3 person teams
- **Perfect for**: Small teams needing collaboration (owner + 1-2 techs)

### Workshop Plan - $29.00/month
- **Users**: 7 users maximum
- **AI Calls**: 1,500 calls/month
- **Target**: 4-7 person companies
- **Perfect for**: Larger teams, multiple crews, workshops with staff

---

## What Happens When Limits Are Reached?

### User Limit Exceeded
- **Status**: Red alert on dashboard
- **Action**: Cannot add new team members
- **Solution**: Upgrade to higher tier plan
- **Message**: "You've reached the maximum users for your plan (1). Upgrade to Team or Workshop."

### AI Call Limit Exceeded
- **Status**: New AI requests blocked
- **Action**: Existing requests complete, new ones rejected
- **Solution**: Wait until next billing cycle OR upgrade plan
- **Message**: "You've used 500/500 AI calls this month. Upgrade your plan or wait until next month."

---

## Usage Tracking

### Dashboard Display
Each plan shows:
- ✅ Current team members: 1/1 (Solo), 2/3 (Team), 5/7 (Workshop)
- ✅ AI calls used: 450/500 (Solo), 892/1000 (Team), 1380/1500 (Workshop)
- ✅ Days remaining: 8 days until reset
- ✅ Progress bars for both metrics

### Monthly Reset
- **Reset Date**: 1st of each month at UTC 00:00
- **AI Calls**: Reset to 0
- **Users**: Carried over (no change)
- **Notification**: Email sent with new monthly allowance

---

## Plan Comparison

| Feature | Solo | Team | Workshop |
|---------|------|------|----------|
| **Monthly Cost** | $9.99 | $15.00 | $29.00 |
| **Max Users** | 1 | 3 | 7 |
| **Monthly AI Calls** | 500 | 1,000 | 1,500 |
| **Support** | Email | Email | Email + Priority |
| **Mobile Access** | ✅ | ✅ | ✅ |
| **Web Access** | ✅ | ✅ | ✅ |
| **All 14 Features** | ✅ | ✅ | ✅ |
| **All 5 AI Agents** | ✅ (limited calls) | ✅ (limited calls) | ✅ (limited calls) |
| **Custom Branding** | ❌ | ❌ | ✅ |
| **API Access** | ❌ | ❌ | ✅ |

---

## Real-World Examples

### Solo Electrician (Solo Plan)
```
- 1 owner (at limit)
- 400 AI calls/month for:
  - Job estimates (CFO agent)
  - Invoice generation (CFO agent)
  - Client communication (Marketing agent)
- 100 calls remaining as buffer
- Cost: $9.99/month (predictable)
```

### Small Plumbing Team (Team Plan)
```
- 3 team members: Owner + 2 Technicians (at limit)
- 950 AI calls/month for:
  - Dispatching (Admin agent)
  - Job scheduling (CEO agent)
  - Team coordination (Admin agent)
  - Invoice personalization (CFO agent)
  - Client outreach (Marketing agent)
- 50 calls remaining as buffer
- Cost: $15.00/month (predictable)
```

### HVAC Workshop (Workshop Plan)
```
- 7 team members: Owner + 3 Techs + Admin + Scheduler + Manager (at limit)
- 1,480 AI calls/month for:
  - All 5 AI agents used heavily
  - Multiple crews coordinating
  - Complex scheduling
  - Client management at scale
- 20 calls remaining as buffer
- Cost: $29.00/month (predictable)
```

---

## Upgrading Plans

### Mid-Month Upgrade
- New limits take effect immediately
- **Example**: Solo to Team upgrade on day 15
  - User count: Can now add 2 more members
  - AI calls: Remaining budget calculated (500 ÷ 30 days × 15 days remaining)
  - No refund for Solo plan
  - Team billing starts next month ($15.00)

### Downgrading Plans
- Takes effect at end of current billing cycle
- Must remove excess users before downgrade
- Next month applies new lower limits

---

## FAQs

**Q: What if I need more AI calls mid-month?**
A: Upgrade to the next tier plan for immediate access to higher limits.

**Q: Can I add more users after reaching the limit?**
A: No. You must upgrade your plan to add more team members.

**Q: Do unused AI calls roll over to next month?**
A: No. Monthly allowance resets on the 1st of each month.

**Q: What counts as an "AI call"?**
A: Each interaction with any AI agent (CFO, CEO, Marketing, Sales, Admin) counts as 1 call.

**Q: Can I invite users to view-only accounts (not counted)?**
A: No. View-only accounts still count toward your team limit.

**Q: What happens if I go over the limit by accident?**
A: New AI requests are blocked. Contact support for emergency override (reviewed case-by-case).

**Q: Is there an annual discount?**
A: Not yet. Monthly billing is current standard.

---

## Benefits of Tiered Limits

| Benefit | Impact |
|---------|--------|
| **Predictable Costs** | Know exactly what you're paying ($9.99, $15, or $29) |
| **Abuse Prevention** | Bots/scripts can't drain resources or inflate bills |
| **Fair Pricing** | Pay for what you use, not unlimited (expensive) |
| **Growth Path** | Easy to scale: Solo → Team → Workshop |
| **Resource Management** | Server costs stay manageable |
| **Quality Control** | Prevents system overload from any single user |

---

## Implementation Checklist

- [ ] Database: Add `tier_limits` table with user/call counts per plan
- [ ] Dashboard: Create "Usage" widget showing both metrics
- [ ] Backend: Add checks before AI agent calls (calls remaining?)
- [ ] Backend: Add checks before user invitations (users remaining?)
- [ ] Frontend: Show alerts when approaching limits (90%)
- [ ] Frontend: Show error when limit reached (100%)
- [ ] Jobs: Daily batch job to log usage metrics
- [ ] Jobs: Monthly reset job (1st of month, AI calls → 0)
- [ ] Email: Send monthly summary (calls used, users, next billing)
- [ ] Testing: QA all limit scenarios (hit user, hit calls, upgrade, downgrade)

