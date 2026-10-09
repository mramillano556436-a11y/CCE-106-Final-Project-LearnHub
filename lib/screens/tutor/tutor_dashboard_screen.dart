import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/payment_record.dart';
import '../../models/tutor_profile.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';
import '../shared/order_chat_screen.dart';

/// Tutor landing page: active orders, unread messages, earnings, rating.
class TutorDashboardScreen extends StatelessWidget {
  const TutorDashboardScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return Scaffold(
      appBar: brandAppBar(
        title: 'Dashboard',
        subtitle: 'Welcome back, ${me.name.split(' ').first}',
        actions: [HeaderAvatar(name: me.name, photoUrl: me.photoUrl, onTap: () => onOpenTab(4))],
      ),
      body: StreamView<List<TutoringOrder>>(
        stream: Db.instance.streamTutorOrders(me.uid),
        builder: (context, orders) => StreamView<List<PaymentRecord>>(
          stream: Db.instance.streamTutorTransactions(me.uid),
          builder: (context, txs) => StreamView<TutorProfile?>(
            stream: Db.instance.streamTutorProfile(me.uid),
            builder: (context, profile) => _content(context, me.uid, orders, txs, profile),
          ),
        ),
      ),
    );
  }

  Widget _content(
      BuildContext context, String uid, List<TutoringOrder> orders, List<PaymentRecord> txs, TutorProfile? profile) {
    final now = DateTime.now();
    final active = orders.where((o) => OrderStatus.ongoing.contains(o.status)).length;
    final pending = orders.where((o) => o.status == OrderStatus.pending).length;
    final unread = orders.where((o) => o.hasUnreadFor(uid)).length;
    final thisMonth = txs
        .where((t) => t.createdAt != null && t.createdAt!.year == now.year && t.createdAt!.month == now.month)
        .fold(0, (total, t) => total + t.tutorPayoutCents);
    final recent = [...orders]..sort((a, b) => b.activityTime.compareTo(a.activityTime));

    return PageBody(
      children: [
        if (profile != null && !profile.approved) _ApprovalNotice(profile: profile, onTap: () => onOpenTab(4)),
        HeroCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Earned this month',
          value: formatPeso(thisMonth),
          footer: 'After the 5% platform fee',
          onTap: () => onOpenTab(3),
        ),
        StatGrid(children: [
          StatCard(value: '$active', label: 'Active orders', icon: Icons.event_note, onTap: () => onOpenTab(1)),
          StatCard(value: '$pending', label: 'New requests', icon: Icons.inbox_outlined, onTap: () => onOpenTab(1)),
          StatCard(value: '$unread', label: 'Unread chats', icon: Icons.chat_bubble_outline, onTap: () => onOpenTab(2)),
          StatCard(value: profile?.ratingLabel ?? 'New', label: 'Rating', icon: Icons.star_outline_rounded),
        ]),
        const SectionTitle('Recent Activity'),
        if (recent.isEmpty)
          const EmptyState(icon: Icons.inbox, message: 'No bookings yet.\nKeep your profile complete to get noticed!'),
        for (final o in recent.take(6))
          AppCard(
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderChatScreen(orderId: o.id))),
            child: Row(children: [
              UserAvatar(name: o.clientName, photoUrl: o.clientPhotoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.clientName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(o.hasUnreadFor(uid) ? 'Sent you a message' : 'Booked a session · ${o.subject}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ]),
              ),
              if (o.status == OrderStatus.pending)
                const StatusChip('new')
              else
                Text(timeAgo(o.activityTime), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
      ],
    );
  }
}

class _ApprovalNotice extends StatelessWidget {
  const _ApprovalNotice({required this.profile, required this.onTap});
  final TutorProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = profile.rejected ? AppColors.danger : AppColors.warning;
    return AppCard(
      onTap: onTap,
      color: color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        IconBadge(profile.rejected ? Icons.block : Icons.hourglass_top, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile.rejected ? 'Profile not approved' : 'Awaiting admin approval',
                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(
              profile.rejected
                  ? 'Update your profile and save it to resubmit for review.'
                  : 'Your listing appears in the directory once an admin approves it.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.35),
            ),
          ]),
        ),
        Icon(Icons.chevron_right, color: color),
      ]),
    );
  }
}
