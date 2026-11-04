import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_assets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../utils/ugandan_phone_number.dart';
import '../../widgets/app_logo_badge.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  bool _isGoogleBusy = false;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isBusy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      await ref.read(authServiceProvider).signInWithEmailPassword(
            identifier: _emailController.text.trim(),
            password: _passwordController.text,
            usePhone: _usePhone,
          );
      if (mounted) {
        ref.read(showHomeHeroSectionProvider.notifier).state = true;
        context.go('/home');
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _isGoogleBusy = true;
    });
    try {
      final response = await ref.read(authServiceProvider).signInWithGoogle();
      if (response != null && mounted) {
        ref.read(showHomeHeroSectionProvider.notifier).state = true;
        context.go('/home');
      }
    } catch (error) {
      _showGoogleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isGoogleBusy = false;
        });
      }
    }
  }

  void _showGoogleError(Object error) {
    if (!mounted) return;
    final message = error is GoogleSignInConfigurationException
        ? error.message
        : 'Google sign-in failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _resetPassword() async {
    final identifier = _emailController.text.trim();
    if (_usePhone || !identifier.contains('@')) {
      _showError('Enter your email address to reset your password.');
      return;
    }
    try {
      await ref.read(authServiceProvider).resetPasswordForEmail(identifier);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign in failed: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogoBadge(size: 104)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sign in to Buy From Lango',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Email')),
                        ButtonSegment(value: true, label: Text('Phone number')),
                      ],
                      selected: {_usePhone},
                      onSelectionChanged: _isBusy
                          ? null
                          : (selection) =>
                              setState(() => _usePhone = selection.first),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: _usePhone
                          ? TextInputType.phone
                          : TextInputType.emailAddress,
                      autofillHints: _usePhone
                          ? const [AutofillHints.telephoneNumber]
                          : const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: _usePhone ? 'Phone number' : 'Email',
                        hintText: _usePhone ? '+256 7XX XXX XXX' : null,
                        prefixIcon: Icon(
                          _usePhone
                              ? Icons.phone_outlined
                              : Icons.email_outlined,
                        ),
                      ),
                      validator: (value) {
                        final identifier = value?.trim() ?? '';
                        if (identifier.isEmpty) {
                          return _usePhone
                              ? 'Enter your phone number.'
                              : 'Enter your email address.';
                        }
                        if (_usePhone &&
                            normalizeUgandanPhoneNumber(identifier) == null) {
                          return 'Enter a valid Ugandan number, such as +256700000000.';
                        }
                        if (!_usePhone &&
                            (!identifier.contains('@') ||
                                !identifier.contains('.'))) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => (value?.isEmpty ?? true)
                          ? 'Enter your password.'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _usePhone
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: _isBusy ? null : _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isBusy ? null : _signIn,
                      child: _isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _signInWithGoogle,
                      icon: _isGoogleBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : SvgPicture.asset(
                              AppAssets.iconGoogleLogo,
                              width: 22,
                              height: 22,
                            ),
                      label: Text(
                        _isGoogleBusy
                            ? 'Signing in with Google...'
                            : 'Continue with Google',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () => context.push('/sign-up'),
                      child: const Text("Don't have an account? Sign up"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
