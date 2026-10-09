import 'package:intl/intl.dart';

import '../config.dart';

/// All money is stored as integer centavos to avoid floating point errors.
final _peso = NumberFormat.currency(locale: 'en_US', symbol: '₱', decimalDigits: 2);

String formatPeso(int cents) => _peso.format(cents / 100);

/// Parses user input like "250" or "250.50" into centavos. Returns null if invalid.
int? pesosToCents(String input) {
  final value = double.tryParse(input.replaceAll(',', '').replaceAll('₱', '').trim());
  if (value == null || value <= 0) return null;
  return (value * 100).round();
}

/// 5% platform fee, rounded down. Mirrors the check in firestore.rules.
int platformFeeCents(int amountCents) => amountCents ~/ AppConfig.platformFeeDivisor;

int tutorPayoutCents(int amountCents) => amountCents - platformFeeCents(amountCents);
