import '../utils/format.dart';

class ReportType {
  static const order = 'order';
  static const profile = 'profile';
  static const message = 'message';
}

/// A document in the `reports` collection (disputes and flagged content).
class Report {
  final String id;
  final String type;
  final String reporterId;
  final String reporterName;
  final String targetUserId;
  final String targetLabel;
  final String orderId;
  final String messageText;
  final String reason;
  final String status;
  final String decision;
  final String notes;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const Report({
    required this.id,
    required this.type,
    required this.reporterId,
    required this.reporterName,
    required this.targetUserId,
    required this.targetLabel,
    this.orderId = '',
    this.messageText = '',
    required this.reason,
    this.status = 'pending',
    this.decision = '',
    this.notes = '',
    this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status == 'pending';

  String get title => switch (type) {
        ReportType.order => 'Order ${orderNumber(orderId)}',
        ReportType.message => 'Message from $targetLabel',
        _ => 'Profile: $targetLabel',
      };

  factory Report.fromMap(String id, Map<String, dynamic> d) => Report(
        id: id,
        type: d['type'] as String? ?? ReportType.order,
        reporterId: d['reporterId'] as String? ?? '',
        reporterName: d['reporterName'] as String? ?? '',
        targetUserId: d['targetUserId'] as String? ?? '',
        targetLabel: d['targetLabel'] as String? ?? '',
        orderId: d['orderId'] as String? ?? '',
        messageText: d['messageText'] as String? ?? '',
        reason: d['reason'] as String? ?? '',
        status: d['status'] as String? ?? 'pending',
        decision: d['decision'] as String? ?? '',
        notes: d['notes'] as String? ?? '',
        createdAt: toDate(d['createdAt']),
        resolvedAt: toDate(d['resolvedAt']),
      );
}
