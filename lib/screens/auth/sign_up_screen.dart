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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBusy = false;
  bool _isGoogleBusy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isBusy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      final response =
          await ref.read(authServiceProvider).signUpWithEmailPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                phone: _phoneController.text.trim(),
                fullName: _nameController.text.trim(),
              );

      if (!mounted) return;

      if (response.session != null) {
        ref.read(showHomeHeroSectionProvider.notifier).state = true;
        context.go('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account.'),
          ),
        );
        context.go('/sign-in');
      }
    } catch (error) {
      if (mounted) {
        final message = switch (error) {
          EmailAlreadyRegisteredException() =>
            EmailAlreadyRegisteredException.message,
          PhoneAlreadyRegisteredException() =>
            PhoneAlreadyRegisteredException.message,
          FormatException() => error.message,
          _ => 'Could not create your account. Please check your connection '
              'and try again.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_isBusy) return;
    if (normalizeUgandanPhoneNumber(_phoneController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter a valid Ugandan phone number before continuing.'),
        ),
      );
      return;
    }
    setState(() {
      _isBusy = true;
      _isGoogleBusy = true;
    });
    try {
      final response = await ref.read(authServiceProvider).signInWithGoogle();
      if (response != null && mounted) {
        await ref.read(authServiceProvider).savePhoneForCurrentUser(
              phone: _phoneController.text.trim(),
              fullName: _nameController.text.trim(),
            );
        if (!mounted) return;
        ref.read(showHomeHeroSectionProvider.notifier).state = true;
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        final message = switch (error) {
          GoogleSignInConfigurationException() => error.message,
          PhoneAlreadyRegisteredException() =>
            PhoneAlreadyRegisteredException.message,
          FormatException() => error.message,
          PhoneLoginException() => error.message,
          _ => 'Google sign-in failed. Please try again.',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _isGoogleBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                    const Center(child: AppLogoBadge(size: 96)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Join Buy From Lango',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+256 7XX XXX XXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        if (normalizeUgandanPhoneNumber(value ?? '') == null) {
                          return 'Enter a valid Ugandan phone number, such as +256700000000.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty || !email.contains('@')) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Use at least 8 characters.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _isBusy ? null : _signUp,
                      child: _isBusy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : _signUpWithGoogle,
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
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Already registered? Sign in'),
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
