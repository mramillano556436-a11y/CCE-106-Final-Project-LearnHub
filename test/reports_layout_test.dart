import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/models/report.dart';
import 'package:learnhub/screens/admin/disputes_screen.dart';
import 'package:learnhub/services/report_printer.dart';
import 'package:learnhub/theme.dart';
import 'package:learnhub/widgets/common.dart';

/// Renders the report list card and review screen on small phones to catch layout overflows.
void main() {
  final pending = Report(
    id: 'r1',
    type: ReportType.message,
    reporterId: 'c1',
    reporterName: 'Maria Concepcion Villanueva-Santos',
    targetUserId: 't1',
    targetLabel: 'Juan Miguel Dela Cruz Bautista',
    orderId: 'abcdef123',
    messageText: 'This is the message that was reported by the client for being rude.',
    reason: 'The tutor was rude and kept asking for payment outside the app, which is against the rules.',
    createdAt: DateTime(2026, 10, 1, 9, 30),
  );
  final resolved = Report(
    id: 'r2',
    type: ReportType.profile,
    reporterId: 'c1',
    reporterName: 'Maria Concepcion Villanueva-Santos',
    targetUserId: 't1',
    targetLabel: 'Juan Miguel Dela Cruz Bautista',
    reason: 'Fake credentials.',
    status: 'resolved',
    decision: 'Account suspended',
    notes: 'Verified with the university registrar.',
    createdAt: DateTime(2026, 9, 20, 14),
    resolvedAt: DateTime(2026, 9, 21, 10),
  );

  Future<void> pumpAt(WidgetTester tester, double width, Widget home) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: home));
    await tester.pumpAndSettle();
    final error = tester.takeException();
    expect(error, isNull, reason: error is FlutterError ? error.toStringDeep() : '$error');
  }

  for (final width in [320.0, 412.0]) {
    testWidgets('report cards fit at ${width.toInt()}px wide', (tester) async {
      await pumpAt(
        tester,
        width,
        Scaffold(
          appBar: brandAppBar(
            title: 'Disputes & Reports',
            subtitle: 'Review flagged orders, profiles, and messages',
            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.print_outlined))],
          ),
          body: PageBody(children: [
            ReportCard(report: pending, onTap: () {}),
            ReportCard(report: resolved, onTap: () {}),
          ]),
        ),
      );
    });

    for (final r in [pending, resolved]) {
      testWidgets('review screen (${r.status}) fits at ${width.toInt()}px wide', (tester) async {
        await pumpAt(tester, width, ReportReviewScreen(report: r));
      });
    }

    testWidgets('report reason dialog fits with the keyboard open at ${width.toInt()}px wide', (tester) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => promptText(context, 'Report Juan Miguel Dela Cruz Bautista', 'Why are you reporting this profile?'),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      expect(error, isNull, reason: error is FlutterError ? error.toStringDeep() : '$error');
    });
  }

  test('report history and single report build printable PDFs', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final history = await ReportPrinter.buildHistoryPdf([pending, resolved, for (var i = 0; i < 40; i++) resolved]);
    final single = await ReportPrinter.buildReportPdf(pending);
    for (final pdf in [history, single]) {
      expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    }
  });
}
