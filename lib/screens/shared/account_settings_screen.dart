import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Account-level settings (email, password, log out), separate from the
/// public teaching profile.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _email.text = context.read<Session>().currentUser.email;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = context.read<Session>();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() => _busy = true);
    await guard(context, () async {
      var changed = false;
      if (email.isNotEmpty && email.toLowerCase() != session.currentUser.email) {
        await AuthService.changeEmail(email);
        changed = true;
        if (mounted) showSnack(context, 'Check $email for a link to confirm the change.');
      }
      if (password.isNotEmpty) {
        if (password.length < 6) throw StateError('Password must be at least 6 characters.');
        await AuthService.changePassword(password);
        _password.clear();
        changed = true;
        if (mounted) showSnack(context, 'Password updated.');
      }
      if (!changed && mounted) showSnack(context, 'Nothing to update.');
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final passwordLogin = AuthService.hasPasswordLogin;
    return Scaffold(
      appBar: brandAppBar(title: 'Account Settings', subtitle: 'Login details and security'),
      body: PageBody(
        children: [
          if (!passwordLogin)
            const AppCard(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                IconBadge(Icons.verified_user_outlined, size: 46),
                SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('You sign in with Google',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Your email and password are managed by your Google account.',
                        style: TextStyle(color: AppColors.muted, height: 1.35)),
                  ]),
                ),
              ]),
            )
          else ...[
            const SectionTitle('Login details'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'New Password', hintText: 'Leave blank to keep', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _busy ? null : _save, child: const Text('Save Changes')),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          const LogOutButton(),
        ],
      ),
    );
  }
}

/// Red-outlined log out button used on every profile page.
class LogOutButton extends StatelessWidget {
  const LogOutButton({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: () => context.read<Session>().signOut(),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.35), width: 1.2),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Log Out'),
      );
}
