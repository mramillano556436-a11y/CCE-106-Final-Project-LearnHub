import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Shown once after a first-time Google sign-in to pick Client or Tutor.
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  bool _busy = false;

  Future<void> _choose(String role) async {
    setState(() => _busy = true);
    await guard(context, () => context.read<Session>().completeRegistration(role));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final name = session.firebaseUser?.displayName ?? '';
    return Scaffold(
      appBar: brandAppBar(
        title: 'Welcome${name.isEmpty ? '' : ', ${name.split(' ').first}'}!',
        subtitle: 'One last step before you start',
        actions: [
          TextButton(
            onPressed: session.signOut,
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: PageBody(
        children: [
          const SectionTitle('How will you use LearnHub?'),
          _RoleCard(
            icon: Icons.person_search,
            title: "I'm a Client",
            subtitle: 'Find, compare, and book tutors for any subject.',
            onTap: _busy ? null : () => _choose(UserRole.client),
          ),
          _RoleCard(
            icon: Icons.co_present,
            title: "I'm a Tutor",
            subtitle: 'Advertise your lessons, set your rate, and get booked.',
            onTap: _busy ? null : () => _choose(UserRole.tutor),
          ),
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          IconBadge(icon, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.muted, height: 1.35)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
        ]),
      );
}
