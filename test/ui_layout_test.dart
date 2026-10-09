import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/models/order.dart';
import 'package:learnhub/models/tutor_profile.dart';
import 'package:learnhub/screens/client/tutor_card.dart';
import 'package:learnhub/screens/client/tutor_filters.dart';
import 'package:learnhub/theme.dart';
import 'package:learnhub/widgets/common.dart';

/// Renders the shared containers on a small phone to catch layout overflows.
void main() {
  for (final width in [320.0, 412.0]) {
    testWidgets('shared containers fit at ${width.toInt()}px wide', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final order = TutoringOrder(
        id: 'abcdef123',
        clientId: 'c1',
        clientName: 'Jamie Lopez',
        tutorId: 't1',
        tutorName: 'Angela Cruz',
        subject: 'Mathematics',
        scheduleAt: DateTime(2026, 10, 9, 15),
        amountCents: 120000,
        status: OrderStatus.pending,
      );
      const tutor = TutorProfile(
        tutorId: 't1',
        name: 'Angela Cruz',
        subjects: ['Mathematics', 'Calculus', 'Statistics'],
        rateCents: 120000,
        availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        approved: true,
        profileComplete: true,
        ratingSum: 48,
        ratingCount: 10,
      );

      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: brandAppBar(
              title: 'Dashboard',
              subtitle: 'Welcome back, Angela',
              bottom: brandTabBar(const ['Pending', 'Ongoing', 'Completed']),
            ),
            body: PageBody(children: [
              const HeroCard(icon: Icons.payments, label: 'Earned this month', value: '₱12,345.67', footer: 'After fees'),
              StatGrid(children: [
                StatCard(value: '12', label: 'Active orders', icon: Icons.event_note, onTap: () {}),
                const StatCard(value: '₱1,234.00', label: 'This month', icon: Icons.payments),
              ]),
              const SectionTitle('Recent Activity', trailing: Pill('Review')),
              OrderTile(
                order: order,
                viewerId: 't1',
                footer: Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Decline'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: () {}, child: const Text('Accept'))),
                ]),
              ),
              const TutorCard(tutor: tutor),
              Row(children: [
                const Expanded(child: TextField()),
                const SizedBox(width: 10),
                FilterButton(count: 3, onPressed: () {}),
              ]),
              ActiveFilterChips(
                filter: const TutorFilter(
                  subjects: {'Mathematics'},
                  minRateCents: 50000,
                  maxRateCents: 150000,
                  days: {'Mon', 'Wed', 'Fri'},
                  timeSlot: TimeSlot.afternoon,
                  minRating: 4.5,
                ),
                onChanged: (_) {},
              ),
              SizedBox(width: 200, child: StarRatingPicker(value: 4, onChanged: (_) {})),
              ResultsHeader(count: 12, sort: TutorSort.priceLow, onSort: (_) {}),
              TutorFilterPanel(
                filter: const TutorFilter(subjects: {'Calculus'}, timeSlot: TimeSlot.evening, minRating: 4),
                subjects: const ['Mathematics', 'Calculus', 'Statistics', 'English Writing', 'Python'],
                ceilingCents: 300000,
                onChanged: (_) {},
              ),
              const InfoRow(icon: Icons.schedule, label: 'Availability', value: 'Mon–Fri · 2:00 PM – 8:00 PM'),
              const ProfileHeader(name: 'Jamie Lopez', photoUrl: '', caption: 'Client since 2026'),
              const EmptyState(icon: Icons.inbox, message: 'No orders here yet.'),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      expect(error, isNull, reason: error is FlutterError ? error.toStringDeep() : '$error');
    });
  }
}
