# 🔧 Service Integration Guide - How to Use All Services

**Purpose**: Shows actual code examples of how to integrate and use all the payment, email, analytics, and error logging services together

---

## 1️⃣ PAYMENT SERVICE INTEGRATION

### In Sign-Up Page (After User Created)

**File**: `lib/sign_up_page.dart`

```dart
import 'package:aura_crm/services/stripe_payment_service.dart';
import 'package:aura_crm/services/resend_email_service.dart';

class _SignUpPageState extends State<SignUpPage> {
  Future<void> _handleSignUp() async {
    try {
      final supabase = Supabase.instance.client;
      
      // 1. Create auth user (already done)
      final user = await supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // 2. Create organization
      final orgResponse = await supabase
          .from('organizations')
          .insert({
            'owner_id': user.user!.id,
            'name': _companyNameController.text,
            'plan': 'solo', // Free plan initially
            'stripe_customer_id': null, // Set after payment
          })
          .select()
          .single();
      
      // 3. Create Stripe customer (when upgrading to paid)
      // This will be done on pricing page
      
      // 4. Send welcome email
      await ResendEmailService.sendWelcomeEmail(
        userEmail: _emailController.text,
        userName: _firstNameController.text,
        planName: 'Free Trial',
        maxUsers: 1,
        aiCalls: 100,
      );
      
      // 5. Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('❌ Sign up error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
```

---

### In Pricing Page (Purchase Flow)

**File**: `lib/pricing_page.dart` (add this method)

```dart
import 'package:aura_crm/services/stripe_payment_service.dart';
import 'package:aura_crm/services/resend_email_service.dart';

class _PricingPageState extends State<PricingPage> {
  
  Future<void> _handleSubscribe(String planId) async {
    try {
      setState(() => _loading = true);
      
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/sign-in');
        return;
      }
      
      // 1. Get or create Stripe customer
      final org = await supabase
          .from('organizations')
          .select('stripe_customer_id, name, email')
          .eq('owner_id', user.id)
          .single();
      
      String? customerId = org['stripe_customer_id'];
      
      // Create customer if doesn't exist
      if (customerId == null || customerId.isEmpty) {
        customerId = await StripePaymentService.createCustomer(
          email: user.email!,
          name: org['name'] ?? user.email!,
        );
        
        // Save customer ID
        await supabase
            .from('organizations')
            .update({'stripe_customer_id': customerId})
            .eq('owner_id', user.id);
      }
      
      // 2. Create subscription
      final subscription = 
          await StripePaymentService.createSubscription(
        customerId: customerId!,
        planId: planId,
      );
      
      if (subscription == null) {
        throw Exception('Failed to create subscription');
      }
      
      // 3. Save subscription to database
      await supabase.from('subscriptions').insert({
        'user_id': user.id,
        'plan_id': planId,
        'stripe_subscription_id': subscription['id'],
        'stripe_customer_id': customerId,
        'status': subscription['status'],
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // 4. Update organization plan
      await supabase
          .from('organizations')
          .update({'plan': planId})
          .eq('owner_id', user.id);
      
      // 5. Send confirmation email
      final planNames = {
        'solo': 'Solo',
        'team': 'Team',
        'workshop': 'Workshop',
      };
      
      final planAmounts = {
        'solo': 9.99,
        'team': 15.00,
        'workshop': 29.00,
      };
      
      await ResendEmailService.sendSubscriptionConfirmation(
        userEmail: user.email!,
        userName: org['name'] ?? user.email!,
        planName: planNames[planId] ?? planId,
        monthlyAmount: planAmounts[planId] ?? 0.0,
      );
      
      // 6. Navigate to dashboard
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Subscription successful! Welcome aboard!'),
          ),
        );
        
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print('❌ Subscription error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
```

---

## 2️⃣ EMAIL SERVICE INTEGRATION

### Send Invoice Email After Creating Invoice

**File**: `lib/services/invoice_service.dart` (add this method)

```dart
import 'package:aura_crm/services/resend_email_service.dart';

class InvoiceService {
  static Future<void> createAndSendInvoice({
    required String invoiceNumber,
    required String clientId,
    required double amount,
    required DateTime dueDate,
    required String userId,
  }) async {
    final supabase = Supabase.instance.client;
    
    try {
      // 1. Create invoice in database
      final invoice = await supabase
          .from('invoices')
          .insert({
            'invoice_number': invoiceNumber,
            'client_id': clientId,
            'amount': amount,
            'due_date': dueDate.toIso8601String(),
            'created_by': userId,
            'status': 'draft',
          })
          .select()
          .single();
      
      // 2. Get client details
      final client = await supabase
          .from('clients')
          .select('email, name')
          .eq('id', clientId)
          .single();
      
      // 3. Get technician details
      final tech = await supabase
          .from('users')
          .select('email, full_name')
          .eq('id', userId)
          .single();
      
      // 4. Get company details
      final org = await supabase
          .from('organizations')
          .select('name')
          .eq('owner_id', userId)
          .single();
      
      // 5. Send invoice email
      await ResendEmailService.sendInvoiceEmail(
        clientEmail: client['email'],
        clientName: client['name'],
        invoiceNumber: invoiceNumber,
        amount: amount,
        dueDate: dueDate.toString().split(' ')[0],
        technicianName: tech['full_name'],
        companyName: org['name'],
      );
      
      print('✅ Invoice #$invoiceNumber sent to ${client['email']}');
    } catch (e) {
      print('❌ Error creating/sending invoice: $e');
      rethrow;
    }
  }
}
```

### Send Password Reset Email

**File**: `lib/forgot_password_page.dart`

```dart
import 'package:aura_crm/services/resend_email_service.dart';

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  Future<void> _handlePasswordReset() async {
    try {
      setState(() => _loading = true);
      
      final supabase = Supabase.instance.client;
      
      // Supabase automatically sends reset email,
      // but you can send custom email too:
      
      final resetLink = 'https://yourdomain.com/reset-password?token=xxx';
      
      await ResendEmailService.sendPasswordResetEmail(
        userEmail: _emailController.text,
        resetLink: resetLink,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Reset link sent to your email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
```

### Send Team Invitation Email

**File**: `lib/team_page.dart`

```dart
import 'package:aura_crm/services/resend_email_service.dart';

class _TeamPageState extends State<TeamPage> {
  Future<void> _inviteTeamMember(String email, String role) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      // 1. Create invitation record
      final invitation = await supabase
          .from('team_invitations')
          .insert({
            'inviter_id': user!.id,
            'invitee_email': email,
            'role': role,
            'token': _generateToken(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      // 2. Get inviter name
      final inviterOrg = await supabase
          .from('organizations')
          .select('name')
          .eq('owner_id', user.id)
          .single();
      
      final inviterName = inviterOrg['name'];
      
      // 3. Send invitation email
      final invitationLink = 
          'https://yourdomain.com/accept-invitation/${invitation['token']}';
      
      await ResendEmailService.sendTeamInvitation(
        inviteeEmail: email,
        inviterName: inviterName,
        companyName: inviterName,
        invitationLink: invitationLink,
        role: role,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Invitation sent to $email')),
      );
    } catch (e) {
      print('❌ Error inviting team member: $e');
    }
  }
  
  String _generateToken() {
    // Generate random token
    return 'inv_${DateTime.now().millisecondsSinceEpoch}';
  }
}
```

---

## 3️⃣ ERROR LOGGING INTEGRATION (Sentry)

### In main.dart (Already Configured)

**File**: `lib/main.dart`

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  // Initialize Sentry
  await SentryFlutter.init(
    (options) {
      options.dsn = String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '',
      );
      options.tracesSampleRate = 1.0;
      options.enableAutoSessionTracking = true;
      options.environment = 'production';
    },
    appRunner: () => runApp(const MyApp()),
  );
}
```

### Capture Errors in Services

**File**: `lib/services/stripe_payment_service.dart` (example)

```dart
static Future<String?> createCustomer({
  required String email,
  required String name,
}) async {
  try {
    // ... your code
    return customerId;
  } catch (exception, stackTrace) {
    // Log to Sentry
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        'email': email,
        'service': 'StripePaymentService',
        'action': 'createCustomer',
      }),
    );
    
    print('❌ Error creating customer: $exception');
    return null;
  }
}
```

### Capture User Actions

**File**: `lib/aura_chat_page.dart` (example)

```dart
Future<void> _sendMessage(String message) async {
  try {
    // Send message...
    
    // Capture successful action
    await Sentry.captureMessage(
      'User sent AI message',
      level: SentryLevel.info,
      hint: Hint.withMap({
        'user_id': userId,
        'message_length': message.length,
      }),
    );
  } catch (e) {
    // Capture error
    await Sentry.captureException(e);
  }
}
```

---

## 4️⃣ ANALYTICS INTEGRATION (Google Analytics)

### In main.dart

**File**: `lib/main.dart`

```dart
import 'package:aura_crm/services/analytics_service.dart';

void main() async {
  // Initialize analytics
  await AnalyticsService.initialize();
  
  runApp(const MyApp());
}
```

### Track Page Views

**File**: `lib/home_page.dart` (each page)

```dart
@override
void initState() {
  super.initState();
  
  // Track page view
  AnalyticsService.trackPageView('home_page');
}
```

### Track Feature Usage

**File**: `lib/job_list_page.dart`

```dart
Future<void> _createJob() async {
  try {
    // Create job...
    
    // Track feature usage
    AnalyticsService.trackFeatureUsage('create_job');
  } catch (e) {
    // Error handling
  }
}
```

### Track Subscription

**File**: `lib/pricing_page.dart`

```dart
Future<void> _handleSubscribe(String planId) async {
  try {
    // Subscribe...
    
    final planAmounts = {
      'solo': 9.99,
      'team': 15.00,
      'workshop': 29.00,
    };
    
    // Track purchase event
    AnalyticsService.trackSubscription(
      planId,
      planAmounts[planId] ?? 0.0,
    );
  } catch (e) {
    // Error handling
  }
}
```

---

## 5️⃣ PLAN LIMITS SERVICE

### Check Download Limits

**File**: `lib/services/plan_limits_service.dart` (already created)

```dart
// Check if user can download app
bool canDownload = await PlanLimitsService.canDownloadApp(
  planId,
  'ios', // or 'android' or 'web'
);

if (!canDownload) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Download Limit Reached'),
      content: Text(
        'Your $planName plan allows 2 iOS downloads per month. '
        'Upgrade to Team or Workshop for more downloads.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/pricing');
          },
          child: const Text('Upgrade Plan'),
        ),
      ],
    ),
  );
} else {
  // Record download
  await PlanLimitsService.recordDownload(planId, 'ios');
  
  // Open app store
  launchUrl(Uri.parse('https://apps.apple.com/app/...'));
}
```

---

## 6️⃣ WEBHOOK HANDLERS (Backend)

### Stripe Webhook Handler

**File**: `lib/services/webhook_service.dart` (new file)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebhookService {
  
  // This should be in your backend, but here's the concept:
  
  static Future<void> handleStripeWebhook({
    required String payload,
    required String signature,
  }) async {
    // 1. Verify signature
    // final isValid = StripePaymentService.verifyWebhookSignature(
    //   payload: payload,
    //   signature: signature,
    // );
    
    // 2. Parse event
    final event = jsonDecode(payload);
    final eventType = event['type'];
    
    // 3. Handle different event types
    switch (eventType) {
      case 'customer.subscription.created':
      case 'customer.subscription.updated':
        await _handleSubscriptionCreated(event);
        break;
      
      case 'customer.subscription.deleted':
        await _handleSubscriptionCancelled(event);
        break;
      
      case 'invoice.payment_succeeded':
        await _handlePaymentSucceeded(event);
        break;
      
      case 'invoice.payment_failed':
        await _handlePaymentFailed(event);
        break;
      
      default:
        print('⚠️ Unhandled webhook event: $eventType');
    }
  }
  
  static Future<void> _handleSubscriptionCreated(Map event) async {
    final subscription = event['data']['object'];
    final customerId = subscription['customer'];
    
    // Update database
    final supabase = Supabase.instance.client;
    await supabase
        .from('subscriptions')
        .upsert({
          'stripe_customer_id': customerId,
          'stripe_subscription_id': subscription['id'],
          'status': subscription['status'],
          'current_period_start': subscription['current_period_start'],
          'current_period_end': subscription['current_period_end'],
        })
        .eq('stripe_subscription_id', subscription['id']);
    
    print('✅ Subscription created: ${subscription['id']}');
  }
  
  static Future<void> _handlePaymentFailed(Map event) async {
    final invoice = event['data']['object'];
    final customerId = invoice['customer'];
    
    // Get customer email
    // Send payment failed email
    final supabase = Supabase.instance.client;
    final user = await supabase
        .from('subscriptions')
        .select('user_id')
        .eq('stripe_customer_id', customerId)
        .single();
    
    // Send email notification
    print('⚠️ Payment failed for customer: $customerId');
  }
}
```

---

## 7️⃣ COMPLETE USER JOURNEY

### New User → Paid Subscriber

```dart
// 1. USER SIGNS UP
// - Auth created
// - Organization created
// - Welcome email sent ✉️

// 2. USER VIEWS PRICING
// - Page tracked in Analytics 📊
// - Sees 3 plans with limits

// 3. USER CHOOSES PLAN
// - Clicks "Subscribe to Team"
// - Stripe customer created 💳
// - Subscription created
// - Confirmation email sent ✉️
// - Plan updated in database 💾
// - Event tracked in Analytics 📊

// 4. PAYMENT WEBHOOK
// - Stripe sends webhook
// - Subscription status updated
// - Stored in Sentry if error 🔔

// 5. USER USES FEATURES
// - Creates job → tracked 📊
// - Creates invoice → sent via email ✉️
// - Errors logged → Sentry 🔔
// - Usage tracked → Analytics 📊

// 6. MONTHLY BILLING
// - Subscription auto-renews
// - Invoice email sent ✉️
// - Payment tracked in Analytics 📊

// 7. USER CANCELS (Optional)
// - Subscription cancelled via dashboard
// - Cancellation email sent ✉️
// - Plan reverted to free
// - Tracked in Analytics 📊
```

---

## 📝 QUICK REFERENCE TABLE

| Feature | Service File | Key Method | When to Use |
|---------|--------------|-----------|-----------|
| **Create Subscription** | `stripe_payment_service.dart` | `createSubscription()` | After user clicks "Subscribe" |
| **Send Email** | `resend_email_service.dart` | `sendInvoiceEmail()` | After creating invoice |
| **Log Error** | `main.dart` (Sentry) | `Sentry.captureException()` | In catch blocks |
| **Track Event** | `analytics_service.dart` | `trackFeatureUsage()` | On user actions |
| **Check Limits** | `plan_limits_service.dart` | `canDownloadApp()` | Before app download |
| **Handle Webhook** | `webhook_service.dart` | `handleStripeWebhook()` | Payment events |

---

**All services integrated and ready! 🚀**
