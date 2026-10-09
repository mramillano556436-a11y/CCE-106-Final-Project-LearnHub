import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/payment_record.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/money.dart';
import '../../widgets/common.dart';

/// Mock checkout. No real money moves; the payment is recorded in
/// `transactions` with the automatic 5% platform fee.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.order});
  final TutoringOrder order;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _methods = [
    ('GCash', Icons.account_balance_wallet, 'Pay with your GCash wallet'),
    ('Credit / Debit Card', Icons.credit_card, 'Visa, Mastercard, and more'),
  ];

  String _method = 'GCash';
  bool _busy = false;

  Future<void> _pay() async {
    setState(() => _busy = true);
    PaymentRecord? receipt;
    final ok = await guard(context, () async {
      receipt = await Db.instance.processPayment(widget.order, _method);
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    await showReceipt(context, receipt!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: brandAppBar(title: 'Checkout', subtitle: 'Order ${o.number}'),
      body: PageBody(
        children: [
          const SectionTitle('Order Summary'),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                UserAvatar(name: o.tutorName, photoUrl: o.tutorPhotoUrl, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.tutorName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.ink)),
                    Text('${o.subject} · 1 session', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ]),
                ),
              ]),
              const Divider(height: 24),
              _row('Schedule', formatDateTime(o.scheduleAt)),
              _row('Session rate', formatPeso(o.amountCents)),
            ]),
          ),
          const SectionTitle('Payment Method'),
          for (final (method, icon, hint) in _methods)
            AppCard(
              onTap: () => setState(() => _method = method),
              borderColor: _method == method ? AppColors.primary : null,
              color: _method == method ? AppColors.tint : null,
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                IconBadge(icon, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(method, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text(hint, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ]),
                ),
                Icon(
                  _method == method ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _method == method ? AppColors.primary : AppColors.border,
                ),
              ]),
            ),
          const SizedBox(height: 6),
          HeroCard(
            icon: Icons.receipt_long,
            label: 'Total to pay',
            value: formatPeso(o.amountCents),
            footer: 'Demo payment — no real charge is made',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _busy ? null : _pay,
            icon: _busy
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.lock_outline),
            label: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
      );
}

Future<void> showReceipt(BuildContext context, PaymentRecord r) => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        scrollable: true,
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 38),
        ),
        title: const Text('Payment Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (label, value) in [
              ('Order', orderNumber(r.orderId)),
              ('Tutor', r.tutorName),
              ('Subject', r.subject),
              ('Method', r.method),
              ('Date', formatDateTime(r.createdAt)),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
                  Flexible(
                    child: Text(value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                ]),
              ),
            const Divider(height: 20),
            Row(children: [
              const Expanded(
                child: Text('Amount paid', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              Text(formatPeso(r.amountCents),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Done'))],
      ),
    );
