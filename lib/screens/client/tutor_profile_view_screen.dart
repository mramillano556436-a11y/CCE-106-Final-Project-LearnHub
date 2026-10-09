import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/report.dart';
import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import 'place_order_screen.dart';

class TutorProfileViewScreen extends StatelessWidget {
  const TutorProfileViewScreen({super.key, required this.tutorId});
  final String tutorId;

  Future<void> _report(BuildContext context, TutorProfile tutor) async {
    final me = context.read<Session>().currentUser;
    final reason = await promptText(context, 'Report ${tutor.name}', 'Why are you reporting this profile?');
    if (reason == null || !context.mounted) return;
    await guard(
      context,
      () => Db.instance.reportContent(
        reporter: me,
        type: ReportType.profile,
        targetUserId: tutor.tutorId,
        targetLabel: tutor.name,
        reason: reason,
      ),
      success: 'Report sent to the LearnHub admin.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClient = context.watch<Session>().currentUser.isClient;
    return StreamBuilder<TutorProfile?>(
      stream: Db.instance.streamTutorProfile(tutorId),
      builder: (context, snap) {
        final tutor = snap.data;
        return Scaffold(
          appBar: brandAppBar(
            title: 'Tutor Profile',
            actions: [
              if (tutor != null && isClient)
                PopupMenuButton<String>(
                  onSelected: (_) => _report(context, tutor),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(children: [
                        Icon(Icons.flag_outlined, size: 20, color: AppColors.danger),
                        SizedBox(width: 10),
                        Text('Report profile'),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          bottomNavigationBar: tutor != null && isClient
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute<void>(builder: (_) => PlaceOrderScreen(tutor: tutor))),
                      icon: const Icon(Icons.event_available),
                      label: Text('Place Order · ${formatPeso(tutor.rateCents)}'),
                    ),
                  ),
                )
              : null,
          body: tutor == null
              ? (snap.hasError || snap.connectionState == ConnectionState.active
                  ? const EmptyState(icon: Icons.person_off, message: 'This tutor is no longer available.')
                  : const Center(child: CircularProgressIndicator()))
              : _body(tutor),
        );
      },
    );
  }

  Widget _body(TutorProfile tutor) {
    Widget stat(String value, String label) => Expanded(
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        );
    Widget divider() => Container(width: 1, height: 32, color: AppColors.border);

    return PageBody(
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(children: [
            UserAvatar(name: tutor.name, photoUrl: tutor.photoUrl, radius: 46, ring: true),
            const SizedBox(height: 12),
            Text(tutor.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('${tutor.subjects.isEmpty ? '' : tutor.subjects.first} Tutor',
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                stat(formatPeso(tutor.rateCents), 'per session'),
                divider(),
                stat(tutor.ratingCount == 0 ? 'New' : tutor.rating.toStringAsFixed(1), 'rating'),
                divider(),
                stat('${tutor.ratingCount}', 'review${tutor.ratingCount == 1 ? '' : 's'}'),
              ]),
            ),
          ]),
        ),
        const SectionTitle('Details'),
        AppCard(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Column(children: [
            InfoRow(
              icon: Icons.menu_book,
              label: 'Subjects',
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final s in tutor.subjects) Pill(s)],
                ),
              ),
            ),
            InfoRow(icon: Icons.schedule, label: 'Availability', value: tutor.availabilityLabel),
          ]),
        ),
        const SectionTitle('About'),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Text(tutor.about.isEmpty ? 'No description yet.' : tutor.about,
              style: const TextStyle(height: 1.5, color: AppColors.ink)),
        ),
      ],
    );
  }
}
