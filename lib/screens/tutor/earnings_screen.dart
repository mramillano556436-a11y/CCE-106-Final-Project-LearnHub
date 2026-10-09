import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/payment_record.dart';
import '../../services/db.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';

/// Tutor earnings after the automatic 5% platform fee.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<Session>().currentUser;
    return Scaffold(
      appBar: brandAppBar(title: 'Earnings', subtitle: 'Payouts after the 5% platform fee'),
      body: StreamView<List<TutoringOrder>>(
        stream: Db.instance.streamTutorOrders(me.uid),
        builder: (context, orders) => StreamView<List<PaymentRecord>>(
          stream: Db.instance.streamTutorTransactions(me.uid),
          builder: (context, txs) {
            final completedIds = orders.where((o) => o.status == OrderStatus.completed).map((o) => o.id).toSet();
            final total = Db.tutorTotalEarnings(txs, completedOrderIds: completedIds);
            final awaiting = Db.tutorTotalEarnings(txs) - total;
            return PageBody(
              children: [
                HeroCard(
                  icon: Icons.payments_outlined,
                  label: 'Total earnings',
                  value: formatPeso(total),
                  footer: awaiting > 0
                      ? '+ ${formatPeso(awaiting)} from paid sessions not yet completed'
                      : 'From ${completedIds.length} completed session${completedIds.length == 1 ? '' : 's'}',
                ),
                const SectionTitle('Recent Transactions'),
                if (txs.isEmpty) const EmptyState(icon: Icons.payments_outlined, message: 'No payments yet.'),
                for (final t in txs) _TransactionCard(tx: t, completed: completedIds.contains(t.orderId)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx, required this.completed});
  final PaymentRecord tx;
  final bool completed;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          UserAvatar(name: tx.clientName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.clientName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text('${tx.subject} · ${formatDate(tx.createdAt)}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text('Paid ${formatPeso(tx.amountCents)} · Fee ${formatPeso(tx.platformFeeCents)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Pill('+${formatPeso(tx.tutorPayoutCents)}', color: AppColors.success),
            const SizedBox(height: 6),
            Text(completed ? 'Completed' : 'Awaiting completion',
                style: TextStyle(fontSize: 11, color: completed ? AppColors.muted : AppColors.warning)),
          ]),
        ]),
      );
}
