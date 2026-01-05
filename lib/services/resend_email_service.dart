import 'package:http/http.dart' as http;
import 'dart:convert';

/// ResendEmailService - Email delivery via Resend
/// 
/// Handles:
/// - Welcome emails
/// - Invoice emails
/// - Subscription confirmations
/// - Password reset emails
/// - Team invitations

class ResendEmailService {
  static const String apiBaseUrl = 'https://api.resend.com/emails';
  static const String apiKey = String.fromEnvironment('RESEND_API_KEY');
  static const String fromEmail = String.fromEnvironment('RESEND_FROM_EMAIL', defaultValue: 'noreply@aurasphere.app');
  static const String fromName = 'AuraSphere CRM';

  // WELCOME EMAIL
  static Future<bool> sendWelcomeEmail({
    required String userEmail,
    required String userName,
    required String planName,
    required int maxUsers,
    required int aiCalls,
  }) async {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #007BFF 0%, #0056b3 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
        .feature { margin: 15px 0; padding: 10px; background: white; border-left: 4px solid #007BFF; }
        .button { background: #007BFF; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; }
        .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Welcome to AuraSphere CRM! 🎉</h1>
        </div>
        
        <div class="content">
          <p>Hi $userName,</p>
          
          <p>Your <strong>$planName</strong> plan is now active! Here's what you get:</p>
          
          <div class="feature">
            <strong>👥 Team Members:</strong> Up to $maxUsers users
          </div>
          
          <div class="feature">
            <strong>🤖 AI Calls:</strong> $aiCalls calls per month
          </div>
          
          <div class="feature">
            <strong>📊 All Features:</strong> Full access to jobs, invoices, clients, analytics
          </div>
          
          <p><strong>Get Started:</strong></p>
          <ul>
            <li>Add your first client</li>
            <li>Create a job</li>
            <li>Send your first invoice</li>
            <li>Invite team members</li>
          </ul>
          
          <a href="https://app.aurasphere.app/dashboard" class="button">Go to Dashboard</a>
          
          <p>Questions? Email us at support@aurasphere.app</p>
        </div>
        
        <div class="footer">
          <p>© 2026 AuraSphere CRM. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    ''';

    return _sendEmail(
      to: userEmail,
      subject: 'Welcome to AuraSphere CRM - Your $planName Plan is Active',
      html: htmlContent,
    );
  }

  // INVOICE EMAIL
  static Future<bool> sendInvoiceEmail({
    required String clientEmail,
    required String clientName,
    required String invoiceNumber,
    required double amount,
    required String dueDate,
    required String technicianName,
    required String companyName,
  }) async {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #f9f9f9; padding: 20px; border-bottom: 3px solid #007BFF; }
        .invoice-details { margin: 30px 0; }
        .detail-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #eee; }
        .amount { font-size: 24px; font-weight: bold; color: #007BFF; }
        .button { background: #007BFF; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h2>Invoice #$invoiceNumber</h2>
          <p>From: <strong>$companyName</strong></p>
          <p>Technician: $technicianName</p>
        </div>
        
        <div class="invoice-details">
          <p>Hi $clientName,</p>
          
          <p>Thank you for your business! Here's your invoice:</p>
          
          <div class="detail-row">
            <span>Invoice Number:</span>
            <strong>#$invoiceNumber</strong>
          </div>
          
          <div class="detail-row">
            <span>Amount Due:</span>
            <span class="amount">\$${amount.toStringAsFixed(2)}</span>
          </div>
          
          <div class="detail-row">
            <span>Due Date:</span>
            <strong>$dueDate</strong>
          </div>
          
          <p>To view full invoice details and download a PDF, click below:</p>
          <a href="https://app.aurasphere.app/invoices/$invoiceNumber" class="button">View Invoice</a>
        </div>
        
        <p style="color: #666; font-size: 12px;">
          If you have any questions, please contact $technicianName.
        </p>
      </div>
    </body>
    </html>
    ''';

    return _sendEmail(
      to: clientEmail,
      subject: 'Invoice #$invoiceNumber - \$${amount.toStringAsFixed(2)} Due',
      html: htmlContent,
    );
  }

  // SUBSCRIPTION CONFIRMATION
  static Future<bool> sendSubscriptionConfirmation({
    required String userEmail,
    required String userName,
    required String planName,
    required double monthlyAmount,
  }) async {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .success-box { background: #d4edda; border: 1px solid #c3e6cb; color: #155724; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .amount { font-size: 28px; font-weight: bold; color: #007BFF; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Subscription Confirmed ✅</h2>
        
        <div class="success-box">
          <p><strong>Your subscription is now active!</strong></p>
        </div>
        
        <p>Hi $userName,</p>
        
        <p>Thank you for upgrading to <strong>$planName</strong>!</p>
        
        <p style="font-size: 16px;">
          <strong>Plan:</strong> $planName<br>
          <strong>Amount:</strong> <span class="amount">\$${monthlyAmount.toStringAsFixed(2)}/month</span><br>
          <strong>Renewal:</strong> Same date each month
        </p>
        
        <p>You can manage your subscription anytime in your <a href="https://app.aurasphere.app/settings">account settings</a>.</p>
        
        <p>Enjoy using AuraSphere CRM!</p>
      </div>
    </body>
    </html>
    ''';

    return _sendEmail(
      to: userEmail,
      subject: 'Your $planName Subscription is Now Active',
      html: htmlContent,
    );
  }

  // PASSWORD RESET EMAIL
  static Future<bool> sendPasswordResetEmail({
    required String userEmail,
    required String resetLink,
  }) async {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .button { background: #007BFF; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; }
        .warning { background: #fff3cd; border: 1px solid #ffc107; color: #856404; padding: 15px; border-radius: 5px; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Password Reset Request</h2>
        
        <p>We received a request to reset your password. Click the link below:</p>
        
        <a href="$resetLink" class="button">Reset Password</a>
        
        <p>Or copy this link: <br><code>$resetLink</code></p>
        
        <div class="warning">
          <strong>⚠️ Security Note:</strong> This link expires in 24 hours.
        </div>
        
        <p>If you didn't request this, ignore this email.</p>
      </div>
    </body>
    </html>
    ''';

    return _sendEmail(
      to: userEmail,
      subject: 'Reset Your AuraSphere Password',
      html: htmlContent,
    );
  }

  // TEAM INVITATION EMAIL
  static Future<bool> sendTeamInvitation({
    required String inviteeEmail,
    required String inviterName,
    required String companyName,
    required String invitationLink,
    required String role,
  }) async {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .button { background: #007BFF; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>You're Invited to Join $companyName! 👋</h2>
        
        <p><strong>$inviterName</strong> invited you to join their team in AuraSphere CRM.</p>
        
        <p><strong>Role:</strong> $role</p>
        
        <p>Accept the invitation to get started:</p>
        
        <a href="$invitationLink" class="button">Join Team</a>
        
        <p>Or copy this link: <br><code>$invitationLink</code></p>
        
        <p>You'll be able to manage jobs, view schedules, and collaborate with the team.</p>
      </div>
    </body>
    </html>
    ''';

    return _sendEmail(
      to: inviteeEmail,
      subject: '$inviterName invited you to $companyName on AuraSphere',
      html: htmlContent,
    );
  }

  // PAYMENT FAILED EMAIL
  static Future<bool> sendPaymentFailedEmail({
    required String userEmail,
    required String userName,
    required String planName,
    required String failureReason,
  }) async {
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .error-box { background: #f8d7da; border: 1px solid #f5c6cb; color: #721c24; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .button { background: #007BFF; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>Payment Failed ⚠️</h2>
        
        <div class="error-box">
          <p><strong>Your recent payment for $planName failed.</strong></p>
        </div>
        
        <p>Hi $userName,</p>
        
        <p><strong>Reason:</strong> $failureReason</p>
        
        <p>Please update your payment method to keep your $planName plan active:</p>
        
        <a href="https://app.aurasphere.app/billing" class="button">Update Payment Method</a>
        
        <p>If you have questions, contact our support team.</p>
      </div>
    </body>
    </html>
    ''';

    return _sendEmail(
      to: userEmail,
      subject: 'Payment Failed - Action Required for Your $planName Plan',
      html: htmlContent,
    );
  }

  // INTERNAL: Send email via Resend API
  static Future<bool> _sendEmail({
    required String to,
    required String subject,
    required String html,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    try {
      if (apiKey.isEmpty) {
        print('⚠️ RESEND_API_KEY not configured');
        return false;
      }

      final body = {
        'from': '$fromName <$fromEmail>',
        'to': [to],
        'subject': subject,
        'html': html,
      };

      if (cc != null && cc.isNotEmpty) {
        body['cc'] = cc;
      }

      if (bcc != null && bcc.isNotEmpty) {
        body['bcc'] = bcc;
      }

      final response = await http.post(
        Uri.parse(apiBaseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 500),
      );

      if (response.statusCode == 200) {
        print('✅ Email sent to $to');
        return true;
      } else {
        print('❌ Email failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Email error: $e');
      return false;
    }
  }
}
