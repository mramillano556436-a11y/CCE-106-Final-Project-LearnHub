import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/models/tutor_profile.dart';
import 'package:learnhub/services/db.dart';
import 'package:learnhub/utils/money.dart';

TutorProfile tutor(String id, List<String> subjects, int rateCents,
        {bool approved = true,
        bool complete = true,
        List<String> days = const ['Mon'],
        String from = '',
        String to = '',
        (int, int) rating = (0, 0)}) =>
    TutorProfile(
      tutorId: id,
      name: 'Tutor $id',
      subjects: subjects,
      rateCents: rateCents,
      availableDays: days,
      timeFrom: from,
      timeTo: to,
      approved: approved,
      profileComplete: complete,
      ratingSum: rating.$1,
      ratingCount: rating.$2,
    );

void main() {
  group('5% platform fee (WB-CLI007)', () {
    test('fee and payout split a ₱12.00 session', () {
      expect(platformFeeCents(1200), 60);
      expect(tutorPayoutCents(1200), 1140);
    });

    test('fee rounds down and fee + payout always equals the amount', () {
      for (final amount in [1, 19, 20, 999, 1250, 123456]) {
        expect(platformFeeCents(amount) + tutorPayoutCents(amount), amount);
        expect(platformFeeCents(amount), amount ~/ 20);
      }
    });

    test('peso parsing and formatting', () {
      expect(pesosToCents('250'), 25000);
      expect(pesosToCents('₱1,250.50'), 125050);
      expect(pesosToCents('abc'), isNull);
      expect(pesosToCents('0'), isNull);
      expect(formatPeso(125050), '₱1,250.50');
    });
  });

  group('searchTutors (WB-CLI003, WB-TUT003)', () {
    final tutors = [
      tutor('a', ['Mathematics'], 1200, from: '9:00 AM', to: '11:00 AM', rating: (9, 2)),
      tutor('b', ['Chemistry'], 1500, days: ['Sat'], from: '1:00 PM', to: '4:00 PM', rating: (10, 2)),
      tutor('c', ['Mathematics', 'Physics'], 2500, from: '6:00 PM', to: '9:00 PM'),
      tutor('d', ['Mathematics'], 1000, complete: false),
      tutor('e', ['Mathematics'], 1000, approved: false),
    ];
    List<String> ids(TutorFilter f) => Db.searchTutors(tutors, f).map((t) => t.tutorId).toList();

    test('no filters returns every published tutor only', () {
      expect(ids(const TutorFilter()), ['a', 'b', 'c']);
      expect(const TutorFilter().activeCount, 0);
    });

    test('subjects (any of, case-insensitive), price, and days', () {
      expect(ids(const TutorFilter(subjects: {'mathematics'})), ['a', 'c']);
      expect(ids(const TutorFilter(subjects: {'Physics', 'Chemistry'})), ['b', 'c']);
      expect(ids(const TutorFilter(maxRateCents: 1500)), ['a', 'b']);
      expect(ids(const TutorFilter(minRateCents: 1300, maxRateCents: 3000)), ['b', 'c']);
      expect(ids(const TutorFilter(days: {'Sat'})), ['b']);
      expect(ids(const TutorFilter(days: {'Sat', 'Mon'})), ['a', 'b', 'c']);
      expect(ids(const TutorFilter(query: 'phys')), ['c']);
    });

    test('time of day matches overlapping hours', () {
      expect(ids(const TutorFilter(timeSlot: TimeSlot.morning)), ['a']);
      expect(ids(const TutorFilter(timeSlot: TimeSlot.afternoon)), ['b']);
      expect(ids(const TutorFilter(timeSlot: TimeSlot.evening)), ['c']);
    });

    test('rating filter and sorting', () {
      expect(ids(const TutorFilter(minRating: 4.6)), ['b']);
      expect(ids(const TutorFilter(sort: TutorSort.priceHigh)), ['c', 'b', 'a']);
      expect(ids(const TutorFilter(sort: TutorSort.priceLow)), ['a', 'b', 'c']);
      expect(ids(const TutorFilter(sort: TutorSort.rating)), ['b', 'a', 'c']);
    });

    test('copyWith can clear nullable fields', () {
      const f = TutorFilter(minRateCents: 100, maxRateCents: 900, timeSlot: TimeSlot.morning, days: {'Mon'});
      expect(f.activeCount, 3);
      final cleared = f.copyWith(minRateCents: () => null, maxRateCents: () => null, timeSlot: () => null);
      expect(cleared.hasPrice, isFalse);
      expect(cleared.timeSlot, isNull);
      expect(f.cleared().activeCount, 0);
    });
  });
}
