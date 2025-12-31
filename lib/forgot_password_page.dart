import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() => _message = 'Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'http://localhost:8000/reset-password',
      );

      setState(() {
        _isSuccess = true;
        _message =
            'Password reset link sent! Check your email (check spam folder too)';
      });
    } on AuthException catch (e) {
      setState(() => _message = 'Error: ${e.message}');
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'An unexpected error occurred');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.lock_reset_outlined,
              size: 80,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 32),
            const Text(
              'Forgot Your Password?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Email Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'you@example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            // Message
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: _isSuccess
                        ? Colors.green[300]!
                        : Colors.red[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: _isSuccess ? Colors.green[700] : Colors.red[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_message != null) const SizedBox(height: 24),
            // Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Back to Sign In
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Sign In'),
            ),
            const SizedBox(height: 40),
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Tips:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Check your spam/junk folder\n'
                    '• The link expires in 1 hour\n'
                    '• Create a strong password\n'
                    '• The reset works immediately',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
