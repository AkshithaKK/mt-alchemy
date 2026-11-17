import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/learning.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

void openCertificate(BuildContext context, String courseId, {bool replace = false}) {
  final route = MaterialPageRoute<void>(
    builder: (_) => CertificatePage(courseId: courseId),
  );
  replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

class CertificatePage extends StatelessWidget {
  final String courseId;

  const CertificatePage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageScaffold(
      title: 'Certificate',
      maxWidth: 900,
      child: StreamView<Course?>(
        stream: Db.course(courseId),
        builder: (context, course) => StreamView<Enrolment?>(
          stream: Db.enrolment(app.uid, courseId),
          builder: (context, e) {
            if (course == null || e == null || !e.passed) {
              return const EmptyState(
                icon: Icons.workspace_premium_outlined,
                title: 'Certificate not available yet',
                message: 'Complete every module and pass the assessment to earn it.',
              );
            }
            final completedOn = e.completedAt ?? DateTime.now();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Congratulations!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: navy, fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: yellow, width: 6),
                  ),
                  child: Column(
                    children: [
                      const Text('MT ALCHEMY',
                          style: TextStyle(
                              color: navy, fontSize: 26, fontWeight: FontWeight.w900)),
                      const Text('CERTIFICATE OF COMPLETION',
                          style: TextStyle(color: yellow, letterSpacing: 2)),
                      const SizedBox(height: 22),
                      const Text('This certifies that'),
                      const SizedBox(height: 8),
                      Text(app.name,
                          style: const TextStyle(
                              color: navy, fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      const Text('has successfully completed'),
                      const SizedBox(height: 8),
                      Text(course.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 30,
                        runSpacing: 16,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Instructor: ${course.instructor}'),
                              Text('Completed: ${shortDate(completedOn)}'),
                              Text('Certificate ID: ${e.certificateId}'),
                              Text('Score: ${e.quizScore ?? '-'}%'),
                            ],
                          ),
                          Column(children: [
                            QrView(
                              data: '${PdfService.verifyBase}${e.certificateId}',
                              size: 96,
                            ),
                            const SizedBox(height: 4),
                            const Text('Scan to verify', style: TextStyle(fontSize: 11)),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: navy,
                      padding: const EdgeInsets.all(18),
                    ),
                    onPressed: () => PdfService.certificate(
                      learner: app.name,
                      course: course.title,
                      instructor: course.instructor,
                      completedOn: completedOn,
                      certificateId: e.certificateId,
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Certificate (PDF)'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Draws a QR code using the barcode package (no image assets needed).
class QrView extends StatelessWidget {
  final String data;
  final double size;

  const QrView({super.key, required this.data, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _QrPainter(data));
  }
}

class _QrPainter extends CustomPainter {
  final String data;

  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    for (final e in Barcode.qrCode().make(data, width: size.width, height: size.height)) {
      if (e is BarcodeBar && e.black) {
        canvas.drawRect(Rect.fromLTWH(e.left, e.top, e.width, e.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.data != data;
}
