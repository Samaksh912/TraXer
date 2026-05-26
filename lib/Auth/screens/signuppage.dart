import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:traxer/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
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

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(
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
            backgroundColor: context.appColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignup() async {
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
            backgroundColor: context.appColors.expense,
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
                      colors: [
                        context.appColors.background,
                        context.appColors.surface,
                        context.appColors.background,
                      ],
                    ),
                    color: theme.cardColor.withValues(alpha: isDark ? 0.2 : 0.3),
                  ),
                ),
              ),
            ),

            // Abstract floating orbs
            Positioned(
              top: -50,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appColors.income.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appColors.accent.withValues(alpha: 0.1),
                ),
              ),
            ),

            // Main Content - Full Height
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 16.0 : 24.0),
              child: Center(
                child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: isCompact ? 60.0 : 80.0,
                        color: context.appColors.accent,
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      Text(
                        "Create Account",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 26.0 : 32.0,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 6),
                      Text(
                        "Start your journey to better finances",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: isCompact ? 15.0 : 18.0,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isCompact ? 16 : 24),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: isCompact ? 16.0 : 18.0),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(fontSize: isCompact ? 16.0 : 18.0),
                          prefixIcon: Icon(Icons.email_outlined, size: isCompact ? 24.0 : 28.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: isCompact ? 16.0 : 24.0, horizontal: 18),
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
                        style: TextStyle(fontSize: isCompact ? 16.0 : 18.0),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(fontSize: isCompact ? 16.0 : 18.0),
                          prefixIcon: Icon(Icons.lock_outline, size: isCompact ? 24.0 : 28.0),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: isCompact ? 24.0 : 28.0,
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
                          contentPadding: EdgeInsets.symmetric(vertical: isCompact ? 16.0 : 24.0, horizontal: 18),
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
                        height: isCompact ? 54.0 : 64.0,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.accent,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: isCompact ? 18.0 : 22.0,
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
                            child: Text("OR", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: isCompact ? 14.0 : 16.0)),
                          ),
                          Expanded(child: Divider(color: theme.dividerColor)),
                        ],
                      ),
                      SizedBox(height: isCompact ? 12 : 16),

                      SizedBox(
                        width: double.infinity,
                        height: isCompact ? 54.0 : 64.0,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignup,
                          icon: Icon(Icons.g_mobiledata, size: isCompact ? 32.0 : 40.0),
                          label: Text(
                            "Sign up with Google",
                            style: TextStyle(fontSize: isCompact ? 16.0 : 20.0, fontWeight: FontWeight.bold),
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
                          context.pop();
                        },
                        child: Text.rich(
                          TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(fontSize: isCompact ? 14.0 : 16.0, color: isDark ? Colors.white70 : Colors.black87),
                            children: [
                              TextSpan(
                                text: "Log In",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.appColors.accent,
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
            ),
          ],
        ),
      ),
    );
  }
}
