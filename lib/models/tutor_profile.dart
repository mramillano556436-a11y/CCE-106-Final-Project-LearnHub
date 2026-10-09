import '../utils/format.dart';

/// A document in the `tutor_profiles` collection (doc id = tutor uid).
class TutorProfile {
  final String tutorId;
  final String name;
  final String photoUrl;
  final List<String> subjects;
  final int rateCents;
  final List<String> availableDays;
  final String timeFrom;
  final String timeTo;
  final String about;
  final bool profileComplete;
  final bool approved;
  final bool rejected;
  final int ratingSum;
  final int ratingCount;
  final DateTime? createdAt;

  const TutorProfile({
    required this.tutorId,
    required this.name,
    this.photoUrl = '',
    this.subjects = const [],
    this.rateCents = 0,
    this.availableDays = const [],
    this.timeFrom = '',
    this.timeTo = '',
    this.about = '',
    this.profileComplete = false,
    this.approved = false,
    this.rejected = false,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.createdAt,
  });

  double get rating => ratingCount == 0 ? 0 : ratingSum / ratingCount;
  String get ratingLabel => ratingCount == 0 ? 'New' : '${rating.toStringAsFixed(1)}/5';
  String get subjectsLabel => subjects.join(', ');

  /// Whether the tutor's daily hours overlap [slot].
  bool availableDuring(TimeSlot slot) {
    final from = minutesOfDay(timeFrom);
    final to = minutesOfDay(timeTo);
    if (from == null || to == null) return false;
    return from < slot.endMinute && to > slot.startMinute;
  }

  String get availabilityLabel {
    if (availableDays.isEmpty) return 'Not set';
    final days = availableDays.length == 7
        ? 'Every day'
        : weekDays.where(availableDays.contains).join(', ');
    return timeFrom.isEmpty ? days : '$days · $timeFrom – $timeTo';
  }

  factory TutorProfile.fromMap(String id, Map<String, dynamic> d) => TutorProfile(
        tutorId: id,
        name: d['name'] as String? ?? '',
        photoUrl: d['photoUrl'] as String? ?? '',
        subjects: List<String>.from(d['subjects'] as List? ?? const []),
        rateCents: (d['rateCents'] as num?)?.toInt() ?? 0,
        availableDays: List<String>.from(d['availableDays'] as List? ?? const []),
        timeFrom: d['timeFrom'] as String? ?? '',
        timeTo: d['timeTo'] as String? ?? '',
        about: d['about'] as String? ?? '',
        profileComplete: d['profileComplete'] as bool? ?? false,
        approved: d['approved'] as bool? ?? false,
        rejected: d['rejected'] as bool? ?? false,
        ratingSum: (d['ratingSum'] as num?)?.toInt() ?? 0,
        ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
        createdAt: toDate(d['createdAt']),
      );
}

/// Part of the day a client wants a session in.
enum TimeSlot {
  morning('Morning', 6 * 60, 12 * 60),
  afternoon('Afternoon', 12 * 60, 17 * 60),
  evening('Evening', 17 * 60, 22 * 60);

  const TimeSlot(this.label, this.startMinute, this.endMinute);
  final String label;
  final int startMinute;
  final int endMinute;
}

enum TutorSort {
  recommended('Recommended'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  rating('Highest rated'),
  newest('Newest');

  const TutorSort(this.label);
  final String label;
}

/// Criteria used by [Db.searchTutors]. Empty sets / nulls mean "any".
class TutorFilter {
  final String query;
  final Set<String> subjects;
  final int? minRateCents;
  final int? maxRateCents;
  final Set<String> days;
  final TimeSlot? timeSlot;
  final double minRating;
  final TutorSort sort;

  const TutorFilter({
    this.query = '',
    this.subjects = const {},
    this.minRateCents,
    this.maxRateCents,
    this.days = const {},
    this.timeSlot,
    this.minRating = 0,
    this.sort = TutorSort.recommended,
  });

  bool get hasPrice => minRateCents != null || maxRateCents != null;

  /// Number of filter groups in use (the search text and sort are not counted).
  int get activeCount =>
      (subjects.isNotEmpty ? 1 : 0) +
      (hasPrice ? 1 : 0) +
      (days.isNotEmpty ? 1 : 0) +
      (timeSlot != null ? 1 : 0) +
      (minRating > 0 ? 1 : 0);

  /// True when the user is searching rather than just browsing.
  bool get isSearching => query.trim().isNotEmpty || activeCount > 0 || sort != TutorSort.recommended;

  /// Clears every filter group but keeps the search text and sort.
  TutorFilter cleared() => TutorFilter(query: query, sort: sort);

  /// Nullable fields take a function so they can be set back to null.
  TutorFilter copyWith({
    String? query,
    Set<String>? subjects,
    int? Function()? minRateCents,
    int? Function()? maxRateCents,
    Set<String>? days,
    TimeSlot? Function()? timeSlot,
    double? minRating,
    TutorSort? sort,
  }) =>
      TutorFilter(
        query: query ?? this.query,
        subjects: subjects ?? this.subjects,
        minRateCents: minRateCents != null ? minRateCents() : this.minRateCents,
        maxRateCents: maxRateCents != null ? maxRateCents() : this.maxRateCents,
        days: days ?? this.days,
        timeSlot: timeSlot != null ? timeSlot() : this.timeSlot,
        minRating: minRating ?? this.minRating,
        sort: sort ?? this.sort,
      );
}
