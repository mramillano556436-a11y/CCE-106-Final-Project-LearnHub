import '../utils/format.dart';

/// Order lifecycle: pending → confirmed → paid → completed.
/// A pending order can also become declined (by the tutor) or cancelled (by the client).
class OrderStatus {
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const declined = 'declined';
  static const cancelled = 'cancelled';
  static const paid = 'paid';
  static const completed = 'completed';

  static const ongoing = [confirmed, paid];
  static const finished = [completed, declined, cancelled];
}

/// A document in the `orders` collection.
class TutoringOrder {
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhotoUrl;
  final String tutorId;
  final String tutorName;
  final String tutorPhotoUrl;
  final String subject;
  final DateTime? scheduleAt;
  final String notes;
  final int amountCents;
  final String status;
  final int? rating;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, DateTime?> lastRead;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TutoringOrder({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl = '',
    required this.tutorId,
    required this.tutorName,
    this.tutorPhotoUrl = '',
    required this.subject,
    this.scheduleAt,
    this.notes = '',
    required this.amountCents,
    required this.status,
    this.rating,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    this.lastMessageAt,
    this.lastRead = const {},
    this.createdAt,
    this.updatedAt,
  });

  String get number => orderNumber(id);
  DateTime get sortTime => createdAt ?? DateTime.now();
  DateTime get activityTime => lastMessageAt ?? updatedAt ?? sortTime;

  bool hasUnreadFor(String uid) {
    if (lastMessageAt == null || lastMessageSenderId == uid || lastMessageSenderId.isEmpty) {
      return false;
    }
    final read = lastRead[uid];
    return read == null || read.isBefore(lastMessageAt!);
  }

  String otherName(String uid) => uid == clientId ? tutorName : clientName;
  String otherPhoto(String uid) => uid == clientId ? tutorPhotoUrl : clientPhotoUrl;

  factory TutoringOrder.fromMap(String id, Map<String, dynamic> d) {
    final read = (d['lastRead'] as Map?) ?? const {};
    return TutoringOrder(
      id: id,
      clientId: d['clientId'] as String? ?? '',
      clientName: d['clientName'] as String? ?? '',
      clientPhotoUrl: d['clientPhotoUrl'] as String? ?? '',
      tutorId: d['tutorId'] as String? ?? '',
      tutorName: d['tutorName'] as String? ?? '',
      tutorPhotoUrl: d['tutorPhotoUrl'] as String? ?? '',
      subject: d['subject'] as String? ?? '',
      scheduleAt: toDate(d['scheduleAt']),
      notes: d['notes'] as String? ?? '',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      status: d['status'] as String? ?? OrderStatus.pending,
      rating: (d['rating'] as num?)?.toInt(),
      lastMessage: d['lastMessage'] as String? ?? '',
      lastMessageSenderId: d['lastMessageSenderId'] as String? ?? '',
      lastMessageAt: toDate(d['lastMessageAt']),
      lastRead: {for (final e in read.entries) e.key as String: toDate(e.value)},
      createdAt: toDate(d['createdAt']),
      updatedAt: toDate(d['updatedAt']),
    );
  }
}
