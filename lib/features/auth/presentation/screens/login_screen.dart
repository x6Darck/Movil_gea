import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/gea_text_field.dart';
import 'package:gea_app/core/presentation/widgets/gea_button.dart';
import 'package:gea_app/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
      
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        if (mounted) context.go('/');
      } else if (authState.errorMessage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authState.errorMessage!), 
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          color: AppTokens.background,
        ),
        child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            padding: EdgeInsets.all(isDesktop ? 40 : 24),
            decoration: isDesktop ? BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ) : null,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/gea-logo.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.welcomeTitle,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  GeaTextField(
                    label: l10n.emailLabel,
                    hint: l10n.emailHint,
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l10n.fieldRequired;
                      if (!value.contains('@')) return l10n.emailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  GeaTextField(
                    label: l10n.passwordLabel,
                    hint: '••••••••',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return l10n.fieldRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.secondary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      child: Text(l10n.forgotPassword),
                    ),
                  ),
                   const SizedBox(height: 24),
                  GeaButton(
                    text: l10n.loginButton,
                    onPressed: _onLogin,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: 16),
                  _buildMicrosoftButton(theme, l10n),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('O', style: TextStyle(color: AppTokens.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GeaButton(
                    text: l10n.guestButton,
                    variant: GeaButtonVariant.secondary,
                    onPressed: () {
                      ref.read(authProvider.notifier).continueAsGuest();
                      context.go('/');
                    },
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

  Widget _buildMicrosoftButton(ThemeData theme, AppLocalizations l10n) {
    final authState = ref.watch(authProvider);
    return OutlinedButton(
      onPressed: authState.isLoading
          ? null
          : () async {
              await ref.read(authProvider.notifier).loginWithMicrosoft();
              final updatedState = ref.read(authProvider);
              if (updatedState.user != null) {
                if (mounted) context.go('/');
              } else if (updatedState.errorMessage != null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(updatedState.errorMessage!),
                      backgroundColor: theme.colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            },
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5E5E5E),
        side: const BorderSide(color: Color(0xFF8C8C8C)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMicrosoftLogo(),
          const SizedBox(width: 12),
          Text(
            l10n.microsoftLogin,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Segoe UI',
              color: Color(0xFF5E5E5E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrosoftLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, color: const Color(0xFFF25022)),
            const SizedBox(width: 2),
            Container(width: 7, height: 7, color: const Color(0xFF7FBA00)),
          ],
        ),
        const SizedBox(width: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 7, height: 7, color: const Color(0xFF00A4EF)),
            const SizedBox(width: 2),
            Container(width: 7, height: 7, color: const Color(0xFFFFB900)),
          ],
        ),
      ],
    );
  }
}

