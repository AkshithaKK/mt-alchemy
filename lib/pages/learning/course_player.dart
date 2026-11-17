import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/learning.dart';
import '../../services/firestore_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'certificate_page.dart';
import 'quiz_page.dart';

void openPlayer(BuildContext context, String courseId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => CoursePlayerPage(courseId: courseId)),
  );
}

/// Viewers for each module content type. Add a new entry here to support a
/// new type (audio, slides...) without touching the player itself.
final Map<String, Widget Function(CourseModule module)> moduleViewers = {
  'text': (m) => Text(m.content, style: const TextStyle(fontSize: 16, height: 1.7)),
  'video': (m) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [navy, blue]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, color: yellow, size: 72),
                  SizedBox(height: 8),
                  Text('Video lesson', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(m.content, style: const TextStyle(fontSize: 16, height: 1.7)),
        ],
      ),
  'pdf': (m) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: danger.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.picture_as_pdf, color: danger, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Text('${m.title}.pdf\nReading / worksheet resource',
                    style: const TextStyle(height: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text(m.content, style: const TextStyle(fontSize: 16, height: 1.7)),
        ],
      ),
};

class CoursePlayerPage extends StatefulWidget {
  final String courseId;

  const CoursePlayerPage({super.key, required this.courseId});

  @override
  State<CoursePlayerPage> createState() => _CoursePlayerPageState();
}

class _CoursePlayerPageState extends State<CoursePlayerPage> {
  int? _current;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return StreamView<Course?>(
      stream: Db.course(widget.courseId),
      builder: (context, course) {
        if (course == null) {
          return const Scaffold(body: Center(child: Text('Course not found')));
        }
        return StreamView<Enrolment?>(
          stream: Db.enrolment(app.uid, course.id),
          builder: (context, enrolment) {
            if (enrolment == null) {
              return Scaffold(
                appBar: AppBar(title: Text(course.title)),
                body: const Center(child: Text('Please enrol in this course first.')),
              );
            }
            return _buildPlayer(context, course, enrolment);
          },
        );
      },
    );
  }

  Widget _buildPlayer(BuildContext context, Course course, Enrolment e) {
    final modules = course.modules;
    final firstOpen = List.generate(modules.length, (i) => i)
        .firstWhere((i) => !e.completed.contains(i), orElse: () => 0);
    final current = (_current ?? firstOpen).clamp(0, modules.isEmpty ? 0 : modules.length - 1);
    final allDone = e.completed.length >= modules.length;
    final wide = MediaQuery.sizeOf(context).width > 900;

    final moduleList = Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Course modules',
                style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
          ),
          for (var i = 0; i < modules.length; i++)
            ListTile(
              dense: true,
              selected: i == current,
              selectedTileColor: yellow.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: Icon(
                e.completed.contains(i)
                    ? Icons.check_box
                    : i == current
                        ? Icons.play_arrow
                        : Icons.radio_button_unchecked,
                color: e.completed.contains(i) ? success : navy,
              ),
              title: Text('Module ${i + 1}'),
              subtitle: Text(modules[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => setState(() => _current = i),
            ),
          ListTile(
            dense: true,
            leading: Icon(e.passed ? Icons.check_box : Icons.quiz_outlined,
                color: e.passed ? success : navy),
            title: const Text('Final assessment'),
            subtitle: Text(allDone ? 'Ready' : 'Complete all modules first'),
            onTap: allDone ? () => _openQuiz(context, course) : null,
          ),
        ],
      ),
    );

    final module = modules.isEmpty ? null : modules[current];
    final viewer = module == null
        ? const Text('This course has no modules yet.')
        : (moduleViewers[module.type] ?? moduleViewers['text']!)(module);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (module != null) ...[
                Text('MODULE ${current + 1} OF ${modules.length} • ${module.minutes} MIN',
                    style: const TextStyle(color: Colors.black54, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(module.title,
                    style: const TextStyle(
                        color: navy, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
              ],
              viewer,
            ],
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Course Progress: ${e.progress}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: e.progress / 100,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: current > 0 ? () => setState(() => _current = current - 1) : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: success),
                    onPressed: module == null || e.completed.contains(current)
                        ? null
                        : () => _markComplete(course, e, current),
                    icon: const Icon(Icons.check),
                    label: Text(e.completed.contains(current) ? 'Completed' : 'Mark Complete'),
                  ),
                  if (current < modules.length - 1)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _current = current + 1),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    )
                  else if (e.passed)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: navy),
                      onPressed: () => openCertificate(context, course.id),
                      icon: const Icon(Icons.workspace_premium),
                      label: const Text('Certificate'),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: navy),
                      onPressed: allDone ? () => _openQuiz(context, course) : null,
                      icon: const Icon(Icons.quiz),
                      label: const Text('Take Quiz'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 300, child: moduleList),
                      const SizedBox(width: 20),
                      Expanded(child: content),
                    ],
                  )
                : Column(children: [content, const SizedBox(height: 16), moduleList]),
          ),
        ),
      ),
    );
  }

  Future<void> _markComplete(Course course, Enrolment e, int index) async {
    final app = context.read<AppState>();
    final completed = {...e.completed, index}.toList()..sort();
    await Db.updateEnrolment(app.uid, course.id, {'completed': completed});
    if (!mounted) return;
    if (index < course.modules.length - 1) {
      setState(() => _current = index + 1);
    } else {
      showSnack(context, 'All modules complete. You can now take the quiz.');
    }
  }

  void _openQuiz(BuildContext context, Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuizPage(course: course)),
    );
  }
}
