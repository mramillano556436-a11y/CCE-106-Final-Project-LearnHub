import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import '../client/tutor_profile_view_screen.dart';

/// Clients, Tutors, and Pending tutor approvals. The admin can approve or
/// reject tutors and suspend, reactivate, or remove any account.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 2,
      child: Scaffold(
        appBar: brandAppBar(title: 'Accounts', bottom: brandTabBar(const ['Clients', 'Tutors', 'Pending'])),
        body: StreamView<List<AppUser>>(
          stream: Db.instance.streamAllUsers(),
          builder: (context, users) => StreamView<List<TutorProfile>>(
            stream: Db.instance.streamAllTutorProfiles(),
            builder: (context, tutors) {
              final pending = tutors.where((t) => t.profileComplete && !t.approved && !t.rejected).toList();
              final profilesById = {for (final t in tutors) t.tutorId: t};
              return TabBarView(
                children: [
                  _UserList(users: users.where((u) => u.isClient).toList(), profiles: profilesById),
                  _UserList(users: users.where((u) => u.isTutor).toList(), profiles: profilesById),
                  _PendingList(pending: pending),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({required this.users, required this.profiles});
  final List<AppUser> users;
  final Map<String, TutorProfile> profiles;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const EmptyState(icon: Icons.group_off, message: 'No accounts yet.');
    return PageBody(
      children: [
        for (final u in users)
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => _manage(context, u),
            child: Row(children: [
              UserAvatar(name: u.name, photoUrl: u.photoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(u.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  Text('Joined ${formatDate(u.createdAt)}', style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              StatusChip(_label(u)),
            ]),
          ),
      ],
    );
  }

  String _label(AppUser u) {
    if (!u.isActive) return u.status;
    if (!u.isTutor) return 'active';
    final p = profiles[u.uid];
    if (p == null || !p.profileComplete) return 'incomplete';
    if (p.rejected) return 'rejected';
    return p.approved ? 'approved' : 'pending approval';
  }

  void _manage(BuildContext context, AppUser u) {
    Widget action(IconData icon, Color color, String title, String? subtitle, VoidCallback onTap) => ListTile(
          leading: IconBadge(icon, color: color, size: 38),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          onTap: onTap,
        );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: UserAvatar(name: u.name, photoUrl: u.photoUrl, radius: 24),
                title: Text(u.name),
                subtitle: Text('${u.role} · ${u.email}${u.phone.isEmpty ? '' : ' · ${u.phone}'}'),
              ),
              const Divider(),
              if (u.isTutor && profiles[u.uid]?.profileComplete == true)
                action(Icons.visibility_outlined, AppColors.primary, 'View tutor profile', null, () {
                  Navigator.pop(sheet);
                  Navigator.push(
                      context, MaterialPageRoute<void>(builder: (_) => TutorProfileViewScreen(tutorId: u.uid)));
                }),
              if (u.isActive)
                action(Icons.pause_circle_outline, AppColors.warning, 'Suspend account',
                    'Blocks login. Tutors are hidden from the directory.', () async {
                  Navigator.pop(sheet);
                  if (await confirmDialog(context, 'Suspend ${u.name}?', 'They will not be able to log in.',
                          confirm: 'Suspend') &&
                      context.mounted) {
                    await guard(context, () => Db.instance.suspendAccount(u), success: 'Account suspended.');
                  }
                })
              else
                action(Icons.play_circle_outline, AppColors.success, 'Reactivate account',
                    u.isTutor ? 'The tutor will need to be approved again.' : null, () async {
                  Navigator.pop(sheet);
                  await guard(context, () => Db.instance.reactivateAccount(u.uid), success: 'Account reactivated.');
                }),
              if (u.status != AccountStatus.deleted)
                action(Icons.delete_outline, AppColors.danger, 'Remove account',
                    'Permanently blocks the account. Order history is kept.', () async {
                  Navigator.pop(sheet);
                  if (await confirmDialog(context, 'Remove ${u.name}?',
                          'The account will be blocked and hidden. Records of past orders are kept for disputes.',
                          confirm: 'Remove') &&
                      context.mounted) {
                    await guard(context, () => Db.instance.suspendAccount(u, delete: true), success: 'Account removed.');
                  }
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.pending});
  final List<TutorProfile> pending;

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return const EmptyState(icon: Icons.verified_outlined, message: 'No tutor profiles are waiting for approval.');
    }
    return PageBody(
      children: [
        for (final t in pending)
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  UserAvatar(name: t.name, photoUrl: t.photoUrl, radius: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.ink)),
                      Text(t.subjectsLabel, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                    ]),
                  ),
                  Pill(formatPeso(t.rateCents)),
                ]),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.schedule, size: 15, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(t.availabilityLabel, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(t.about,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => guard(context, () => Db.instance.rejectTutor(t.tutorId),
                          success: '${t.name} was not approved.'),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => guard(context, () => Db.instance.approveTutor(t.tutorId),
                          success: '${t.name} is now listed in the directory.'),
                      child: const Text('Approve'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
      ],
    );
  }
}
