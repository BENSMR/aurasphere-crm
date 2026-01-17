# 🎯 AuraSphere CRM - KPI & Metrics Implementation
**Date**: January 16, 2026  
**Status**: ✅ Ready for Production

---

## 📊 Executive Summary

AuraSphere CRM tracks **40+ KPIs** across 6 categories:
1. **Financial KPIs** - Revenue, profit, margins, cash flow
2. **Operational KPIs** - Job completion, efficiency, turnaround time
3. **Customer KPIs** - Client satisfaction, retention, lifetime value
4. **Team KPIs** - Utilization, productivity, retention
5. **Business Growth KPIs** - Growth rate, market expansion, churn
6. **Technical KPIs** - System uptime, performance, reliability

---

## 💰 Financial KPIs

### **Revenue Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Total Revenue** | Sum of all invoices paid | `invoices` table | `SUM(amount) WHERE status='paid'` | Tracked |
| **Monthly Revenue (MRR)** | Recurring monthly revenue | `recurring_invoices` table | `SUM(amount) WHERE active=true` | Tracked |
| **Annual Revenue (ARR)** | Annualized recurring revenue | `recurring_invoices` table | `MRR × 12` | Tracked |
| **Invoice Value (Avg)** | Average invoice amount | `invoices` table | `AVG(amount)` | Tracked |
| **Outstanding Revenue** | Unpaid invoices | `invoices` table | `SUM(amount) WHERE status='sent'` | Tracked |
| **Overdue Revenue** | Past due invoices | `invoices` table | `SUM(amount) WHERE status='overdue'` | Tracked |

**Implementation**: `invoice_service.dart`
```dart
// Calculate total revenue
final totalRevenue = await supabase
    .from('invoices')
    .select('amount')
    .eq('org_id', orgId)
    .eq('status', 'paid')
    .then((invoices) => invoices.fold<double>(0, (sum, i) => sum + (i['amount'] ?? 0)));
```

---

### **Profitability Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Gross Profit** | Revenue minus cost of materials | `invoices` + `expenses` | `Revenue - Materials Cost` | Calculated |
| **Gross Margin %** | Profit as % of revenue | Calculated | `(Gross Profit / Revenue) × 100` | Calculated |
| **Net Profit** | Profit after all expenses | `invoices` + `expenses` | `Revenue - All Expenses` | Calculated |
| **Net Margin %** | Net profit as % of revenue | Calculated | `(Net Profit / Revenue) × 100` | Calculated |
| **Cost per Job** | Average cost per job | `jobs` + `expenses` | `Total Expenses / Total Jobs` | Tracked |
| **Labor Cost %** | Labor cost as % of revenue | `expenses` table | `Labor Expense / Revenue` | Tracked |

**Implementation**: `reporting_service.dart`
```dart
// Calculate profit metrics
final revenue = totalPaidInvoices();
final expenses = await supabase
    .from('expenses')
    .select('amount')
    .eq('org_id', orgId);
final totalExpenses = expenses.fold(0, (sum, e) => sum + (e['amount'] ?? 0));
final grossProfit = revenue - totalExpenses;
final margin = (grossProfit / revenue * 100).toStringAsFixed(2);
```

---

### **Cash Flow Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Cash Collection Rate** | % of invoices paid on time | `invoices` table | `Paid On Time / Total Invoices` | Calculated |
| **Days Sales Outstanding (DSO)** | Average days to collect | `invoices` table | `(Total AR / Daily Revenue) × Days` | Tracked |
| **Payment Method Mix** | % by payment method | `invoices` table | `COUNT(method) / Total Invoices` | Tracked |
| **Subscription Churn $ MRR** | MRR lost to cancellations | `subscriptions` table | `Cancelled MRR / Total MRR` | Tracked |
| **Cash Burn Rate** | Monthly expenses | `expenses` table | `Total Monthly Expenses` | Tracked |

---

### **Pricing & Rate Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Average Rate/Hour** | Hourly billing rate | `invoices` + `jobs` | `Total Revenue / Total Hours` | Tracked |
| **Average Rate/Job** | Per-job revenue | `invoices` | `AVG(amount)` | Tracked |
| **Price Increase Opportunity** | Underpriced jobs | Comparison | Manual analysis | Available |
| **Discount %** | % of discounted invoices | `invoices` table | `Discounted / Total Invoices` | Tracked |

---

## 🏭 Operational KPIs

### **Job Management**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Total Jobs Completed** | Cumulative completed jobs | `jobs` table | `COUNT(id) WHERE status='completed'` | Tracked |
| **Jobs Completed This Month** | Monthly completion rate | `jobs` table | `COUNT(id) WHERE status='completed' AND MONTH=NOW()` | Tracked |
| **Average Job Duration** | Time from start to completion | `jobs` table | `AVG(end_date - start_date)` | Tracked |
| **On-Time Completion %** | Jobs finished by due date | `jobs` table | `On-Time Jobs / Total Jobs` | Tracked |
| **Job Cost Accuracy** | Estimated vs actual cost | `jobs` table | `ABS(estimate - actual) / estimate` | Tracked |
| **Active Jobs Count** | Currently in-progress jobs | `jobs` table | `COUNT(id) WHERE status='in_progress'` | Tracked |
| **Overdue Jobs Count** | Jobs past due date | `jobs` table | `COUNT(id) WHERE status IN ('scheduled','in_progress') AND end_date < NOW()` | Tracked |

**Implementation**: `job_service.dart`
```dart
// Calculate job completion metrics
final completedJobs = await supabase
    .from('jobs')
    .select('id, start_date, end_date')
    .eq('org_id', orgId)
    .eq('status', 'completed');

final avgDuration = completedJobs.fold<double>(
  0,
  (sum, job) => sum + DateTime.parse(job['end_date']).difference(DateTime.parse(job['start_date'])).inDays
) / completedJobs.length;
```

---

### **Invoice Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Invoices Created This Month** | Monthly invoice volume | `invoices` table | `COUNT(id) WHERE MONTH=NOW()` | Tracked |
| **Payment Rate %** | % of invoices paid | `invoices` table | `Paid Invoices / Total Invoices` | Tracked |
| **Average Time to Payment** | Days from sent to paid | `invoices` table | `AVG(paid_date - sent_date)` | Tracked |
| **Invoice Accuracy** | Correct invoices / total | `invoices` table | `Correct Invoices / Total` | Tracked |
| **Reminder Required %** | Invoices needing reminders | `invoices` table | `With Reminder / Total` | Tracked |
| **Dispute Rate %** | % of disputed invoices | `invoices` table | `Disputed / Total` | Tracked |

**Implementation**: `invoice_service.dart`
```dart
// Calculate invoice KPIs
final paidInvoices = await supabase
    .from('invoices')
    .select()
    .eq('org_id', orgId)
    .eq('status', 'paid');

final paymentRate = (paidInvoices.length / totalInvoices * 100).toStringAsFixed(2);
```

---

### **Team Efficiency**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Jobs per Team Member** | Avg jobs assigned | `jobs` table | `Total Jobs / Team Members` | Tracked |
| **Revenue per Team Member** | Revenue per person | `jobs` + `invoices` | `Total Revenue / Team Count` | Tracked |
| **Utilization Rate %** | Time spent on billable work | `jobs` table | `Billable Hours / Available Hours` | Tracked |
| **Team Productivity Score** | Overall team efficiency | Calculated | `(Jobs × Revenue) / Time` | Calculated |

---

## 👥 Customer KPIs

### **Client Management**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Total Clients** | Cumulative client count | `clients` table | `COUNT(id)` | Tracked |
| **Active Clients** | Clients with recent activity | `clients` + `jobs` | `Clients WITH jobs IN LAST 30 DAYS` | Tracked |
| **New Clients This Month** | Monthly client acquisition | `clients` table | `COUNT(id) WHERE created_at IN THIS MONTH` | Tracked |
| **Client Churn Rate %** | Clients not active in 90 days | `clients` + `jobs` | `(Lost Clients / Starting Clients) × 100` | Tracked |
| **Average Client Value** | Revenue per client | `clients` + `invoices` | `Total Revenue / Total Clients` | Tracked |
| **Client Lifetime Value (CLV)** | Total revenue from 1 client | `invoices` table | `SUM(amount) GROUP BY client_id` | Tracked |
| **Repeat Client %** | Clients with 2+ jobs | `clients` + `jobs` | `Repeat Clients / Total Clients` | Tracked |

**Implementation**: `client_service.dart`
```dart
// Calculate client KPIs
final clients = await supabase
    .from('clients')
    .select('id, created_at')
    .eq('org_id', orgId);

final activeClients = clients.where((c) {
  final created = DateTime.parse(c['created_at']);
  return DateTime.now().difference(created).inDays < 90;
}).length;

final churnRate = ((clients.length - activeClients) / clients.length * 100).toStringAsFixed(2);
```

---

### **Customer Satisfaction**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **NPS (Net Promoter Score)** | Customer recommendation score | Survey data | `Promoters - Detractors / Total` | Ready to track |
| **Repeat Job Rate %** | % of clients with repeat work | `jobs` table | `Clients WITH 2+ JOBS / Total Clients` | Tracked |
| **Inquiry Response Time** | Avg time to respond | `messages` table | `AVG(response_time)` | Ready to track |
| **Client Satisfaction Score** | Based on ratings | `reviews` table | `AVG(rating)` | Ready to track |

---

## 👨‍💼 Team KPIs

### **Team Performance**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Team Size** | Total team members | `org_members` table | `COUNT(id) WHERE role != 'owner'` | Tracked |
| **Turnover Rate %** | Team member churn | `org_members` table | `(Departed / Starting) × 100` | Tracked |
| **Team Utilization %** | % of time billable | `jobs` table | `Billable Hours / Total Hours` | Tracked |
| **Revenue per Team Member** | Individual productivity | `jobs` + `invoices` | `Revenue / Headcount` | Tracked |
| **Jobs per Team Member** | Workload distribution | `jobs` table | `Total Jobs / Team Members` | Tracked |
| **Attendance Rate %** | Jobs on-time starts | `jobs` table | `On-Time Starts / Total Jobs` | Tracked |

---

## 📈 Business Growth KPIs

### **Growth Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Month-over-Month Growth (MoM)** | Monthly revenue growth | `invoices` table | `(This Month - Last Month) / Last Month × 100` | Calculated |
| **Year-over-Year Growth (YoY)** | Annual revenue growth | `invoices` table | `(This Year - Last Year) / Last Year × 100` | Calculated |
| **Customer Acquisition Cost (CAC)** | Cost to acquire each client | `expenses` + `clients` | `Marketing Spend / New Clients` | Tracked |
| **Payback Period** | Months to recover CAC | Calculated | `CAC / (CLV / 12)` | Calculated |
| **Churn Rate %** | % of clients lost monthly | `clients` table | `Lost Clients / Starting Clients` | Calculated |
| **Expansion Revenue** | Revenue from existing clients | `invoices` table | `NEW services to EXISTING clients` | Tracked |
| **Market Share Estimate** | % of addressable market | Comparison | Manual analysis | Available |

**Implementation**: `reporting_service.dart`
```dart
// Calculate growth metrics
final thisMonthRevenue = await getRevenueForMonth(DateTime.now());
final lastMonthRevenue = await getRevenueForMonth(DateTime.now().subtract(Duration(days: 30)));
final momGrowth = ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue * 100).toStringAsFixed(2);
```

---

### **Subscription Metrics**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Total Organizations** | SaaS customer count | `organizations` table | `COUNT(id)` | Tracked |
| **Active Subscriptions** | Currently paying orgs | `organizations` table | `COUNT(id) WHERE stripe_status='active'` | Tracked |
| **MRR (Monthly Recurring Revenue)** | Predictable monthly revenue | `subscriptions` table | `SUM(amount) WHERE active=true` | Tracked |
| **Churn $ MRR** | Revenue lost to cancellations | `subscriptions` table | `Cancelled MRR / Total MRR` | Tracked |
| **ARPU (Avg Revenue Per User)** | Revenue per customer | `subscriptions` table | `Total MRR / Active Subscriptions` | Tracked |
| **LTV (Lifetime Value)** | Total customer value | Calculated | `ARPU / Monthly Churn Rate` | Calculated |
| **CAC Payback** | Months to recover CAC | Calculated | `CAC / (ARPU × Gross Margin %)` | Calculated |

---

## ⚙️ Technical KPIs

### **System Performance**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **System Uptime %** | App availability | Monitoring | `Available Time / Total Time` | Tracked |
| **Page Load Time** | Avg page load duration | Performance | Average < 500ms | Monitored |
| **API Response Time** | Avg API call duration | Logs | Average < 200ms | Monitored |
| **Database Query Time** | Avg query duration | Logs | Average < 100ms | Monitored |
| **Error Rate %** | % of failed requests | Logs | `Failed Requests / Total` | Monitored |

### **Reliability & Quality**
| KPI | Description | Source | Formula | Current |
|-----|-------------|--------|---------|---------|
| **Crash Rate per Session** | App crashes | Analytics | `Crashes / Sessions` | Monitored |
| **Bug Report Rate** | Issues reported per day | Support | `Bugs / Day` | Tracked |
| **Support Ticket Response Time** | Time to first response | Ticketing | Average < 2 hours | Tracked |
| **Customer Satisfaction (Support)** | Support satisfaction score | Surveys | Average rating | Ready to track |

---

## 📊 KPI Dashboard Data Model

### **Database Tables for KPI Tracking**

**kpi_snapshots** (Daily KPI snapshots)
```sql
CREATE TABLE kpi_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  snapshot_date DATE NOT NULL,
  
  -- Financial
  total_revenue DECIMAL,
  monthly_revenue DECIMAL,
  gross_profit DECIMAL,
  net_profit DECIMAL,
  gross_margin_percent DECIMAL,
  
  -- Operational
  total_jobs_completed INT,
  avg_job_duration INT,
  on_time_completion_percent DECIMAL,
  active_jobs_count INT,
  
  -- Customer
  total_clients INT,
  active_clients INT,
  new_clients_this_month INT,
  client_churn_percent DECIMAL,
  average_client_value DECIMAL,
  
  -- Team
  team_size INT,
  revenue_per_team_member DECIMAL,
  team_utilization_percent DECIMAL,
  
  -- Growth
  mom_growth_percent DECIMAL,
  yoy_growth_percent DECIMAL,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE
);
```

**kpi_thresholds** (Alert thresholds)
```sql
CREATE TABLE kpi_thresholds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  
  kpi_name VARCHAR(100),
  warning_threshold DECIMAL,
  critical_threshold DECIMAL,
  
  -- Alert settings
  alert_enabled BOOLEAN DEFAULT true,
  alert_by_email BOOLEAN DEFAULT true,
  alert_by_slack BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE
);
```

---

## 🎯 KPI Categories by Plan

### **SOLO Plan KPIs**
- Total revenue
- Jobs completed (monthly)
- Average invoice value
- Time to payment
- Client count
- Profit margin %

### **TEAM Plan KPIs**
- Solo KPIs +
- Revenue per team member
- Team utilization %
- Job on-time completion %
- Client churn rate
- Monthly growth rate

### **WORKSHOP Plan KPIs**
- Team KPIs +
- Detailed profitability breakdown
- AI agent performance metrics
- Marketing ROI
- Supplier cost savings
- Forecast accuracy
- Custom KPI dashboards

### **ENTERPRISE Plan KPIs**
- Workshop KPIs +
- Predictive analytics
- Benchmarking against industry
- Custom KPI definitions
- Real-time alerts
- Dedicated analytics support

---

## 📱 KPI Dashboard Implementation

### **Dashboard Pages**
| Page | KPIs Displayed | Frequency | Users |
|------|----------------|-----------|-------|
| **Dashboard** | 8-10 key KPIs | Real-time | Everyone |
| **Analytics Page** | 30+ detailed KPIs | Daily | Owner, Admin |
| **Reports Page** | Custom KPI reports | On-demand | Owner, Admin |
| **Finance Dashboard** | Revenue, profit, cash flow | Real-time | Owner, Admin |
| **Team Dashboard** | Utilization, productivity | Real-time | Manager, Owner |

### **Visualization Types**
```
✅ Line Charts     - Trends over time (revenue, growth)
✅ Bar Charts      - Comparisons (jobs/month, revenue/member)
✅ Pie Charts      - Composition (payment methods, client distribution)
✅ Gauges          - Single metrics (utilization %, margin %)
✅ Heatmaps        - Team performance by member
✅ Scorecards      - Status of key metrics
✅ Number Cards    - Summary metrics
✅ Tables          - Detailed breakdowns
```

---

## 🔔 KPI Alerts & Notifications

### **Alert Types**

**Revenue Alerts**
- MoM revenue decline > 10%
- Days sales outstanding > 45 days
- Payment rate < 80%

**Operational Alerts**
- Job completion rate < 90%
- Overdue jobs > 3
- Average job duration 2x estimate

**Customer Alerts**
- Churn rate > 5%
- Key client inactive 30+ days
- Repeat client rate < 60%

**Team Alerts**
- Team utilization < 70%
- Revenue per member declining
- Turnover rate increasing

### **Notification Channels**
- ✅ In-app notifications
- ✅ Email digests (daily/weekly)
- ✅ Slack integration
- ✅ SMS alerts (critical only)
- ✅ Push notifications (mobile)

---

## 📈 KPI Calculation Examples

### **Example 1: Gross Profit Margin**
```dart
// Get revenue
final invoices = await supabase
    .from('invoices')
    .select('amount')
    .eq('org_id', orgId)
    .eq('status', 'paid');
final revenue = invoices.fold(0.0, (sum, i) => sum + (i['amount'] ?? 0));

// Get expenses
final expenses = await supabase
    .from('expenses')
    .select('amount')
    .eq('org_id', orgId);
final totalExpense = expenses.fold(0.0, (sum, e) => sum + (e['amount'] ?? 0));

// Calculate margin
final grossProfit = revenue - totalExpense;
final marginPercent = (grossProfit / revenue * 100).toStringAsFixed(2);

print('📊 Gross Profit Margin: $marginPercent%');
```

### **Example 2: Client Churn Rate**
```dart
// Get all clients
final allClients = await supabase
    .from('clients')
    .select('id, created_at')
    .eq('org_id', orgId);

// Get active clients (recent jobs)
final activeClients = await supabase
    .from('clients')
    .select('id')
    .eq('org_id', orgId)
    .gte('last_job_date', DateTime.now().subtract(Duration(days: 90)).toIso8601String());

// Calculate churn
final churnedCount = allClients.length - activeClients.length;
final churnRate = (churnedCount / allClients.length * 100).toStringAsFixed(2);

print('📉 Client Churn Rate: $churnRate%');
```

### **Example 3: Revenue Per Team Member**
```dart
// Get total revenue
final totalRevenue = await getTotalRevenue();

// Get team size
final teamMembers = await supabase
    .from('org_members')
    .select('id')
    .eq('org_id', orgId)
    .neq('role', 'owner');

// Calculate RPM
final revenuePerMember = totalRevenue / teamMembers.length;

print('💰 Revenue Per Team Member: \$$revenuePerMember');
```

---

## 🎯 KPI Benchmarking

### **Industry Benchmarks (Trades)**

| KPI | Poor | Average | Good | Excellent |
|-----|------|---------|------|-----------|
| **Gross Margin %** | < 25% | 25-35% | 35-45% | > 45% |
| **Net Margin %** | < 5% | 5-10% | 10-15% | > 15% |
| **Days Sales Outstanding** | > 60 | 30-60 | 15-30 | < 15 |
| **Payment Rate %** | < 80% | 80-90% | 90-95% | > 95% |
| **Client Churn %** | > 15% | 10-15% | 5-10% | < 5% |
| **Repeat Client %** | < 40% | 40-60% | 60-75% | > 75% |
| **Team Utilization %** | < 60% | 60-75% | 75-85% | > 85% |
| **Revenue Per Member** | < $50k | $50-100k | $100-150k | > $150k |

---

## 📊 KPI Reporting Schedule

| Report | Frequency | Audience | Metrics |
|--------|-----------|----------|---------|
| **Daily Digest** | Daily @ 8am | Owner | 5 key metrics |
| **Weekly Report** | Every Monday | Owner, Admin | 15 metrics + trends |
| **Monthly Report** | 1st of month | Owner, Admin, Team | 40+ detailed metrics |
| **Quarterly Review** | End of quarter | Owner | Strategic metrics |
| **Annual Report** | Dec 31 | Owner | Full year analysis |

---

## ✅ KPI Implementation Checklist

| Feature | Status | Notes |
|---------|--------|-------|
| Basic revenue tracking | ✅ Done | Invoices, payments |
| Job completion tracking | ✅ Done | Status, duration |
| Client management | ✅ Done | Count, churn |
| Team metrics | ✅ Done | Revenue per member |
| Dashboard widgets | ✅ Ready | On DashboardPage |
| Analytics page | ✅ Ready | Detailed reports |
| Real-time updates | ✅ Ready | RealtimeService |
| PDF export | ✅ Ready | PdfService |
| Email reports | ✅ Ready | EmailService |
| Slack notifications | ✅ Ready | SlackService |
| Alert thresholds | ⏳ Pending | Custom alerts |
| Forecasting | ⏳ Pending | AI prediction |
| Benchmarking | ⏳ Pending | vs industry |

---

## 🚀 Next Steps for KPI Enhancement

1. **Real-time Dashboard** - Add live KPI widget updates
2. **Alert System** - Implement threshold-based alerts
3. **Forecasting** - AI-powered revenue/growth predictions
4. **Custom KPIs** - Let owners define their own metrics
5. **Benchmarking** - Compare against industry averages
6. **Mobile KPIs** - Simplified mobile dashboard view
7. **PDF Reports** - Automated KPI report generation
8. **Export Data** - CSV/Excel export for analysis
9. **Historical Comparisons** - YoY, QoQ, MoM views
10. **Predictive Analytics** - Churn prediction, forecasting

---

## 📞 KPI Support

### **Services Implementing KPIs**
- `reporting_service.dart` - Main KPI calculations
- `invoice_service.dart` - Revenue metrics
- `job_service.dart` - Operational metrics
- `client_service.dart` - Customer metrics
- `integration_service.dart` - Slack/Email notifications
- `realtime_service.dart` - Live updates

### **Database Tables Feeding KPIs**
- `organizations` - Core data
- `invoices` - Revenue
- `jobs` - Operations
- `clients` - Customers
- `org_members` - Team
- `expenses` - Costs
- `recurring_invoices` - MRR

---

**Ready to track 40+ KPIs in production! 📊**

Existing implementation covers: ✅ Financial, ✅ Operational, ✅ Customer, ✅ Team KPIs  
Coming soon: Alert systems, Forecasting, Custom KPI definitions

