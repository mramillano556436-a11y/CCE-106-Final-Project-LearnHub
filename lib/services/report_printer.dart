import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report.dart';
import '../utils/format.dart';

/// Builds printable PDFs of reports and sends them to the system print dialog
/// (which also offers "Save as PDF").
class ReportPrinter {
  static const _primary = PdfColor.fromInt(0xFF1F64C8);
  static const _ink = PdfColor.fromInt(0xFF132238);
  static const _muted = PdfColor.fromInt(0xFF6A7A92);
  static const _border = PdfColor.fromInt(0xFFDDE6F3);
  static const _tint = PdfColor.fromInt(0xFFE9F1FD);

  /// Prints every report as a table, with pending/resolved totals.
  static Future<void> printHistory(List<Report> reports) => Printing.layoutPdf(
        name: 'LearnHub report history ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        onLayout: (format) => buildHistoryPdf(reports, format: format.landscape),
      );

  /// Prints a single report with its resolution.
  static Future<void> printReport(Report report) => Printing.layoutPdf(
        name: 'LearnHub report ${report.id}',
        onLayout: (format) => buildReportPdf(report, format: format),
      );

  static Future<Uint8List> buildHistoryPdf(List<Report> reports, {PdfPageFormat format = PdfPageFormat.a4}) async {
    final doc = pw.Document(theme: await _theme(), title: 'LearnHub Report History', author: 'LearnHub');
    final pending = reports.where((r) => r.isPending).length;
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => _header('Report History'),
      footer: _footer,
      build: (_) => [
        pw.Row(children: [
          _stat('Total reports', '${reports.length}'),
          pw.SizedBox(width: 10),
          _stat('Pending', '$pending'),
          pw.SizedBox(width: 10),
          _stat('Resolved', '${reports.length - pending}'),
        ]),
        pw.SizedBox(height: 16),
        if (reports.isEmpty)
          pw.Text('No reports.', style: const pw.TextStyle(color: _muted))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Report', 'Reported by', 'Reported user', 'Reason', 'Status', 'Decision', 'Resolved'],
            data: [
              for (final r in reports)
                [
                  formatDate(r.createdAt),
                  r.title,
                  r.reporterName,
                  r.targetLabel,
                  r.reason,
                  _capitalize(r.status),
                  r.decision.isEmpty ? '—' : r.decision,
                  r.isPending ? '—' : formatDate(r.resolvedAt),
                ],
            ],
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(1.6),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(2.6),
              5: pw.FlexColumnWidth(0.9),
              6: pw.FlexColumnWidth(1.4),
              7: pw.FlexColumnWidth(1.1),
            },
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: _primary),
            cellStyle: const pw.TextStyle(fontSize: 8.5, color: _ink),
            cellAlignment: pw.Alignment.topLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            oddRowDecoration: const pw.BoxDecoration(color: _tint),
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _border, width: 0.5),
              bottom: pw.BorderSide(color: _border, width: 0.5),
            ),
          ),
      ],
    ));
    return doc.save();
  }

  static Future<Uint8List> buildReportPdf(Report r, {PdfPageFormat format = PdfPageFormat.a4}) async {
    final doc = pw.Document(theme: await _theme(), title: r.title, author: 'LearnHub');
    doc.addPage(pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(40),
      header: (_) => _header('Report: ${r.title}'),
      footer: _footer,
      build: (_) => [
        _section('Details'),
        _field('Status', _capitalize(r.status)),
        _field('Reported by', '${r.reporterName} · ${formatDateTime(r.createdAt)}'),
        _field('Reported user', r.targetLabel),
        if (r.orderId.isNotEmpty) _field('Order', orderNumber(r.orderId)),
        _field('Reason', r.reason),
        if (r.messageText.isNotEmpty) _field('Reported message', '"${r.messageText}"'),
        pw.SizedBox(height: 10),
        _section('Resolution'),
        if (r.isPending)
          _field('Decision', 'Pending review')
        else ...[
          _field('Decision', r.decision),
          if (r.notes.isNotEmpty) _field('Notes', r.notes),
          _field('Resolved', formatDateTime(r.resolvedAt)),
        ],
      ],
    ));
    return doc.save();
  }

  // ---------------------------------------------------------------- helpers

  /// The app font, so names with accents or non-Latin letters print correctly.
  static Future<pw.ThemeData> _theme() async {
    Future<pw.Font> font(int weight) async =>
        pw.Font.ttf(await rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'));
    return pw.ThemeData.withFont(base: await font(400), bold: await font(700));
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static pw.Widget _header(String title) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 16),
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2))),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('LearnHub',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primary)),
                pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink)),
              ]),
            ),
            pw.Text('Printed ${formatDateTime(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      );

  static pw.Widget _footer(pw.Context context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _muted)),
      );

  static pw.Widget _stat(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: _tint, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _ink)),
          ]),
        ),
      );

  static pw.Widget _section(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(title, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _primary)),
      );

  static pw.Widget _field(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(width: 110, child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _muted))),
          pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 11, color: _ink))),
        ]),
      );
}
