import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'order_chat_screen.dart';

/// Chat inbox: one thread per order, most recent activity first.
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    final stream = me.isTutor ? Db.instance.streamTutorOrders(me.uid) : Db.instance.streamMyOrders(me.uid);
    return Scaffold(
      appBar: brandAppBar(title: 'Messages', subtitle: 'One conversation per order'),
      body: StreamView<List<TutoringOrder>>(
        stream: stream,
        builder: (context, orders) {
          final threads = [...orders]..sort((a, b) => b.activityTime.compareTo(a.activityTime));
          if (threads.isEmpty) {
            return const EmptyState(icon: Icons.forum_outlined, message: 'Chats appear here once an order is placed.');
          }
          return PageBody(
            children: [
              for (final o in threads) _ThreadCard(order: o, uid: me.uid),
            ],
          );
        },
      ),
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.order, required this.uid});
  final TutoringOrder order;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final unread = order.hasUnreadFor(uid);
    return AppCard(
      borderColor: unread ? AppColors.primary.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(14),
      onTap: () =>
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderChatScreen(orderId: order.id))),
      child: Row(children: [
        UserAvatar(name: order.otherName(uid), photoUrl: order.otherPhoto(uid), radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(order.otherName(uid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                ),
                Text(timeAgo(order.activityTime),
                    style: TextStyle(
                        fontSize: 11.5,
                        color: unread ? AppColors.primary : AppColors.muted,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w400)),
              ]),
              const SizedBox(height: 2),
              Text('${order.subject} · ${order.number}',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text(
                    order.lastMessage.isEmpty ? 'No messages yet' : order.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: unread ? AppColors.ink : AppColors.muted,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
                  ),
                ),
                if (unread)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(gradient: AppColors.gradient, shape: BoxShape.circle),
                  ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}
