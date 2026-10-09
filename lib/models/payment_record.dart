import '../utils/format.dart';

/// A document in the `transactions` collection (doc id = order id).
class PaymentRecord {
  final String id;
  final String orderId;
  final String clientId;
  final String clientName;
  final String tutorId;
  final String tutorName;
  final String subject;
  final int amountCents;
  final int platformFeeCents;
  final int tutorPayoutCents;
  final String method;
  final DateTime? createdAt;

  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.clientId,
    required this.clientName,
    required this.tutorId,
    required this.tutorName,
    required this.subject,
    required this.amountCents,
    required this.platformFeeCents,
    required this.tutorPayoutCents,
    required this.method,
    this.createdAt,
  });

  factory PaymentRecord.fromMap(String id, Map<String, dynamic> d) => PaymentRecord(
        id: id,
        orderId: d['orderId'] as String? ?? id,
        clientId: d['clientId'] as String? ?? '',
        clientName: d['clientName'] as String? ?? '',
        tutorId: d['tutorId'] as String? ?? '',
        tutorName: d['tutorName'] as String? ?? '',
        subject: d['subject'] as String? ?? '',
        amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
        platformFeeCents: (d['platformFeeCents'] as num?)?.toInt() ?? 0,
        tutorPayoutCents: (d['tutorPayoutCents'] as num?)?.toInt() ?? 0,
        method: d['method'] as String? ?? '',
        createdAt: toDate(d['createdAt']),
      );
}
