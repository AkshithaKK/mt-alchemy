import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/learning.dart';
import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import '../store/payment_page.dart';
import 'course_player.dart';

/// Grid of published courses with category filters.
class CourseCatalogue extends StatefulWidget {
  final Widget Function(Course course, VoidCallback onTap) cardBuilder;
  final int? limit;

  const CourseCatalogue({super.key, required this.cardBuilder, this.limit});

  @override
  State<CourseCatalogue> createState() => _CourseCatalogueState();
}

class _CourseCatalogueState extends State<CourseCatalogue> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Course>>(
      stream: Db.publishedCourses(),
      builder: (context, courses) {
        final categories = {'All', ...courses.map((c) => c.category)};
        var shown = courses
            .where((c) => _category == 'All' || c.category == _category)
            .toList();
        if (widget.limit != null) shown = shown.take(widget.limit!).toList();
        return Column(
          children: [
            if (widget.limit == null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
            const SizedBox(height: 20),
            if (shown.isEmpty)
              const EmptyState(
                icon: Icons.school_outlined,
                title: 'No courses published yet',
                message: 'Courses published from the admin portal will show here.',
              )
            else
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  for (final c in shown)
                    widget.cardBuilder(c, () => openCourse(context, c.id)),
                ],
              ),
          ],
        );
      },
    );
  }
}

void openCourse(BuildContext context, String courseId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CourseDetailPage(courseId: courseId)),
  );
}

class CourseDetailPage extends StatelessWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return PageScaffold(
      title: 'Course Detail',
      child: StreamView<Course?>(
        stream: Db.course(courseId),
        builder: (context, course) {
          if (course == null) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'Course not found',
              message: 'This course is no longer available.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(course: course),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, c) {
                final details = _Details(course: course);
                final action = app.isLoggedIn
                    ? StreamView<Enrolment?>(
                        stream: Db.enrolment(app.uid, course.id),
                        builder: (context, enrolment) =>
                            _EnrolPanel(course: course, enrolment: enrolment),
                      )
                    : Panel(
                        child: Column(children: [
                          Text(course.isFree ? 'Free' : money(course.price),
                              style: const TextStyle(
                                  fontSize: 28,
                                  color: navy,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => AppNav.go(context, 'Login'),
                            child: const Text('Sign in to enrol'),
                          ),
                        ]),
                      );
                if (c.maxWidth > 820) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: details),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: action),
                    ],
                  );
                }
                return Column(children: [action, const SizedBox(height: 16), details]);
              }),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Course course;

  const _Header({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navy, blue]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(course.icon, color: yellow, size: 44),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.category.toUpperCase(),
                    style: const TextStyle(
                        color: yellow, letterSpacing: 1.2, fontSize: 12)),
                const SizedBox(height: 6),
                Text(course.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'By ${course.instructor} • ${course.level} • '
                  '${course.durationHours} hours • ${course.modules.length} modules • '
                  '★ ${course.rating}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final Course course;

  const _Details({required this.course});

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('About this course'),
          Text(course.description, style: const TextStyle(height: 1.6)),
          if (course.audience.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Who it is for: ${course.audience}',
                style: const TextStyle(color: Colors.black54)),
          ],
          if (course.objectives.isNotEmpty) ...[
            const SectionTitle('What you will learn'),
            for (final o in course.objectives)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.check, color: success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(o)),
                ]),
              ),
          ],
          const SectionTitle('Curriculum'),
          for (var i = 0; i < course.modules.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: yellow.withValues(alpha: 0.2),
                child: Text('${i + 1}', style: const TextStyle(color: navy)),
              ),
              title: Text('Module ${i + 1}: ${course.modules[i].title}'),
              subtitle: Text(
                  '${course.modules[i].type.toUpperCase()} • ${course.modules[i].minutes} min'),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0x22168A79),
              child: Icon(Icons.quiz_outlined, color: success),
            ),
            title: const Text('Final assessment'),
            subtitle: Text('${course.questions.length} questions • '
                'pass mark ${course.passingScore}%'),
          ),
          const SizedBox(height: 8),
          const Row(children: [
            Icon(Icons.workspace_premium_outlined, color: yellow),
            SizedBox(width: 8),
            Text('Certificate of completion included'),
          ]),
        ],
      ),
    );
  }
}

class _EnrolPanel extends StatefulWidget {
  final Course course;
  final Enrolment? enrolment;

  const _EnrolPanel({required this.course, required this.enrolment});

  @override
  State<_EnrolPanel> createState() => _EnrolPanelState();
}

class _EnrolPanelState extends State<_EnrolPanel> {
  bool _busy = false;

  Future<void> _enrol({required String source}) async {
    final app = context.read<AppState>();
    final course = widget.course;

    if (source == 'Purchased') {
      final result = await openPayment(
        context,
        amount: course.price,
        description: 'Course enrolment: ${course.title}',
      );
      if (result == null || !mounted) return;
      // Keep a record of the course purchase alongside store orders.
      await Db.createOrder(ShopOrder(
        orderNumber: newOrderNumber(),
        userId: app.uid,
        userEmail: app.email,
        items: [
          OrderItem(
            productId: course.id,
            title: course.title,
            type: 'Course',
            price: course.price,
            qty: 1,
          ),
        ],
        subtotal: course.price,
        total: course.price,
        customer: {'name': app.name, 'email': app.email},
        paymentStatus: result.status.label,
        paymentRef: result.reference,
        status: result.status == PaymentStatus.successful
            ? 'Available'
            : result.status == PaymentStatus.pending
                ? 'Pending'
                : 'Cancelled',
      ));
      if (!mounted) return;
      if (result.status != PaymentStatus.successful) {
        showSnack(context, '${result.message} Enrolment opens once payment succeeds.');
        return;
      }
    }

    setState(() => _busy = true);
    try {
      await Db.enrol(Enrolment(
        userId: app.uid,
        userEmail: app.email,
        userName: app.name,
        courseId: course.id,
        courseTitle: course.title,
        moduleCount: course.modules.length,
        courseHours: course.durationHours,
        source: source,
      ));
      if (!mounted) return;
      showSnack(context, 'You are enrolled in ${course.title}.');
      openPlayer(context, course.id);
    } catch (e) {
      if (mounted) showSnack(context, 'Enrolment failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final course = widget.course;
    final enrolment = widget.enrolment;

    if (enrolment != null) {
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('You are enrolled',
                style: TextStyle(fontWeight: FontWeight.bold, color: navy, fontSize: 18)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: enrolment.progress / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text('Course Progress: ${enrolment.progress}%'),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: navy),
              onPressed: () => openPlayer(context, course.id),
              icon: const Icon(Icons.play_arrow),
              label: Text(enrolment.passed ? 'Review course' : 'Continue Course'),
            ),
          ],
        ),
      );
    }

    return StreamView(
      stream: Db.assignmentsForEmail(app.email),
      builder: (context, assignments) {
        final assigned = assignments.where((a) => a.courseId == course.id).firstOrNull;
        return Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(course.isFree ? 'Free' : money(course.price),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 30, color: navy, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              if (assigned != null) ...[
                Text('Assigned to you by ${assigned.orgName}'
                    '${assigned.deadline == null ? '' : ' • due ${shortDate(assigned.deadline)}'}',
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _busy ? null : () => _enrol(source: 'Assigned'),
                  child: const Text('Start assigned course'),
                ),
              ] else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: _busy
                      ? null
                      : () => _enrol(source: course.isFree ? 'Free' : 'Purchased'),
                  icon: const Icon(Icons.school),
                  label: Text(course.isFree ? 'Enrol for free' : 'Enrol now'),
                ),
              const SizedBox(height: 10),
              const Text(
                'Lifetime access • Quiz • Certificate',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }
}
