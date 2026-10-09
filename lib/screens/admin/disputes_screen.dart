import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/report.dart';
import '../../services/db.dart';
import '../../services/report_printer.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../client/tutor_profile_view_screen.dart';
import '../shared/order_chat_screen.dart';

IconData _iconFor(String type) => switch (type) {
      ReportType.message => Icons.chat_bubble_outline,
      ReportType.profile => Icons.person_outline,
      _ => Icons.receipt_long,
    };

/// Reported orders, profiles, and chat messages.
class DisputesScreen extends StatelessWidget {
  const DisputesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(
        title: 'Disputes & Reports',
        subtitle: 'Review flagged orders, profiles, and messages',
        actions: [
          IconButton(
            tooltip: 'Print report history',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => guard(context, () async {
              await ReportPrinter.printHistory(await Db.instance.streamFlaggedContent().first);
            }),
          ),
        ],
      ),
      body: StreamView<List<Report>>(
        stream: Db.instance.streamFlaggedContent(),
        builder: (context, reports) {
          if (reports.isEmpty) {
            return const EmptyState(icon: Icons.verified_user_outlined, message: 'No reports. All clear!');
          }
          return PageBody(
            children: [
              for (final r in reports)
                ReportCard(
                  report: r,
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ReportReviewScreen(report: r))),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One row in the reports list: type icon, title, reporter, reason, and status.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, this.onTap});
  final Report report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = report;
    return AppCard(
      padding: const EdgeInsets.all(14),
      borderColor: r.isPending ? AppColors.warning.withValues(alpha: 0.35) : null,
      onTap: onTap,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBadge(_iconFor(r.type), color: r.isPending ? AppColors.warning : AppColors.success),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('Reported by ${r.reporterName} · ${timeAgo(r.createdAt)}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            const SizedBox(height: 6),
            Text('"${r.reason}"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.ink, fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(width: 8),
        StatusChip(r.status),
      ]),
    );
  }
}

class ReportReviewScreen extends StatefulWidget {
  const ReportReviewScreen({super.key, required this.report});
  final Report report;

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen> {
  static const _decisions = ['No action needed', 'Warning issued', 'Refund arranged', 'Account suspended'];
  final _notes = TextEditingController();
  String _decision = _decisions.first;
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final r = widget.report;
    setState(() => _busy = true);
    final ok = await guard(context, () async {
      if (_decision == 'Account suspended' && r.targetUserId.isNotEmpty) {
        final target = await Db.instance.streamUser(r.targetUserId).first;
        if (target != null && !target.isAdmin && target.status == AccountStatus.active) {
          await Db.instance.suspendAccount(target);
        }
      }
      await Db.instance.resolveDispute(r.id, _decision, _notes.text.trim());
    }, success: 'Report resolved.');
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Scaffold(
      appBar: brandAppBar(
        title: r.title,
        subtitle: 'Report details',
        actions: [
          IconButton(
            tooltip: 'Print report',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => guard(context, () => ReportPrinter.printReport(r)),
          ),
        ],
      ),
      body: PageBody(
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(children: [
              InfoRow(icon: Icons.flag_outlined, label: 'Status', child: Align(alignment: Alignment.centerLeft, child: StatusChip(r.status))),
              InfoRow(icon: Icons.person_outline, label: 'Reported by', value: '${r.reporterName} · ${formatDateTime(r.createdAt)}'),
              InfoRow(icon: Icons.person_off_outlined, label: 'Reported user', value: r.targetLabel),
              InfoRow(icon: Icons.report_outlined, label: 'Reason', value: r.reason),
              if (r.messageText.isNotEmpty)
                InfoRow(icon: _iconFor(ReportType.message), label: 'Reported message', value: '"${r.messageText}"'),
            ]),
          ),
          if (r.orderId.isNotEmpty || r.type == ReportType.profile) const SizedBox(height: 6),
          if (r.orderId.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderChatScreen(orderId: r.orderId))),
              icon: const Icon(Icons.forum_outlined),
              label: Text('Review order ${orderNumber(r.orderId)} conversation'),
            ),
          if (r.type == ReportType.profile)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute<void>(builder: (_) => TutorProfileViewScreen(tutorId: r.targetUserId))),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('View reported profile'),
            ),
          const SectionTitle('Resolution'),
          if (!r.isPending)
            AppCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Column(children: [
                InfoRow(icon: Icons.gavel, label: 'Decision', value: r.decision),
                if (r.notes.isNotEmpty) InfoRow(icon: Icons.notes, label: 'Notes', value: r.notes),
                InfoRow(icon: Icons.event_available, label: 'Resolved', value: formatDateTime(r.resolvedAt)),
              ]),
            )
          else ...[
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RadioGroup<String>(
                groupValue: _decision,
                onChanged: (v) => setState(() => _decision = v!),
                child: Column(
                  children: [
                    for (final d in _decisions)
                      RadioListTile<String>(value: d, title: Text(d, style: const TextStyle(fontSize: 14.5))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)', alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _resolve,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Resolved'),
            ),
          ],
        ],
      ),
    );
  }
}
