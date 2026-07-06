import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';

  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  // 0–4 password strength score
  int _passwordStrength = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateEmail(String v) {
    if (v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String v) {
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String v) {
    if (v.isEmpty) return 'Please confirm your password';
    if (v != _passwordController.text) return "Passwords don't match";
    return null;
  }

  int _calcStrength(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  Color get _strengthColor => switch (_passwordStrength) {
        0 || 1 => AppColors.error,
        2 => AppColors.warning,
        3 => const Color(0xFF2E8B57),
        _ => const Color(0xFF27AE60),
      };

  String get _strengthLabel => switch (_passwordStrength) {
        0 || 1 => 'Weak',
        2 => 'Fair',
        3 => 'Good',
        _ => 'Strong',
      };

  Future<void> _signUp() async {
    final emailErr = _validateEmail(_emailController.text);
    final passErr = _validatePassword(_passwordController.text);
    final confErr = _validateConfirm(_confirmController.text);
    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmError = confErr;
    });
    if (emailErr != null || passErr != null || confErr != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = switch (e.code) {
          'email-already-in-use' =>
            'An account with this email already exists.',
          'weak-password' => 'Please choose a stronger password.',
          'invalid-email' => 'The email address is not valid.',
          _ => e.message ?? 'Sign up failed. Please try again.',
        };
      });
    } catch (_) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Create Account', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Get started',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Text('Create a free account to save your resumes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xl),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                ),
                onChanged: (v) {
                  if (_emailError != null) {
                    setState(() => _emailError = _validateEmail(v));
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    _passwordStrength = _calcStrength(v);
                    if (_passwordError != null) {
                      _passwordError = _validatePassword(v);
                    }
                    if (_confirmError != null) {
                      _confirmError = _validateConfirm(_confirmController.text);
                    }
                  });
                },
              ),

              // Password strength bar
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_passwordStrength + 1) / 5,
                          backgroundColor:
                              theme.colorScheme.outline.withAlpha(60),
                          valueColor:
                              AlwaysStoppedAnimation(_strengthColor),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(_strengthLabel,
                        style: TextStyle(
                            color: _strengthColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // Confirm password
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                onChanged: (v) {
                  if (_confirmError != null) {
                    setState(() => _confirmError = _validateConfirm(v));
                  }
                },
              ),

              // Error banner
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(_errorMessage,
                            style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52)),
                      child: const Text('Create Account',
                          style: TextStyle(fontSize: 16)),
                    ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: theme.textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
