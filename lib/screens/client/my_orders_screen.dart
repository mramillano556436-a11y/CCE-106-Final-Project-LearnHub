import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../widgets/common.dart';
import '../shared/order_chat_screen.dart';
import 'checkout_screen.dart';

/// The client's orders, grouped into Pending / Ongoing / Completed tabs.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: brandAppBar(
          title: 'My Orders',
          bottom: brandTabBar(const ['Pending', 'Ongoing', 'Completed']),
        ),
        body: StreamView<List<TutoringOrder>>(
          stream: Db.instance.streamMyOrders(me.uid),
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
    if (orders.isEmpty) return const EmptyState(icon: Icons.receipt_long, message: 'No orders here yet.');
    return PageBody(
      children: [
        for (final o in orders)
          OrderTile(
            order: o,
            viewerId: uid,
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OrderChatScreen(orderId: o.id))),
            footer: o.status == OrderStatus.paid || o.status == OrderStatus.completed
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.receipt, size: 18),
                      label: const Text('View receipt'),
                      onPressed: () async {
                        final r = await Db.instance.getTransaction(o.id);
                        if (r != null && context.mounted) await showReceipt(context, r);
                      },
                    ),
                  )
                : null,
          ),
      ],
    );
  }
}
