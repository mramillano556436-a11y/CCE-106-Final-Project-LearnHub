import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final session = context.read<Session>();
    final notice = session.notice;
    if (notice != null) {
      session.clearNotice();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            icon: const Icon(Icons.info_outline, color: AppColors.primary, size: 36),
            title: const Text('Unable to sign in'),
            content: Text(notice),
            actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await guard(context, action);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() => AuthService.signIn(_email.text, _password.text));
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) {
      showSnack(context, 'Enter your email address first.');
      return;
    }
    await guard(context, () => AuthService.sendPasswordReset(_email.text),
        success: 'Password reset link sent to ${_email.text.trim()}.');
  }

  void _openRegister(String role) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => RegisterScreen(role: role)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _Hero(),
            Transform.translate(
              offset: const Offset(0, -56),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                          child: _form(),
                        ),
                        const SectionTitle('New to LearnHub?'),
                        Row(children: [
                          Expanded(
                            child: _JoinCard(
                              icon: Icons.person_search,
                              title: 'Register as Client',
                              subtitle: 'Find a tutor',
                              onTap: () => _openRegister(UserRole.client),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _JoinCard(
                              icon: Icons.co_present,
                              title: 'Register as Tutor',
                              subtitle: 'Offer lessons',
                              onTap: () => _openRegister(UserRole.tutor),
                            ),
                          ),
                        ]),
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

  Widget _form() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Welcome back',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            const Text('Sign in to continue', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) => (v ?? '').contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
            ),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Log In'),
            ),
            if (AuthService.googleSupported) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(children: [
                  Expanded(child: Divider(height: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or', style: TextStyle(color: AppColors.muted)),
                  ),
                  Expanded(child: Divider(height: 1)),
                ]),
              ),
              GoogleButton(onPressed: _busy ? null : () => _run(AuthService.signInWithGoogle)),
            ],
          ],
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          child: Stack(children: [
            const Positioned(right: -60, top: -40, child: Orb(size: 220, opacity: 0.08)),
            const Positioned(left: -50, bottom: 10, child: Orb(size: 140, opacity: 0.06)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 92),
                child: Center(
                  child: Column(children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.school_rounded, size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 14),
                    const Text('LearnHub',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('Your tutoring marketplace, all in one place',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      );
}

class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      );
}

/// Outlined "Continue with Google" button with a simple G mark.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.label = 'Continue with Google'});
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.tint, shape: BoxShape.circle),
            child: const Text('G',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Text(label),
        ]),
      );
}
