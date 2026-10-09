import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/payment_record.dart';
import '../../models/report.dart';
import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';

/// Platform-wide totals and items needing the admin's attention.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final db = Db.instance;
    final me = context.watch<Session>().currentUser;
    return Scaffold(
      appBar: brandAppBar(
        title: 'Admin Dashboard',
        subtitle: 'Platform overview',
        actions: [HeaderAvatar(name: me.name, photoUrl: me.photoUrl, onTap: () => onOpenTab(4))],
      ),
      body: StreamView<List<AppUser>>(
        stream: db.streamAllUsers(),
        builder: (context, users) => StreamView<List<TutoringOrder>>(
          stream: db.streamAllOrders(),
          builder: (context, orders) => StreamView<List<PaymentRecord>>(
            stream: db.streamAllTransactions(),
            builder: (context, txs) => StreamView<List<TutorProfile>>(
              stream: db.streamAllTutorProfiles(),
              builder: (context, tutors) => StreamView<List<Report>>(
                stream: db.streamFlaggedContent(),
                builder: (context, reports) {
                  final pendingTutors = tutors.where((t) => t.profileComplete && !t.approved && !t.rejected).length;
                  final pendingReports = reports.where((r) => r.isPending).length;
                  return PageBody(
                    children: [
                      HeroCard(
                        icon: Icons.account_balance_outlined,
                        label: 'Platform earnings (5% fees)',
                        value: formatPeso(Db.totalPlatformEarnings(txs)),
                        footer: 'From ${txs.length} transaction${txs.length == 1 ? '' : 's'}',
                        onTap: () => onOpenTab(3),
                      ),
                      StatGrid(children: [
                        StatCard(
                          value: '${users.where((u) => u.isTutor).length}',
                          label: 'Tutors',
                          icon: Icons.co_present,
                          onTap: () => onOpenTab(1),
                        ),
                        StatCard(
                          value: '${users.where((u) => u.isClient).length}',
                          label: 'Clients',
                          icon: Icons.people_outline,
                          onTap: () => onOpenTab(1),
                        ),
                        StatCard(value: '${orders.length}', label: 'Orders / bookings', icon: Icons.receipt_long),
                        StatCard(
                          value: '${txs.length}',
                          label: 'Transactions',
                          icon: Icons.payments_outlined,
                          onTap: () => onOpenTab(3),
                        ),
                      ]),
                      const SectionTitle('Needs Attention'),
                      _AttentionCard(
                        icon: Icons.how_to_reg_outlined,
                        count: pendingTutors,
                        label: pendingTutors == 1 ? 'tutor' : 'tutors',
                        detail: 'Pending approval',
                        onTap: () => onOpenTab(1),
                      ),
                      _AttentionCard(
                        icon: Icons.flag_outlined,
                        count: pendingReports,
                        label: pendingReports == 1 ? 'report' : 'reports',
                        detail: 'Flagged content and disputes',
                        onTap: () => onOpenTab(2),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final int count;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsAction = count > 0;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      borderColor: needsAction ? AppColors.warning.withValues(alpha: 0.4) : null,
      child: Row(children: [
        IconBadge(needsAction ? icon : Icons.check_circle_outline,
            color: needsAction ? AppColors.warning : AppColors.success),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count $label', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
            Text(needsAction ? detail : 'All caught up', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ]),
        ),
        const Pill('Review'),
      ]),
    );
  }
}
