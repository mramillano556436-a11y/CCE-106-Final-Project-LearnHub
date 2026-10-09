import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

/// Client and Tutor registration. Tutors continue to Profile Setup afterwards.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});
  final String role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  bool get _isTutor => widget.role == UserRole.tutor;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final session = context.read<Session>();
    final ok = await guard(
      context,
      () => session.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        role: widget.role,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    // The RootGate swaps in the right interface; close this page.
    if (ok) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    await guard(context, AuthService.signInWithGoogle);
    if (!mounted) return;
    setState(() => _busy = false);
    if (AuthService.currentUser != null) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(
        title: _isTutor ? 'Create Tutor Account' : 'Create Client Account',
        subtitle: _isTutor ? 'Step 1 of 2 · Account details' : 'Start finding tutors today',
      ),
      body: PageBody(
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    IconBadge(_isTutor ? Icons.co_present : Icons.person_search, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isTutor
                            ? 'Create your account, then set up your teaching profile.'
                            : 'Create your account to browse and book tutors.',
                        style: const TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => (v ?? '').trim().length < 2 ? 'Enter your full name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Enter a valid email',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) => (v ?? '').length < 6 ? 'At least 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_reset)),
                    validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isTutor ? 'Continue to Profile Setup' : 'Create Account'),
                  ),
                  if (AuthService.googleSupported) ...[
                    const SizedBox(height: 12),
                    GoogleButton(onPressed: _busy ? null : _google, label: 'Sign up with Google'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
