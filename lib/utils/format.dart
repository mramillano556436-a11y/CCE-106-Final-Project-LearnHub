import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

DateTime? toDate(Object? value) => value is Timestamp ? value.toDate() : null;

String formatDateTime(DateTime? d) => d == null ? '—' : DateFormat('EEE, MMM d · h:mm a').format(d);

String formatDate(DateTime? d) => d == null ? '—' : DateFormat('MMM d, yyyy').format(d);

String timeAgo(DateTime? d) {
  if (d == null) return 'now';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(d);
}

/// Short human-friendly order number, e.g. "#A1B2C3".
String orderNumber(String orderId) =>
    '#${orderId.substring(0, orderId.length < 6 ? orderId.length : 6).toUpperCase()}';

String initialOf(String name) => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Parses a label like "2:00 PM" into minutes after midnight.
int? minutesOfDay(String label) {
  final m = RegExp(r'^(\d{1,2}):(\d{2}) (AM|PM)$').firstMatch(label.trim());
  if (m == null) return null;
  final hour = int.parse(m[1]!) % 12 + (m[3] == 'PM' ? 12 : 0);
  return hour * 60 + int.parse(m[2]!);
}
