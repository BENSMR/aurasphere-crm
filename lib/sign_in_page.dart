import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'theme/modern_theme.dart';
// import 'services/feature_personalization_helper.dart';
// import 'services/rate_limit_service.dart';
// import 'validators/input_validators.dart';

final _logger = Logger();

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _errorMessage;
  
  final supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    if (_loading) return;
    
    // Validate inputs
    if (_email.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Email required');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email required'))
        );
      }
      return;
    }
    
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    
    try {
      final email = _email.text.trim();
      final password = _password.text.trim();
      
      if (password.isEmpty) {
        setState(() => _errorMessage = 'Password required');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password required'))
          );
        }
        return;
      }
      
      // REAL SUPABASE AUTHENTICATION
      print('🔐 Signing in with Supabase: $email');

      try {
        final response = await supabase.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );

        _logger.i('✅ Sign in successful');
        print('✅ User signed in: ${response.user?.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Signed in successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } on AuthException catch (e) {
        _logger.e('❌ Auth exception: ${e.message} (status: ${e.statusCode})');
        print('❌ Auth error details: message=${e.message}, statusCode=${e.statusCode}');
        throw Exception('Sign in failed: ${e.message}');
      } catch (e) {
        _logger.e('❌ Unexpected error: $e');
        print('❌ Full error: $e');
        rethrow;
      }
    } catch (e) {
      _logger.e('❌ Error: $e');
      print('❌ Error details: $e');

      if (mounted) {
        setState(() => _errorMessage = '❌ ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToSignUp() async {
    Navigator.pushReplacementNamed(context, '/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: ModernTheme.lightBackground,
      body: ModernPageTransition(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Navigation
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ModernTheme.spacingL,
                  vertical: ModernTheme.spacingM,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/'),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: ModernTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                            ),
                            child: const Icon(Icons.construction, color: Colors.white),
                          ),
                          const SizedBox(width: ModernTheme.spacingM),
                          const Text(
                            'AuraSphere',
                            style: ModernTheme.headline4,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          color: ModernTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? ModernTheme.spacingM : ModernTheme.spacingXL,
                  vertical: ModernTheme.spacingXL,
                ),
                child: Row(
                  children: [
                    // Left Side - Sign In Form
                    Expanded(
                      child: ModernCard(
                        padding: const EdgeInsets.all(ModernTheme.spacingXL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Welcome Back',
                              style: ModernTheme.headline2,
                            ),
                            const SizedBox(height: ModernTheme.spacingS),
                            const Text(
                              'Sign in to your AuraSphere account',
                              style: ModernTheme.bodySmall,
                            ),
                            const SizedBox(height: ModernTheme.spacingXL),

                            // Email Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: ModernTheme.spacingS),
                                TextField(
                                  controller: _email,
                                  decoration: InputDecoration(
                                    hintText: 'you@example.com',
                                    filled: true,
                                    fillColor: ModernTheme.lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                                      borderSide: const BorderSide(color: ModernTheme.borderGray),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                                      borderSide: const BorderSide(color: ModernTheme.borderGray),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: ModernTheme.spacingM,
                                      vertical: ModernTheme.spacingM,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                            const SizedBox(height: ModernTheme.spacingL),

                            // Password Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: ModernTheme.spacingS),
                                TextField(
                                  controller: _password,
                                  obscureText: !_showPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password',
                                    filled: true,
                                    fillColor: ModernTheme.lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                                      borderSide: const BorderSide(color: ModernTheme.borderGray),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                                      borderSide: const BorderSide(color: ModernTheme.borderGray),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () => setState(() => _showPassword = !_showPassword),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: ModernTheme.spacingM,
                                      vertical: ModernTheme.spacingM,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: ModernTheme.spacingM),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: ModernTheme.primaryBlue,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: ModernTheme.spacingL),

                            // Error Message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(ModernTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: ModernTheme.dangerRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                                  border: Border.all(color: ModernTheme.dangerRed),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: ModernTheme.dangerRed,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            if (_errorMessage != null) const SizedBox(height: ModernTheme.spacingL),

                            // Sign In Button
                            ModernButton(
                              label: _loading ? 'Signing in...' : 'Sign In',
                              onPressed: _signIn,
                              fullWidth: true,
                              loading: _loading,
                            ),
                            const SizedBox(height: ModernTheme.spacingM),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _loading ? null : _goToSignUp,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: ModernTheme.primaryBlue,
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ModernTheme.spacingL,
                                    vertical: ModernTheme.spacingM,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: ModernTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: ModernTheme.spacingXL),
                      // Right Side - Benefits
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why AuraSphere?',
                              style: ModernTheme.headline3,
                            ),
                            const SizedBox(height: ModernTheme.spacingL),
                            _buildBenefit(
                              'Sovereign Data',
                              'EU-hosted, zero tracking, GDPR compliant',
                              Icons.security_outlined,
                            ),
                            const SizedBox(height: ModernTheme.spacingL),
                            _buildBenefit(
                              'Multi-Language',
                              'Support for 9 languages including Arabic',
                              Icons.language_outlined,
                            ),
                            const SizedBox(height: ModernTheme.spacingL),
                            _buildBenefit(
                              'AI-Powered',
                              'Voice commands, auto-invoicing, smart dispatch',
                              Icons.auto_awesome_outlined,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String title, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(ModernTheme.spacingM),
          decoration: BoxDecoration(
            gradient: ModernTheme.accentGradient,
            borderRadius: BorderRadius.circular(ModernTheme.radiusMedium),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: ModernTheme.spacingL),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ModernTheme.headline4),
              const SizedBox(height: ModernTheme.spacingS),
              Text(desc, style: ModernTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
