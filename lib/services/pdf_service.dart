import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const _navy = PdfColor.fromInt(0xFF0B1426);
const _gold = PdfColor.fromInt(0xFFD8B56D);
const _grey = PdfColor.fromInt(0xFF666666);

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Builds PDFs on the device and hands them to the browser as a download.
class PdfService {
  static const verifyBase = 'https://mt-alchemy-client.web.app/#verify=';

  static Future<void> _share(pw.Document doc, String filename) async {
    await Printing.sharePdf(bytes: await doc.save(), filename: filename);
  }

  static Future<void> certificate({
    required String learner,
    required String course,
    required String instructor,
    required DateTime completedOn,
    required String certificateId,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(36),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _gold, width: 6),
          ),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('MT ALCHEMY',
                  style: pw.TextStyle(
                      color: _navy, fontSize: 30, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('CERTIFICATE OF COMPLETION',
                  style: const pw.TextStyle(color: _gold, fontSize: 16)),
              pw.SizedBox(height: 28),
              pw.Text('This certifies that', style: const pw.TextStyle(color: _grey)),
              pw.SizedBox(height: 10),
              pw.Text(learner,
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold, color: _navy)),
              pw.SizedBox(height: 10),
              pw.Text('has successfully completed', style: const pw.TextStyle(color: _grey)),
              pw.SizedBox(height: 10),
              pw.Text(course,
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Instructor: $instructor'),
                      pw.Text('Completed: ${_date(completedOn)}'),
                      pw.Text('Certificate ID: $certificateId'),
                    ],
                  ),
                  pw.Column(children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: '$verifyBase$certificateId',
                      width: 80,
                      height: 80,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Scan to verify',
                        style: const pw.TextStyle(fontSize: 9, color: _grey)),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await _share(doc, 'MT-Alchemy-Certificate-$certificateId.pdf');
  }

  /// The purchased digital product, personalised with the buyer's name.
  static Future<void> digitalProduct({
    required String title,
    required String description,
    required String buyer,
    required String orderNumber,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (c) => pw.Text(
          'Licensed to $buyer  |  Order $orderNumber  |  Page ${c.pageNumber}',
          style: const pw.TextStyle(fontSize: 9, color: _grey),
        ),
        build: (_) => [
          pw.Text('MT ALCHEMY',
              style: pw.TextStyle(color: _gold, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 26, color: _navy, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text(description),
          pw.SizedBox(height: 24),
          for (final prompt in const [
            'Reflection 1: Describe a recent moment when you felt under pressure. '
                'What did you notice in your body and thoughts?',
            'Reflection 2: Which emotion shows up most often for you at work, '
                'and what is it usually trying to tell you?',
            'Reflection 3: Write one small habit you will practise this week '
                'to respond rather than react.',
          ]) ...[
            pw.Text(prompt, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            for (var i = 0; i < 5; i++)
              pw.Container(
                height: 22,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: _grey, width: 0.5)),
                ),
              ),
            pw.SizedBox(height: 18),
          ],
        ],
      ),
    );
    await _share(doc, '${title.replaceAll(' ', '_')}.pdf');
  }

  /// Employer progress report exported from the corporate dashboard.
  static Future<void> employerReport({
    required String organization,
    required List<List<String>> rows,
    required Map<String, String> summary,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text('Learning Progress Report',
              style: pw.TextStyle(
                  fontSize: 22, color: _navy, fontWeight: pw.FontWeight.bold)),
          pw.Text('$organization  |  Generated ${_date(DateTime.now())}',
              style: const pw.TextStyle(color: _grey)),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              for (final e in summary.entries)
                pw.Text('${e.key}: ${e.value}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Employee', 'Department', 'Course', 'Progress', 'Status'],
            data: rows,
            headerStyle: pw.TextStyle(
                color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: _navy),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );
    await _share(doc, '${organization.replaceAll(' ', '_')}_progress_report.pdf');
  }
}
