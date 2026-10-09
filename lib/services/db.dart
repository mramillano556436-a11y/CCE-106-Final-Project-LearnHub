import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/order.dart';
import '../models/payment_record.dart';
import '../models/report.dart';
import '../models/tutor_profile.dart';
import '../utils/money.dart';

/// All Firestore reads and writes. Method names follow the test cases in the
/// project documentation (placeOrder, processPayment, approveTutor, ...).
///
/// Collections: users, tutor_profiles, orders, orders/{id}/messages,
/// transactions, reports. Access is enforced by firestore.rules.
class Db {
  Db._();
  static final instance = Db._();

  final _fs = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users => _fs.collection('users');
  CollectionReference<Map<String, dynamic>> get _tutors => _fs.collection('tutor_profiles');
  CollectionReference<Map<String, dynamic>> get _orders => _fs.collection('orders');
  CollectionReference<Map<String, dynamic>> get _transactions => _fs.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _reports => _fs.collection('reports');

  static final _now = FieldValue.serverTimestamp();

  // ---------------------------------------------------------------- Users

  /// Creates the `users` document (and an empty tutor profile for tutors).
  /// Used by registerClient / registerTutor and first-time Google sign-in.
  Future<void> createUserDoc({
    required String uid,
    required String name,
    required String email,
    required String role,
    String photoUrl = '',
  }) async {
    final batch = _fs.batch();
    batch.set(_users.doc(uid), {
      'name': name,
      'email': email.toLowerCase(),
      'phone': '',
      'photoUrl': photoUrl,
      'role': role,
      'status': AccountStatus.active,
      'profileComplete': role != UserRole.tutor,
      'createdAt': _now,
      'updatedAt': _now,
    });
    if (role == UserRole.tutor) {
      batch.set(_tutors.doc(uid), {
        'name': name,
        'photoUrl': photoUrl,
        'subjects': <String>[],
        'subjectsLower': <String>[],
        'rateCents': 0,
        'availableDays': <String>[],
        'timeFrom': '',
        'timeTo': '',
        'about': '',
        'profileComplete': false,
        'approved': false,
        'rejected': false,
        'ratingSum': 0,
        'ratingCount': 0,
        'lastRatedOrderId': '',
        'createdAt': _now,
        'updatedAt': _now,
      });
    }
    await batch.commit();
  }

  /// Promotes the configured admin email's account to the admin role.
  Future<void> promoteToAdmin(String uid) =>
      _users.doc(uid).update({'role': UserRole.admin, 'profileComplete': true, 'updatedAt': _now});

  Stream<AppUser?> streamUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? AppUser.fromMap(s.id, s.data()!) : null);

  /// Writes only the fields that changed, plus updatedAt.
  Future<void> updateClientProfile(String uid, Map<String, Object?> changes) async {
    if (changes.isEmpty) return;
    await _users.doc(uid).update({...changes, 'updatedAt': _now});
  }

  // -------------------------------------------------------- Tutor profiles

  /// Saves a tutor's public listing and marks the profile complete.
  Future<void> updateTutorProfile({
    required String uid,
    required String name,
    required String photoUrl,
    required List<String> subjects,
    required int rateCents,
    required List<String> availableDays,
    required String timeFrom,
    required String timeTo,
    required String about,
  }) async {
    final batch = _fs.batch();
    batch.update(_tutors.doc(uid), {
      'name': name,
      'photoUrl': photoUrl,
      'subjects': subjects,
      'subjectsLower': subjects.map((s) => s.toLowerCase()).toList(),
      'rateCents': rateCents,
      'availableDays': availableDays,
      'timeFrom': timeFrom,
      'timeTo': timeTo,
      'about': about,
      'profileComplete': true,
      'rejected': false,
      'updatedAt': _now,
    });
    batch.update(_users.doc(uid), {
      'name': name,
      'photoUrl': photoUrl,
      'profileComplete': true,
      'updatedAt': _now,
    });
    await batch.commit();
  }

  Stream<TutorProfile?> streamTutorProfile(String tutorId) => _tutors
      .doc(tutorId)
      .snapshots()
      .map((s) => s.exists ? TutorProfile.fromMap(s.id, s.data()!) : null);

  Future<TutorProfile?> getTutorProfile(String tutorId) async {
    final s = await _tutors.doc(tutorId).get();
    return s.exists ? TutorProfile.fromMap(s.id, s.data()!) : null;
  }

  /// Approved, complete tutor listings, newest first.
  Stream<List<TutorProfile>> streamPublishedTutors() => _tutors
      .where('approved', isEqualTo: true)
      .where('profileComplete', isEqualTo: true)
      .snapshots()
      .map((q) => q.docs.map((d) => TutorProfile.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now())));

  /// Filters and sorts published tutors. With an empty filter, every
  /// published tutor is returned in its original (newest-first) order.
  static List<TutorProfile> searchTutors(List<TutorProfile> tutors, TutorFilter f) {
    final q = f.query.trim().toLowerCase();
    final subjects = {for (final s in f.subjects) s.toLowerCase()};
    final results = tutors.where((t) {
      if (!t.approved || !t.profileComplete) return false;
      if (q.isNotEmpty &&
          !t.name.toLowerCase().contains(q) &&
          !t.subjects.any((s) => s.toLowerCase().contains(q))) {
        return false;
      }
      if (subjects.isNotEmpty && !t.subjects.any((s) => subjects.contains(s.toLowerCase()))) return false;
      if (f.minRateCents != null && t.rateCents < f.minRateCents!) return false;
      if (f.maxRateCents != null && t.rateCents > f.maxRateCents!) return false;
      if (f.days.isNotEmpty && !t.availableDays.any(f.days.contains)) return false;
      if (f.timeSlot != null && !t.availableDuring(f.timeSlot!)) return false;
      if (f.minRating > 0 && t.rating < f.minRating) return false;
      return true;
    }).toList();

    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    switch (f.sort) {
      case TutorSort.recommended:
        break;
      case TutorSort.priceLow:
        results.sort((a, b) => a.rateCents.compareTo(b.rateCents));
      case TutorSort.priceHigh:
        results.sort((a, b) => b.rateCents.compareTo(a.rateCents));
      case TutorSort.rating:
        results.sort((a, b) {
          final byRating = b.rating.compareTo(a.rating);
          return byRating != 0 ? byRating : b.ratingCount.compareTo(a.ratingCount);
        });
      case TutorSort.newest:
        results.sort((a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch));
    }
    return results;
  }

  // ---------------------------------------------------------------- Orders

  Future<String> placeOrder({
    required AppUser client,
    required TutorProfile tutor,
    required String subject,
    required DateTime scheduleAt,
    required String notes,
  }) async {
    final ref = await _orders.add({
      'clientId': client.uid,
      'clientName': client.name,
      'clientPhotoUrl': client.photoUrl,
      'tutorId': tutor.tutorId,
      'tutorName': tutor.name,
      'tutorPhotoUrl': tutor.photoUrl,
      'subject': subject,
      'scheduleAt': Timestamp.fromDate(scheduleAt),
      'notes': notes,
      'amountCents': tutor.rateCents,
      'status': OrderStatus.pending,
      'rating': null,
      'lastMessage': '',
      'lastMessageSenderId': '',
      'lastMessageAt': null,
      'lastRead': <String, Object>{},
      'createdAt': _now,
      'updatedAt': _now,
    });
    return ref.id;
  }

  Stream<TutoringOrder?> streamOrder(String orderId) => _orders
      .doc(orderId)
      .snapshots()
      .map((s) => s.exists ? TutoringOrder.fromMap(s.id, s.data()!) : null);

  List<TutoringOrder> _sortedOrders(QuerySnapshot<Map<String, dynamic>> q) =>
      q.docs.map((d) => TutoringOrder.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.sortTime.compareTo(a.sortTime));

  /// The signed-in client's orders, newest first.
  Stream<List<TutoringOrder>> streamMyOrders(String clientId) =>
      _orders.where('clientId', isEqualTo: clientId).snapshots().map(_sortedOrders);

  /// Orders addressed to this tutor, newest first.
  Stream<List<TutoringOrder>> streamTutorOrders(String tutorId) =>
      _orders.where('tutorId', isEqualTo: tutorId).snapshots().map(_sortedOrders);

  Stream<List<TutoringOrder>> streamAllOrders() => _orders.snapshots().map(_sortedOrders);

  /// Tutor accepts ("confirmed") or declines ("declined") a pending order.
  Future<void> respondToOrder(String orderId, String status) {
    assert(status == OrderStatus.confirmed || status == OrderStatus.declined);
    return _orders.doc(orderId).update({'status': status, 'updatedAt': _now});
  }

  Future<void> cancelOrder(String orderId) =>
      _orders.doc(orderId).update({'status': OrderStatus.cancelled, 'updatedAt': _now});

  /// Only a paid order can be marked completed.
  Future<void> completeOrder(TutoringOrder order) {
    if (order.status != OrderStatus.paid) {
      throw StateError('Only paid orders can be marked as completed.');
    }
    return _orders.doc(order.id).update({'status': OrderStatus.completed, 'updatedAt': _now});
  }

  /// Records a mock payment with the automatic 5% fee and marks the order paid.
  /// The transaction doc id equals the order id, so an order can only be paid once.
  Future<PaymentRecord> processPayment(TutoringOrder order, String method) async {
    if (order.status != OrderStatus.confirmed) {
      throw StateError('This order must be confirmed by the tutor before payment.');
    }
    final fee = platformFeeCents(order.amountCents);
    final payout = tutorPayoutCents(order.amountCents);
    final batch = _fs.batch();
    batch.set(_transactions.doc(order.id), {
      'orderId': order.id,
      'clientId': order.clientId,
      'clientName': order.clientName,
      'tutorId': order.tutorId,
      'tutorName': order.tutorName,
      'subject': order.subject,
      'amountCents': order.amountCents,
      'platformFeeCents': fee,
      'tutorPayoutCents': payout,
      'method': method,
      'createdAt': _now,
    });
    batch.update(_orders.doc(order.id), {'status': OrderStatus.paid, 'updatedAt': _now});
    await batch.commit();
    return PaymentRecord(
      id: order.id,
      orderId: order.id,
      clientId: order.clientId,
      clientName: order.clientName,
      tutorId: order.tutorId,
      tutorName: order.tutorName,
      subject: order.subject,
      amountCents: order.amountCents,
      platformFeeCents: fee,
      tutorPayoutCents: payout,
      method: method,
      createdAt: DateTime.now(),
    );
  }

  Future<PaymentRecord?> getTransaction(String orderId) async {
    final s = await _transactions.doc(orderId).get();
    return s.exists ? PaymentRecord.fromMap(s.id, s.data()!) : null;
  }

  /// Client rates a completed order (1–5) and the tutor's average is updated.
  Future<void> rateOrder(TutoringOrder order, int stars) async {
    final batch = _fs.batch();
    batch.update(_orders.doc(order.id), {'rating': stars, 'updatedAt': _now});
    batch.update(_tutors.doc(order.tutorId), {
      'ratingSum': FieldValue.increment(stars),
      'ratingCount': FieldValue.increment(1),
      'lastRatedOrderId': order.id,
    });
    await batch.commit();
  }

  // ------------------------------------------------------------------ Chat

  Stream<List<ChatMessage>> streamMessages(String orderId) => _orders
      .doc(orderId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((q) => q.docs.map((d) => ChatMessage.fromMap(d.id, d.data())).toList());

  /// Adds a message to the order's chat thread. Works offline: Firestore
  /// queues the write and sends it when the connection returns.
  Future<void> sendMessage({
    required TutoringOrder order,
    required AppUser sender,
    String text = '',
    String fileUrl = '',
    String fileName = '',
    bool isImage = false,
  }) async {
    final orderRef = _orders.doc(order.id);
    final batch = _fs.batch();
    batch.set(orderRef.collection('messages').doc(), {
      'senderId': sender.uid,
      'senderName': sender.name,
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'isImage': isImage,
      'createdAt': _now,
    });
    batch.update(orderRef, {
      'lastMessage': text.isNotEmpty ? text : '📎 $fileName',
      'lastMessageSenderId': sender.uid,
      'lastMessageAt': _now,
      'lastRead.${sender.uid}': _now,
    });
    await batch.commit();
  }

  Future<void> markRead(String orderId, String uid) =>
      _orders.doc(orderId).update({'lastRead.$uid': _now});

  // ---------------------------------------------------------- Transactions

  Stream<List<PaymentRecord>> _txStream(Query<Map<String, dynamic>> q) => q.snapshots().map(
      (s) => s.docs.map((d) => PaymentRecord.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now())));

  Stream<List<PaymentRecord>> streamTutorTransactions(String tutorId) =>
      _txStream(_transactions.where('tutorId', isEqualTo: tutorId));

  Stream<List<PaymentRecord>> streamAllTransactions() => _txStream(_transactions);

  /// Sum of tutor payouts for transactions whose orders are completed.
  static int tutorTotalEarnings(List<PaymentRecord> txs, {Set<String>? completedOrderIds}) => txs
      .where((t) => completedOrderIds == null || completedOrderIds.contains(t.orderId))
      .fold(0, (total, t) => total + t.tutorPayoutCents);

  static int totalPlatformEarnings(List<PaymentRecord> txs) =>
      txs.fold(0, (total, t) => total + t.platformFeeCents);

  // ----------------------------------------------------------------- Admin

  Stream<List<AppUser>> streamAllUsers() => _users.snapshots().map((q) =>
      q.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  Stream<List<TutorProfile>> streamAllTutorProfiles() => _tutors
      .snapshots()
      .map((q) => q.docs.map((d) => TutorProfile.fromMap(d.id, d.data())).toList());

  Future<void> approveTutor(String tutorId) =>
      _tutors.doc(tutorId).update({'approved': true, 'rejected': false, 'updatedAt': _now});

  Future<void> rejectTutor(String tutorId) =>
      _tutors.doc(tutorId).update({'approved': false, 'rejected': true, 'updatedAt': _now});

  /// Blocks future logins. A suspended tutor is also hidden from the directory
  /// and has to be re-approved after reactivation.
  Future<void> suspendAccount(AppUser user, {bool delete = false}) async {
    final batch = _fs.batch();
    batch.update(_users.doc(user.uid), {
      'status': delete ? AccountStatus.deleted : AccountStatus.suspended,
      'updatedAt': _now,
    });
    if (user.isTutor) {
      batch.update(_tutors.doc(user.uid), {'approved': false, 'updatedAt': _now});
    }
    await batch.commit();
  }

  Future<void> reactivateAccount(String uid) =>
      _users.doc(uid).update({'status': AccountStatus.active, 'updatedAt': _now});

  // --------------------------------------------------------------- Reports

  Future<void> reportContent({
    required AppUser reporter,
    required String type,
    required String targetUserId,
    required String targetLabel,
    required String reason,
    String orderId = '',
    String messageText = '',
  }) =>
      _reports.add({
        'type': type,
        'reporterId': reporter.uid,
        'reporterName': reporter.name,
        'targetUserId': targetUserId,
        'targetLabel': targetLabel,
        'orderId': orderId,
        'messageText': messageText,
        'reason': reason,
        'status': 'pending',
        'decision': '',
        'notes': '',
        'createdAt': _now,
        'resolvedAt': null,
      });

  /// All reports, pending first then newest first.
  Stream<List<Report>> streamFlaggedContent() => _reports.snapshots().map((q) =>
      q.docs.map((d) => Report.fromMap(d.id, d.data())).toList()
        ..sort((a, b) {
          if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
          return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
        }));

  Future<void> resolveDispute(String reportId, String decision, String notes) =>
      _reports.doc(reportId).update({
        'status': 'resolved',
        'decision': decision,
        'notes': notes,
        'resolvedAt': _now,
      });
}
