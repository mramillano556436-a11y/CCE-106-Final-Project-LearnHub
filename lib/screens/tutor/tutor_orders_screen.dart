import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../widgets/common.dart';
import '../shared/order_chat_screen.dart';

/// Incoming and ongoing orders. Tutors accept/decline new requests here and
/// mark paid sessions as completed.
class TutorOrdersScreen extends StatelessWidget {
  const TutorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: brandAppBar(title: 'Orders', bottom: brandTabBar(const ['New', 'Ongoing', 'Completed'])),
        body: StreamView<List<TutoringOrder>>(
          stream: Db.instance.streamTutorOrders(me.uid),
          builder: (context, orders) => TabBarView(
            children: [
              _list(context, me.uid, orders.where((o) => o.status == OrderStatus.pending).toList()),
              _list(context, me.uid, orders.where((o) => OrderStatus.ongoing.contains(o.status)).toList()),
              _list(context, me.uid, orders.where((o) => OrderStatus.finished.contains(o.status)).toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, String uid, List<TutoringOrder> orders) {
    if (orders.isEmpty) return const EmptyState(icon: Icons.inbox, message: 'No orders here.');
    return PageBody(
      children: [
        for (final o in orders)
          OrderTile(
            order: o,
            viewerId: uid,
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderChatScreen(orderId: o.id))),
            footer: _actions(context, o),
          ),
      ],
    );
  }

  Widget? _actions(BuildContext context, TutoringOrder o) {
    if (o.status == OrderStatus.pending) {
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () =>
                guard(context, () => Db.instance.respondToOrder(o.id, OrderStatus.declined), success: 'Order declined.'),
            child: const Text('Decline'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            onPressed: () =>
                guard(context, () => Db.instance.respondToOrder(o.id, OrderStatus.confirmed), success: 'Order accepted.'),
            child: const Text('Accept'),
          ),
        ),
      ]);
    }
    if (o.status == OrderStatus.paid) {
      return FilledButton.icon(
        onPressed: () => guard(context, () => Db.instance.completeOrder(o), success: 'Session completed.'),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Mark as Completed'),
      );
    }
    return null;
  }
}
