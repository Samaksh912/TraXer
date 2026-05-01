import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app_router.dart';
import '../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Navigation is handled automatically by GoRouter via Riverpod state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll(RegExp(r'\[.*?\]'), ''),
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      // Navigation is handled automatically by GoRouter via Riverpod state
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Sign In Failed',
              style: const TextStyle(fontSize: 16),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 720;

    final cardPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 20.0 : 32.0,
      vertical: isCompact ? 20.0 : 28.0,
    );
    final iconSize = isCompact ? 60.0 : 76.0;
    final titleSize = isCompact ? 26.0 : 32.0;
    final subtitleSize = isCompact ? 15.0 : 18.0;
    final fieldFontSize = isCompact ? 16.0 : 18.0;
    final fieldVerticalPadding = isCompact ? 16.0 : 24.0;
    final fieldSuffixIconSize = isCompact ? 24.0 : 28.0;
    final fieldPrefixIconSize = isCompact ? 24.0 : 28.0;
    final primaryButtonHeight = isCompact ? 54.0 : 64.0;
    final actionButtonTextSize = isCompact ? 18.0 : 22.0;
    final actionIconSize = isCompact ? 32.0 : 40.0;
    final dividerLabelSize = isCompact ? 14.0 : 16.0;
    final spacingAfterHeader = isCompact ? 24.0 : 40.0;
    final fieldSpacing = isCompact ? 18.0 : 24.0;
    final sectionSpacing = isCompact ? 18.0 : 24.0;
    final bottomSpacing = isCompact ? 20.0 : 32.0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen Glassmorphism Background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                          : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
                    ),
                    color: theme.cardColor.withValues(alpha: isDark ? 0.2 : 0.3),
                  ),
                ),
              ),
            ),

            // Abstract floating orbs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.tealAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.lightGreen.withValues(alpha: 0.2),
                ),
              ),
            ),

            // Main Content - Full Height
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 16.0 : 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: iconSize,
                        color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Text(
                        'Welcome Back',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: titleSize,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        'Sign in to track your expenses',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: subtitleSize,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isCompact ? 16 : 24),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: fieldFontSize),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: fieldFontSize),
                          prefixIcon: Icon(Icons.email_outlined, size: fieldPrefixIconSize),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 18,
                          ),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty || !val.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isCompact ? 12 : 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(fontSize: fieldFontSize),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: fieldFontSize),
                          prefixIcon: Icon(Icons.lock_outline, size: fieldPrefixIconSize),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: fieldSuffixIconSize,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 18,
                          ),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: isCompact ? 16 : 24),

                      SizedBox(
                        width: double.infinity,
                        height: primaryButtonHeight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.tealAccent.shade400 : Colors.teal.shade600,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: actionButtonTextSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 12 : 16),

                      Row(
                        children: [
                          Expanded(child: Divider(color: theme.dividerColor)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: dividerLabelSize,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                      SizedBox(height: isCompact ? 12 : 16),

                      SizedBox(
                        width: double.infinity,
                        height: primaryButtonHeight,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          icon: Icon(Icons.g_mobiledata, size: actionIconSize),
                          label: Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: isCompact ? 16.0 : 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 8 : 12),

                      TextButton(
                        onPressed: () {
                          context.pushNamed(AppRoutes.signupName);
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              fontSize: isCompact ? 14.0 : 16.0,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
