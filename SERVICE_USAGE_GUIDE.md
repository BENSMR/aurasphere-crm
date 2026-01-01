# 📚 Service Usage Guide - Quick Reference

## Real-Time Service
```dart
import 'services/realtime_service.dart';

final realtimeService = RealtimeService();

// Listen to job updates
realtimeService.listenToJobs(orgId, (data, action) {
  print('Job $action: $data');
});

// Broadcast user presence
realtimeService.broadcastPresence(
  orgId,
  'job_list_page',
  'viewing_jobs',
);

// Cleanup on dispose
realtimeService.unsubscribeAll();
```

## Reporting Service
```dart
import 'services/reporting_service.dart';

final reportingService = ReportingService();

// Generate revenue report
final report = await reportingService.generateRevenueReport(
  orgId: orgId,
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 12, 31),
);
// Returns: {total_revenue, paid_revenue, pending_revenue, payment_rate}

// Export as JSON
final json = reportingService.exportReportAsJson(report, 'revenue');
// Ready for PDF conversion
```

## Stripe Service
```dart
import 'services/stripe_service.dart';

final stripeService = StripeService();

// Create subscription
final sub = await stripeService.createSubscription(
  orgId: orgId,
  planPriceId: 'price_team',
  customerEmail: 'org@example.com',
);

// Create payment intent for invoice
final paymentIntent = await stripeService.createPaymentIntent(
  invoiceId: invoiceId,
  amount: 500.00,
  orgId: orgId,
);

// Confirm payment (call from webhook)
await stripeService.confirmInvoicePayment(
  invoiceId: invoiceId,
  paymentIntentId: intentId,
  status: 'succeeded',
);

// Update plan
await stripeService.updateSubscriptionPlan(
  orgId: orgId,
  newPlanPriceId: 'price_workshop',
);
```

## Notification Service
```dart
import 'services/notification_service.dart';

final notificationService = NotificationService();

// Send SMS
await notificationService.sendSMS(
  phoneNumber: '+11234567890',
  message: 'Your invoice of \$500 is due tomorrow',
);

// Notify job assignment
await notificationService.notifyJobUpdate(
  jobId: jobId,
  jobTitle: 'Electrical Rewiring',
  technicianPhone: '+11234567890',
  updateType: 'assigned', // or 'started', 'completed', 'rescheduled'
);

// Invoice reminder
await notificationService.notifyInvoiceReminder(
  invoiceId: invoiceId,
  clientPhone: '+19876543210',
  amount: 250.00,
  dueDate: dueDate,
  businessName: 'ElectroWorks',
);

// Get user preferences
final prefs = await notificationService.getUserPreferences(userId);

// Update preferences
await notificationService.updateUserPreferences(
  userId: userId,
  preferences: {
    'job_updates': true,
    'invoice_reminders': true,
    'payment_notifications': true,
    'team_alerts': false,
  },
);
```

## White-Label Service
```dart
import 'services/whitelabel_service.dart';

final whiteLabelService = WhiteLabelService();

// Get branding config
final branding = await whiteLabelService.getBrandingConfig(orgId);
print('Business: ${branding.businessName}');
print('Color: ${branding.primaryColor}');

// Update branding
await whiteLabelService.updateBrandingConfig(
  orgId: orgId,
  config: BrandingConfig(
    primaryColor: '#FF6B35',
    secondaryColor: '#004E89',
    accentColor: '#1982C4',
    businessName: 'TechServices Inc',
    logoUrl: 'https://example.com/logo.png',
    customStrings: {'app_title': 'My Service App'},
  ),
);

// Register custom domain
await whiteLabelService.registerCustomDomain(
  orgId: orgId,
  domain: 'mycompany.auracrm.app',
);

// Create reseller account
final reseller = await whiteLabelService.createResellerAccount(
  resellerName: 'Partner Company',
  resellerEmail: 'admin@partner.com',
  parentOrgId: parentOrgId,
  brandingConfig: customBranding,
);

// Apply theme to app
final theme = whiteLabelService.getWhiteLabelTheme(branding);
// Use in MaterialApp(theme: theme)
```

## Offline Service
```dart
import 'services/offline_service.dart';

final offlineService = OfflineService();

// Initialize on app startup
await offlineService.initialize();

// Set online/offline status
offlineService.setOnlineStatus(true); // or false

// Save data locally
await offlineService.saveJob(jobData);
await offlineService.saveInvoice(invoiceData);

// Queue operations
await offlineService.queueOperation(
  table: 'jobs',
  operation: 'update',
  data: {'id': jobId, 'status': 'completed'},
);

// Get offline data
final jobs = await offlineService.getOfflineJobs(orgId);
final invoices = await offlineService.getOfflineInvoices(orgId);

// Check sync status
final status = await offlineService.getSyncStatus();
print('${status['pending_operations']} ops pending');

// Cleanup
offlineService.dispose();
```

## Integration Service
```dart
import 'services/integration_service.dart';

final integrationService = IntegrationService();

// Activate Slack integration
await integrationService.activateIntegration(
  orgId: orgId,
  integrationName: 'slack',
  credentials: {
    'webhook_url': 'https://hooks.slack.com/services/...',
  },
);

// Send Slack message
await integrationService.notifySlack(
  orgId: orgId,
  jobId: jobId,
  jobTitle: 'Plumbing Installation',
  updateType: 'completed',
  assignedTo: 'John Smith',
);

// Activate HubSpot
await integrationService.activateIntegration(
  orgId: orgId,
  integrationName: 'hubspot',
  credentials: {
    'access_token': 'your-hubspot-token',
  },
);

// Sync jobs to HubSpot
await integrationService.syncJobsToHubSpot(orgId: orgId);

// Trigger Zapier workflow
await integrationService.triggerZapier(
  orgId: orgId,
  triggerName: 'new_invoice',
  data: {
    'invoice_id': invoiceId,
    'amount': amount,
    'client': clientName,
  },
);

// Get active integrations
final active = await integrationService.getActiveIntegrations(orgId);
```

## Backup Service
```dart
import 'services/backup_service.dart';

final backupService = BackupService();

// Initialize automatic backups (24-hour interval)
await backupService.initializeBackupSchedule(
  orgId: orgId,
  intervalHours: 24,
);

// Manual backup
final backup = await backupService.triggerManualBackup(orgId);
print('Backup ID: ${backup['backup_id']}');

// List all backups
final backups = await backupService.listBackups(orgId);
for (var backup in backups) {
  print('${backup['id']}: ${backup['created_at']}');
}

// Restore from backup
final success = await backupService.restoreFromBackup(
  orgId: orgId,
  backupId: backupId,
);

// Get backup stats
final stats = await backupService.getBackupStats(orgId);
print('Total backups: ${stats['total_backups']}');
print('Storage used: ${stats['total_storage_used']} bytes');

// Cleanup on dispose
backupService.dispose();
```

## Calendar Page
```dart
// Add to routes in main.dart:
'/calendar': (context) => const CalendarPage(),

// Navigate to calendar
Navigator.pushNamed(context, '/calendar');

// Features:
// - Month view: See all jobs in a calendar grid
// - Week view: Horizontal 7-day view
// - Click job: View details in dialog
// - Drag to reschedule: Change job date (future enhancement)
// - Status colors: Pending (blue), In Progress (orange), Done (green)
```

---

## Environment Variables Required

Create `.env` file in project root:

```env
# Supabase (already set)
SUPABASE_URL=https://fppmvibvpxrkwmymszhd.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...

# Stripe
STRIPE_SECRET_KEY=sk_test_51234567890...
STRIPE_PUBLISHABLE_KEY=pk_test_51234567890...

# Twilio
TWILIO_ACCOUNT_SID=AC1234567890abcdef...
TWILIO_AUTH_TOKEN=your_auth_token_here...
TWILIO_PHONE_NUMBER=+1234567890

# Optional: API Keys for other integrations
HUBSPOT_API_KEY=pat-na1-...
ZAPIER_WEBHOOK_URL=https://hooks.zapier.com/hooks/catch/...
```

---

## Common Integration Patterns

### Pattern 1: Real-time + Offline
```dart
// Show real-time updates when online, offline cache when not
if (isOnline) {
  // Listen to realtime updates
  realtimeService.listenToJobs(orgId, onUpdate);
} else {
  // Load from offline cache
  final cachedJobs = await offlineService.getOfflineJobs(orgId);
  displayJobs(cachedJobs);
}
```

### Pattern 2: Job Completion Workflow
```dart
// 1. User marks job complete in app
// 2. Offline service queues update if offline
// 3. Real-time updates team when synced
// 4. SMS notifies client via notification service
// 5. HubSpot deal updated via integration service
// 6. Revenue report regenerated via reporting service
```

### Pattern 3: Multi-tenant with White-label
```dart
// 1. Determine org from custom domain or user
// 2. Load org's branding config
// 3. Apply theme to app
// 4. All routes/pages use org-specific branding
// 5. For resellers: show child org metrics in dashboard
```

---

**All services are ready for integration into your UI pages!**
