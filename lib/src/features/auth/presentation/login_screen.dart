import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/session_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionControllerProvider, (_, next) {
      next.whenOrNull(
        data: (data) {
          if (data.isAuthorized) {
            context.go('/dashboard');
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    final sessionState = ref.watch(sessionControllerProvider);
    final unauthorizedMessage =
        sessionState.valueOrNull?.unauthorizedMessage ?? '';
    final isLoading = sessionState.isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [
                    Colors.white,
                    colorScheme.surface,
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                  ]
                : [
                    colorScheme.surface,
                    colorScheme.primaryContainer.withValues(alpha: 0.08),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _LoginCard(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLoading: isLoading,
                  obscurePassword: _obscurePassword,
                  unauthorizedMessage: unauthorizedMessage,
                  onTogglePassword: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  onSubmit: _submit,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref.read(sessionControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.unauthorizedMessage,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final String unauthorizedMessage;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secure admin sign-in',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Use an authorized admin account to review pending creators and businesses.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              if (unauthorizedMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: _InlineMessage(
                    icon: Icons.gpp_maybe_rounded,
                    message: unauthorizedMessage,
                    tone: _MessageTone.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'name@company.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                autofillHints: const [AutofillHints.username],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    tooltip: obscurePassword ? 'Show password' : 'Hide password',
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                autofillHints: const [AutofillHints.password],
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!isLoading) {
                    onSubmit();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Access is restricted to approved administrators. Non-admin accounts are blocked automatically.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onSubmit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(isLoading ? 'Signing in...' : 'Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MessageTone { error }

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    required this.tone,
  });

  final IconData icon;
  final String message;
  final _MessageTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (tone) {
      _MessageTone.error => colorScheme.errorContainer,
    };
    final foregroundColor = switch (tone) {
      _MessageTone.error => colorScheme.onErrorContainer,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
