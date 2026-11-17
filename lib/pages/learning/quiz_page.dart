import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'certificate_page.dart';

String newCertificateId() =>
    'MTA-${DateTime.now().year}-${Random().nextInt(899999) + 100000}';

class QuizPage extends StatefulWidget {
  final Course course;

  const QuizPage({super.key, required this.course});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late List<int?> _answers;
  int _index = 0;
  QuizResult? _result;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _answers = List<int?>.filled(widget.course.questions.length, null);
    _index = 0;
    _result = null;
  }

  Future<void> _submit() async {
    final course = widget.course;
    final result = gradeQuiz(course.questions, _answers, course.passingScore);
    setState(() {
      _result = result;
      _saving = true;
    });
    final app = context.read<AppState>();
    final data = <String, dynamic>{'quizScore': result.percent};
    if (result.passed) {
      data['passed'] = true;
      data['certificateId'] = newCertificateId();
      data['completedAt'] = FieldValue.serverTimestamp();
    }
    try {
      await Db.updateEnrolment(app.uid, course.id, data);
    } catch (e) {
      if (mounted) showSnack(context, 'Could not save your result: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final questions = course.questions;
    if (questions.isEmpty) {
      return const PageScaffold(
        title: 'Assessment',
        child: EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No questions yet',
          message: 'The trainer has not added an assessment to this course.',
        ),
      );
    }
    return PageScaffold(
      title: 'Assessment: ${course.title}',
      maxWidth: 760,
      child: _result == null ? _questionView(questions) : _resultView(questions),
    );
  }

  Widget _questionView(List<QuizQuestion> questions) {
    final q = questions[_index];
    final answered = _answers.where((a) => a != null).length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Question ${_index + 1} of ${questions.length}',
              style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: answered / questions.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 20),
          Text(q.question,
              style: const TextStyle(
                  color: navy, fontSize: 21, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          for (var i = 0; i < q.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _answers[_index] == i ? navy : borderColor,
                  ),
                ),
                tileColor: _answers[_index] == i ? yellow.withValues(alpha: 0.15) : null,
                leading: Icon(
                  _answers[_index] == i
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: navy,
                ),
                title: Text(q.options[i]),
                onTap: () => setState(() => _answers[_index] = i),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: _index > 0 ? () => setState(() => _index--) : null,
                child: const Text('Back'),
              ),
              const Spacer(),
              if (_index < questions.length - 1)
                FilledButton(
                  onPressed: _answers[_index] == null ? null : () => setState(() => _index++),
                  child: const Text('Next question'),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: success),
                  onPressed: _answers.contains(null) ? null : _submit,
                  child: const Text('Submit'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultView(List<QuizQuestion> questions) {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          color: (r.passed ? success : danger).withValues(alpha: 0.07),
          child: Column(children: [
            Icon(r.passed ? Icons.emoji_events : Icons.refresh,
                size: 56, color: r.passed ? success : danger),
            const SizedBox(height: 8),
            Text(r.passed ? 'Well done, you passed!' : 'Not quite there yet',
                style: const TextStyle(
                    color: navy, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Score: ${r.correct} / ${r.total} (${r.percent}%) • '
                'Pass mark ${r.passingScore}%'),
            const SizedBox(height: 16),
            if (r.passed)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: navy),
                onPressed: _saving
                    ? null
                    : () => openCertificate(context, widget.course.id, replace: true),
                icon: const Icon(Icons.workspace_premium),
                label: const Text('View Certificate'),
              )
            else
              FilledButton.icon(
                onPressed: () => setState(_reset),
                icon: const Icon(Icons.replay),
                label: const Text('Retake Assessment'),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        const SectionTitle('Review answers'),
        for (var i = 0; i < questions.length; i++)
          Card(
            child: ListTile(
              leading: Icon(
                _answers[i] == questions[i].answer ? Icons.check_circle : Icons.cancel,
                color: _answers[i] == questions[i].answer ? success : danger,
              ),
              title: Text(questions[i].question),
              subtitle: Text(
                'Correct answer: ${questions[i].options[questions[i].answer]}'
                '${questions[i].explanation.isEmpty ? '' : '\n${questions[i].explanation}'}',
              ),
            ),
          ),
      ],
    );
  }
}
