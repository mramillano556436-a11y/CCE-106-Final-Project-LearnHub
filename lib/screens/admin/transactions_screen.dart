import 'package:flutter/material.dart';

import '../../models/payment_record.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';

/// Every completed transaction with its 5% fee and tutor payout.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: brandAppBar(title: 'Transactions', subtitle: 'Every payment and its 5% fee'),
      body: StreamView<List<PaymentRecord>>(
        stream: Db.instance.streamAllTransactions(),
        builder: (context, txs) => PageBody(
          children: [
            HeroCard(
              icon: Icons.account_balance_outlined,
              label: 'Total platform earnings',
              value: formatPeso(Db.totalPlatformEarnings(txs)),
              footer: 'Collected from ${txs.length} transaction${txs.length == 1 ? '' : 's'}',
            ),
            const SectionTitle('All transactions'),
            if (txs.isEmpty) const EmptyState(icon: Icons.receipt_long, message: 'No transactions yet.'),
            for (final t in txs) _TransactionCard(tx: t),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final PaymentRecord tx;

  @override
  Widget build(BuildContext context) {
    Widget figure(String label, int cents, {Color color = AppColors.ink}) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(formatPeso(cents), style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
          ]),
        );

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(children: [
        Row(children: [
          const IconBadge(Icons.receipt_long, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Order ${orderNumber(tx.orderId)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text('${tx.clientName} → ${tx.tutorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            ]),
          ),
          Text(formatDate(tx.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            figure('Amount', tx.amountCents),
            figure('Fee (5%)', tx.platformFeeCents, color: AppColors.primary),
            figure('Tutor payout', tx.tutorPayoutCents, color: AppColors.success),
          ]),
        ),
      ]),
    );
  }
}
