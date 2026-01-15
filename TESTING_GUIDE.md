# 🧪 Testing Guide - Complete Testing Strategy

**Version**: 1.0 | **Updated**: January 15, 2026

---

## 📋 Table of Contents

1. [Testing Overview](#testing-overview)
2. [Unit Testing](#unit-testing)
3. [Integration Testing](#integration-testing)
4. [E2E Testing](#e2e-testing)
5. [Manual Testing Checklist](#manual-testing-checklist)
6. [Performance Testing](#performance-testing)
7. [Security Testing](#security-testing)
8. [Plan-Specific Testing](#plan-specific-testing)

---

## Testing Overview

### Test Pyramid

```
         /\
        /  \          E2E Tests (5%)
       /────\         - Full user flows
      /      \        - Critical paths
     /────────\
    /          \     Integration Tests (25%)
   /            \    - Service interactions
  /──────────────\   - Supabase integration
 /                \ 
/__________________\  Unit Tests (70%)
                    - Individual functions
                    - Business logic
                    - Validators
```

### Testing Environments

| Environment | Database | Purpose | Auth |
|-------------|----------|---------|------|
| **Local** | SQLite/local Supabase | Development | Auto-confirm |
| **Staging** | Supabase Dev | Pre-production | Test accounts |
| **Production** | Supabase Prod | Live users | Real auth |

---

## Unit Testing

### Setup

```bash
# Install dependencies
flutter pub add --dev test mocktail

# Run all unit tests
flutter test

# Run specific test file
flutter test test/services/invoice_service_test.dart

# Run with coverage
flutter test --coverage
```

### Service Testing Example

**File**: `test/services/invoice_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:aura_crm/services/invoice_service.dart';

void main() {
  group('InvoiceService', () {
    late InvoiceService invoiceService;

    setUp(() {
      invoiceService = InvoiceService();
    });

    test('createInvoice should validate org_id', () async {
      // Arrange
      final orgId = 'org_123';
      final amount = 500.0;

      // Act & Assert
      expect(
        () => invoiceService.createInvoice(
          orgId: '',  // Empty org_id
          amount: amount,
          clientId: 'client_123',
        ),
        throwsException,
      );
    });

    test('calculateTax should return correct tax amount', () {
      // Arrange
      const amount = 1000.0;
      const taxRate = 0.1; // 10%
      const expected = 100.0;

      // Act
      final result = invoiceService.calculateTax(amount, taxRate);

      // Assert
      expect(result, equals(expected));
    });

    test('getInvoicesByStatus returns filtered invoices', () async {
      // Arrange
      final orgId = 'org_123';
      final status = 'paid';

      // Act
      final invoices = await invoiceService.getInvoicesByStatus(
        orgId: orgId,
        status: status,
      );

      // Assert
      expect(invoices, isNotEmpty);
      expect(invoices, everyElement((invoice) => invoice['status'] == 'paid'));
    });

    group('Invoice Validation', () {
      test('validateInvoice throws on missing client_id', () {
        expect(
          () => invoiceService.validateInvoice({'amount': 500}),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateInvoice throws on invalid amount', () {
        expect(
          () => invoiceService.validateInvoice({
            'amount': -100,
            'client_id': 'client_123',
          }),
          throwsA(isA<ValidationException>()),
        );
      });

      test('validateInvoice accepts valid invoice', () {
        final validInvoice = {
          'amount': 500.0,
          'client_id': 'client_123',
          'due_date': '2026-02-15',
          'currency': 'USD',
        };

        expect(
          () => invoiceService.validateInvoice(validInvoice),
          returnsNormally,
        );
      });
    });
  });
}
```

### Validator Testing Example

**File**: `test/validators/email_validator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_crm/validators/email_validator.dart';

void main() {
  group('EmailValidator', () {
    late EmailValidator validator;

    setUp(() {
      validator = EmailValidator();
    });

    test('valid emails pass validation', () {
      final validEmails = [
        'user@example.com',
        'john.smith@company.co.uk',
        'first.last+tag@email.org',
      ];

      for (final email in validEmails) {
        expect(validator.isValid(email), isTrue);
      }
    });

    test('invalid emails fail validation', () {
      final invalidEmails = [
        'invalid.email',
        '@example.com',
        'user@',
        'user @example.com',
        '',
      ];

      for (final email in invalidEmails) {
        expect(validator.isValid(email), isFalse);
      }
    });
  });
}
```

### Running Unit Tests

```bash
# Run all tests
flutter test

# Run with output
flutter test --verbose

# Run with coverage
flutter test --coverage

# View coverage (install lcov first)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Integration Testing

### Setup

```bash
# Install integration_test
flutter pub add --dev integration_test

# Create test file: test_driver/integration_test.dart
```

### Integration Test Example

**File**: `integration_test/invoice_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aura_crm/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Invoice Creation Flow', () {
    testWidgets('User can create and send invoice', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to invoices
      await tester.tap(find.byIcon(Icons.receipt));
      await tester.pumpAndSettle();

      // Tap create button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill invoice form
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Test Client',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '500',
      );

      // Submit
      await tester.tap(find.byText('Create Invoice'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.byText('Invoice created successfully'), findsOneWidget);

      // Verify invoice appears in list
      expect(find.byText('Test Client'), findsOneWidget);
    });
  });

  group('Payment Processing', () {
    testWidgets('Stripe payment link generates correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Create invoice
      // ... (setup code)

      // Generate payment link
      await tester.tap(find.byText('Generate Payment Link'));
      await tester.pumpAndSettle();

      // Verify link is displayed
      expect(find.byText('Payment link copied to clipboard'), findsOneWidget);
    });
  });
}
```

### Running Integration Tests

```bash
# Run integration tests (web)
flutter test integration_test/invoice_flow_test.dart -d chrome

# Run on Android
flutter test integration_test/invoice_flow_test.dart -d android

# Run on iOS
flutter test integration_test/invoice_flow_test.dart -d ios
```

---

## E2E Testing

### Supabase Integration Testing

**File**: `test/e2e/auth_flow_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Authentication E2E', () {
    late Supabase supabase;

    setUpAll(() async {
      // Initialize Supabase for testing
      await Supabase.initialize(
        url: 'https://fppmuibvpxrkwmymszhd.supabase.co',
        anonKey: 'test_anon_key',
        authCallbackUrlHostname: 'localhost:8080',
      );
      supabase = Supabase.instance;
    });

    test('User signup and organization creation', () async {
      // Create user
      final authResponse = await supabase.auth.signUp(
        email: 'testuser_${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'TestPassword123!',
      );

      expect(authResponse.user, isNotNull);
      expect(authResponse.user!.id, isNotEmpty);

      // Verify organization was created
      final orgResponse = await supabase
          .from('organizations')
          .select()
          .eq('owner_id', authResponse.user!.id)
          .maybeSingle();

      expect(orgResponse, isNotNull);
    });

    test('RLS policy prevents cross-org data access', () async {
      // Create two users
      final user1 = await supabase.auth.signUp(
        email: 'user1_${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'Password123!',
      );

      // Sign in as user1
      await supabase.auth.signInWithPassword(
        email: user1.user!.email!,
        password: 'Password123!',
      );

      // Try to access another org's data
      final data = await supabase
          .from('invoices')
          .select()
          .eq('org_id', 'other_org_id')
          .maybeSingle();

      // Should be empty due to RLS
      expect(data, isNull);
    });

    test('Invoice CRUD operations with RLS', () async {
      final user = supabase.auth.currentUser!;
      
      // Get user's org
      final org = await supabase
          .from('organizations')
          .select('id')
          .eq('owner_id', user.id)
          .single();

      final orgId = org['id'];

      // CREATE invoice
      final createResponse = await supabase
          .from('invoices')
          .insert({
            'org_id': orgId,
            'client_id': 'client_123',
            'amount': 500.0,
            'status': 'draft',
          })
          .select()
          .single();

      expect(createResponse['id'], isNotEmpty);
      final invoiceId = createResponse['id'];

      // READ invoice
      final readResponse = await supabase
          .from('invoices')
          .select()
          .eq('id', invoiceId)
          .single();

      expect(readResponse['id'], equals(invoiceId));
      expect(readResponse['org_id'], equals(orgId));

      // UPDATE invoice
      final updateResponse = await supabase
          .from('invoices')
          .update({'status': 'sent'})
          .eq('id', invoiceId)
          .select()
          .single();

      expect(updateResponse['status'], equals('sent'));

      // DELETE invoice
      await supabase
          .from('invoices')
          .delete()
          .eq('id', invoiceId);

      final deletedCheck = await supabase
          .from('invoices')
          .select()
          .eq('id', invoiceId)
          .maybeSingle();

      expect(deletedCheck, isNull);
    });
  });
}
```

---

## Manual Testing Checklist

### Pre-Release Checklist

#### Authentication & Authorization
- [ ] User can sign up with valid email/password
- [ ] User receives confirmation email
- [ ] User can sign in with correct credentials
- [ ] User cannot sign in with incorrect credentials
- [ ] User can reset forgotten password
- [ ] User cannot access protected pages without auth
- [ ] Session persists after app restart (on mobile)
- [ ] User can sign out
- [ ] Token refresh works seamlessly

#### Invoicing (All Plans)
- [ ] User can create invoice with valid data
- [ ] System validates required fields
- [ ] System prevents negative amounts
- [ ] User can view invoice list with pagination
- [ ] User can search/filter invoices
- [ ] User can update invoice details
- [ ] User can generate PDF
- [ ] User can send invoice via email
- [ ] Invoice status updates correctly
- [ ] Overdue status calculates correctly

#### Jobs (All Plans)
- [ ] User can create job with all details
- [ ] User can assign job to team member (Team+ plans)
- [ ] Job status transitions work (scheduled → in progress → completed)
- [ ] Job list displays with correct filtering
- [ ] User can mark job complete and create invoice

#### Team Management (Team+ Plans)
- [ ] Owner can invite team members
- [ ] Invited team member receives email
- [ ] Team member can accept invitation
- [ ] Team member appears in team list
- [ ] Owner can change team member role
- [ ] Owner can remove team member
- [ ] Removed team member loses access

#### Device Management (Team+ Plans)
- [ ] Owner can register mobile device
- [ ] Owner can register tablet device
- [ ] System prevents exceeding device limit
- [ ] Device code generated and sent to team member
- [ ] Team member can activate device with code
- [ ] Features display correctly on activated device

#### Feature Personalization (All Plans)
- [ ] User can view available features
- [ ] User can enable/disable features
- [ ] Feature count respects max for device type
- [ ] User can reorder features
- [ ] Owner can force enable all features on device
- [ ] Owner can disable specific features
- [ ] Owner can lock features org-wide
- [ ] Audit log shows all changes

#### Payments (Plan-Dependent)
- [ ] Stripe checkout session creates successfully
- [ ] User redirected to Stripe checkout
- [ ] Payment processing succeeds
- [ ] Webhook updates subscription status
- [ ] Features unlock after payment
- [ ] Device limits apply based on plan
- [ ] Prepayment code validates correctly
- [ ] Code redemption applies plan upgrade

#### AI Agents (Plan-Dependent)
- **Solo Plan**:
  - [ ] Job automation runs
  - [ ] Jobs auto-assigned to team members
  - [ ] Team members notified

- **Team Plan**:
  - [ ] Job automation runs (full)
  - [ ] CFO agent: overdue reminders sent
  - [ ] CEO agent: revenue summary generated
  - [ ] Marketing agent: inactive clients identified
  - [ ] Sales agent: client scoring runs

- **Workshop Plan**:
  - [ ] All agents available with full features
  - [ ] Advanced CFO budget tracking
  - [ ] Strategic CEO recommendations
  - [ ] Campaign automation in Marketing

#### Integrations (Plan-Dependent)
- [ ] WhatsApp message sends correctly
- [ ] Email sends via Resend
- [ ] HubSpot sync works (Workshop+ only)
- [ ] QuickBooks sync works (Workshop+ only)
- [ ] Google Calendar integration works
- [ ] Slack notifications send

#### Real-Time Features
- [ ] Invoice updates reflect in real-time
- [ ] Job status changes broadcast to team
- [ ] Presence shows online/offline status
- [ ] Multiple users see changes simultaneously

#### Security
- [ ] User cannot access other org's data
- [ ] RLS policies block unauthorized queries
- [ ] API keys not exposed in frontend
- [ ] HTTPS enforced
- [ ] Session tokens validate correctly
- [ ] CSRF protection active

---

## Performance Testing

### Load Testing

```bash
# Install Apache Bench
brew install httpd

# Test API endpoint
ab -n 1000 -c 10 \
  -H "Authorization: Bearer <token>" \
  https://fppmuibvpxrkwmymszhd.supabase.co/rest/v1/invoices

# Expected results:
# - Average response time: < 100ms
# - 95th percentile: < 200ms
# - Errors: < 1%
```

### Database Query Performance

```dart
// Benchmark query performance
void benchmarkInvoiceQuery() {
  final stopwatch = Stopwatch()..start();

  final invoices = await supabase
      .from('invoices')
      .select()
      .eq('org_id', orgId)
      .lt('due_date', overdueDate);

  stopwatch.stop();

  print('Query time: ${stopwatch.elapsedMilliseconds}ms');
  // Target: < 50ms for indexed queries
}
```

### Mobile App Performance

```bash
# Profile app performance
flutter run --profile -d android

# Memory usage
flutter devtools

# Frame rendering
DevTools → Performance tab
```

---

## Security Testing

### OWASP Top 10 Checklist

- [ ] **A01:2021** - Broken Access Control
  - Test RLS policies prevent cross-org access
  - Verify auth checks on protected pages

- [ ] **A02:2021** - Cryptographic Failures
  - Verify HTTPS enforced
  - Check API keys not exposed
  - Validate encrypted storage

- [ ] **A03:2021** - Injection
  - Test SQL injection protection (Supabase handles)
  - Verify parametrized queries used
  - Check XSS protection in web version

- [ ] **A04:2021** - Insecure Design
  - Verify RLS policies comprehensive
  - Check authentication flows secure

- [ ] **A05:2021** - Security Misconfiguration
  - Review CORS settings
  - Verify HTTPS certificate valid
  - Check Supabase dashboard security

- [ ] **A06:2021** - Vulnerable Components
  - Run `flutter pub outdated`
  - Check for known vulnerabilities: `flutter pub get --security-updates`

- [ ] **A07:2021** - Identification and Authentication Failures
  - Test password requirements
  - Verify session management
  - Check account lockout after failures

- [ ] **A08:2021** - Software and Data Integrity Failures
  - Verify webhook signature validation
  - Check payment webhook authenticity

- [ ] **A09:2021** - Logging & Monitoring Failures
  - Verify audit logs created
  - Check error logging
  - Monitor failed auth attempts

- [ ] **A10:2021** - Server-Side Request Forgery (SSRF)
  - Verify Edge Functions validate inputs
  - Check external API calls sanitized

### Penetration Testing Scenarios

```dart
// Test 1: Cross-Org Data Access
test('RLS prevents accessing other org invoices', () async {
  // Create two orgs with different owners
  final org1 = await createOrganization('owner1@example.com');
  final org2 = await createOrganization('owner2@example.com');

  // Sign in as org1 owner
  await signIn('owner1@example.com');

  // Try to query org2's invoices
  final invoices = await supabase
      .from('invoices')
      .select()
      .eq('org_id', org2['id']);

  // Should return empty (RLS blocked)
  expect(invoices, isEmpty);
});

// Test 2: Device Limit Enforcement
test('Cannot exceed device limit for plan', () async {
  final org = await createOrganization('owner@example.com', plan: 'solo');
  
  // Register 2 mobile devices (limit for solo)
  await registerDevice(org['id'], 'mobile', 'Device 1');
  await registerDevice(org['id'], 'mobile', 'Device 2');

  // Try to register 3rd device (should fail)
  expect(
    () => registerDevice(org['id'], 'mobile', 'Device 3'),
    throwsException,
  );
});

// Test 3: Feature Lock Enforcement
test('Cannot unlock locked features as team member', () async {
  final org = await createOrganization('owner@example.com', plan: 'team');
  
  // Owner locks features
  await lockFeaturesOrgWide(org['id'], ['ai_agents'], 'Compliance');

  // Sign in as team member
  await signIn('member@example.com');

  // Try to enable locked feature (should fail)
  expect(
    () => enableFeature(org['id'], 'ai_agents'),
    throwsException,
  );
});
```

---

## Plan-Specific Testing

### SOLO Plan Testing (`$9.99/month`)

```dart
group('SOLO Plan Features', () {
  late String orgId;

  setUp(() async {
    orgId = await createOrg(plan: 'solo');
  });

  test('Can create only 25 jobs per month', () async {
    // Create 25 jobs
    for (int i = 0; i < 25; i++) {
      await createJob(orgId);
    }

    // Try to create 26th (should fail)
    expect(
      () => createJob(orgId),
      throwsException,
    );
  });

  test('Can register max 2 mobile devices', () async {
    await registerDevice(orgId, 'mobile', 'Device 1');
    await registerDevice(orgId, 'mobile', 'Device 2');

    expect(
      () => registerDevice(orgId, 'mobile', 'Device 3'),
      throwsException,
    );
  });

  test('Can register max 1 tablet device', () async {
    await registerDevice(orgId, 'tablet', 'iPad');

    expect(
      () => registerDevice(orgId, 'tablet', 'iPad Pro'),
      throwsException,
    );
  });

  test('Only 6 features available', () async {
    final features = await getAvailableFeatures(orgId, 'mobile');
    expect(features.length, equals(6));
  });

  test('Job automation agent available', () async {
    // Should succeed
    expect(
      () => runJobAutomationAgent(orgId),
      returnsNormally,
    );
  });

  test('AI agents not available (CFO, CEO, etc)', () async {
    expect(
      () => runCFOAgent(orgId),
      throwsA(isA<PlanFeatureNotAvailableException>()),
    );

    expect(
      () => runCEOAgent(orgId),
      throwsA(isA<PlanFeatureNotAvailableException>()),
    );
  });
});
```

### TEAM Plan Testing (`$15/month`)

```dart
group('TEAM Plan Features', () {
  late String orgId;

  setUp(() async {
    orgId = await createOrg(plan: 'team');
  });

  test('Can manage up to 3 users', () async {
    // Invite 2 team members
    await inviteTeamMember(orgId, 'member1@example.com');
    await inviteTeamMember(orgId, 'member2@example.com');

    // Both should be added
    final members = await getTeamMembers(orgId);
    expect(members.length, equals(3)); // owner + 2 members
  });

  test('Can register max 3 mobile devices', () async {
    for (int i = 0; i < 3; i++) {
      await registerDevice(orgId, 'mobile', 'Device $i');
    }

    expect(
      () => registerDevice(orgId, 'mobile', 'Device 4'),
      throwsException,
    );
  });

  test('Can register max 2 tablet devices', () async {
    await registerDevice(orgId, 'tablet', 'iPad 1');
    await registerDevice(orgId, 'tablet', 'iPad 2');

    expect(
      () => registerDevice(orgId, 'tablet', 'iPad 3'),
      throwsException,
    );
  });

  test('8 features available', () async {
    final features = await getAvailableFeatures(orgId, 'mobile');
    expect(features.length, equals(8));
  });

  test('All AI agents available (limited)', () async {
    // Should succeed with limited features
    expect(() => runJobAutomationAgent(orgId), returnsNormally);
    expect(() => runCFOAgent(orgId), returnsNormally);
    expect(() => runCEOAgent(orgId), returnsNormally);
    expect(() => runMarketingAgent(orgId), returnsNormally);
    expect(() => runSalesAgent(orgId), returnsNormally);
  });

  test('CFO Agent limited: overdue reminders only', () async {
    final result = await runCFOAgent(orgId);
    
    // Should have overdue reminders (limited feature)
    expect(result['overdue_reminders_sent'], isNotNull);
    
    // Should NOT have advanced features
    expect(result['budget_tracking'], isNull);
    expect(result['cash_flow_forecast'], isNull);
  });
});
```

### WORKSHOP Plan Testing (`$29/month`)

```dart
group('WORKSHOP Plan Features', () {
  late String orgId;

  setUp(() async {
    orgId = await createOrg(plan: 'workshop');
  });

  test('Can manage up to 7 users', () async {
    for (int i = 0; i < 6; i++) {
      await inviteTeamMember(orgId, 'member$i@example.com');
    }

    final members = await getTeamMembers(orgId);
    expect(members.length, equals(7)); // owner + 6 members
  });

  test('Can register max 5 mobile devices', () async {
    for (int i = 0; i < 5; i++) {
      await registerDevice(orgId, 'mobile', 'Device $i');
    }

    expect(
      () => registerDevice(orgId, 'mobile', 'Device 6'),
      throwsException,
    );
  });

  test('Can register max 3 tablet devices', () async {
    for (int i = 0; i < 3; i++) {
      await registerDevice(orgId, 'tablet', 'iPad $i');
    }

    expect(
      () => registerDevice(orgId, 'tablet', 'iPad 4'),
      throwsException,
    );
  });

  test('13+ features available', () async {
    final features = await getAvailableFeatures(orgId, 'mobile');
    expect(features.length, greaterThanOrEqualTo(13));
  });

  test('All AI agents available (full capability)', () async {
    // All agents should work with full features
    expect(() => runJobAutomationAgent(orgId), returnsNormally);
    expect(() => runCFOAgent(orgId), returnsNormally);
    expect(() => runCEOAgent(orgId), returnsNormally);
    expect(() => runMarketingAgent(orgId), returnsNormally);
    expect(() => runSalesAgent(orgId), returnsNormally);
  });

  test('CFO Agent full features available', () async {
    final result = await runCFOAgent(orgId);
    
    // Should have all features
    expect(result['overdue_reminders_sent'], isNotNull);
    expect(result['budget_tracking'], isNotNull);
    expect(result['cash_flow_forecast'], isNotNull);
    expect(result['invoice_generation_automation'], isNotNull);
  });

  test('All integrations available', () async {
    expect(() => sendWhatsAppMessage(orgId, 'test'), returnsNormally);
    expect(() => sendEmail(orgId, 'test'), returnsNormally);
    expect(() => syncHubSpot(orgId), returnsNormally);
    expect(() => syncQuickBooks(orgId), returnsNormally);
  });
});
```

---

## Continuous Testing

### GitHub Actions CI/CD

**File**: `.github/workflows/tests.yml`

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run unit tests
        run: flutter test
      
      - name: Run integration tests
        run: flutter test integration_test/
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

---

## Test Reporting

### Coverage Goals

| Component | Target Coverage |
|-----------|-----------------|
| Services | 80%+ |
| Validators | 95%+ |
| UI Pages | 60%+ |
| Overall | 70%+ |

### Generate Coverage Report

```bash
# Generate coverage
flutter test --coverage

# Install lcov (macOS)
brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

---

Generated: January 15, 2026
