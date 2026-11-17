import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Create / edit a course with its modules and quiz.
/// Trainers use the same screen in [trainerMode], which hides pricing,
/// publishing and trainer assignment (admin-only fields).
class CourseEditorPage extends StatefulWidget {
  final Course? course;
  final bool trainerMode;

  const CourseEditorPage({super.key, this.course, this.trainerMode = false});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _ModuleDraft {
  final title = TextEditingController();
  final content = TextEditingController();
  final minutes = TextEditingController(text: '10');
  String type = 'text';
}

class _QuestionDraft {
  final question = TextEditingController();
  final options = TextEditingController();
  final explanation = TextEditingController();
  int answer = 0;
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _instructor = TextEditingController();
  final _trainerEmail = TextEditingController();
  final _audience = TextEditingController();
  final _duration = TextEditingController(text: '1');
  final _price = TextEditingController(text: '0');
  final _passing = TextEditingController(text: '70');
  final _objectives = TextEditingController();
  String _category = courseCategories.first;
  String _level = 'Beginner';
  String _status = 'Draft';
  final List<_ModuleDraft> _modules = [];
  final List<_QuestionDraft> _questions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    if (c == null) {
      _modules.add(_ModuleDraft());
      return;
    }
    _title.text = c.title;
    _description.text = c.description;
    _instructor.text = c.instructor;
    _trainerEmail.text = c.trainerEmail;
    _audience.text = c.audience;
    _duration.text = '${c.durationHours}';
    _price.text = c.price.toStringAsFixed(2);
    _passing.text = '${c.passingScore}';
    _objectives.text = c.objectives.join('\n');
    _category = courseCategories.contains(c.category) ? c.category : courseCategories.first;
    _level = c.level;
    _status = c.status;
    for (final m in c.modules) {
      _modules.add(_ModuleDraft()
        ..title.text = m.title
        ..content.text = m.content
        ..minutes.text = '${m.minutes}'
        ..type = m.type);
    }
    for (final q in c.questions) {
      _questions.add(_QuestionDraft()
        ..question.text = q.question
        ..options.text = q.options.join(' | ')
        ..explanation.text = q.explanation
        ..answer = q.answer);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final course = Course(
      id: widget.course?.id ?? '',
      title: _title.text.trim(),
      category: _category,
      description: _description.text.trim(),
      instructor: _instructor.text.trim(),
      trainerEmail: _trainerEmail.text.trim().toLowerCase(),
      level: _level,
      audience: _audience.text.trim(),
      durationHours: double.tryParse(_duration.text) ?? 1,
      price: double.tryParse(_price.text) ?? 0,
      rating: widget.course?.rating ?? 4.8,
      status: _status,
      passingScore: int.tryParse(_passing.text) ?? 70,
      objectives: _objectives.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      modules: [
        for (final m in _modules)
          CourseModule(
            title: m.title.text.trim(),
            type: m.type,
            content: m.content.text.trim(),
            minutes: int.tryParse(m.minutes.text) ?? 10,
          ),
      ],
      questions: [
        for (final q in _questions)
          QuizQuestion(
            question: q.question.text.trim(),
            options: q.options.text
                .split('|')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            answer: q.answer,
            explanation: q.explanation.text.trim(),
          ),
      ],
    );
    try {
      await Db.saveCourse(course);
      if (!mounted) return;
      showSnack(context, 'Course saved.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showSnack(context, 'Save failed: $e');
      }
    }
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final admin = !widget.trainerMode;
    return PageScaffold(
      title: widget.course == null ? 'New Course' : 'Edit Course',
      maxWidth: 900,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: yellow, foregroundColor: navy),
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Panel(
              child: Column(children: [
                TextFormField(
                  controller: _title,
                  enabled: admin,
                  decoration: const InputDecoration(labelText: 'Course title'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in courseCategories)
                          DropdownMenuItem(value: c, child: Text(c)),
                      ],
                      onChanged: admin ? (v) => setState(() => _category = v!) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _level,
                      decoration: const InputDecoration(labelText: 'Level'),
                      items: [
                        for (final l in const ['Beginner', 'Intermediate', 'Advanced'])
                          DropdownMenuItem(value: l, child: Text(l)),
                      ],
                      onChanged: (v) => setState(() => _level = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instructor,
                      decoration: const InputDecoration(labelText: 'Instructor name'),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _trainerEmail,
                      enabled: admin,
                      decoration: const InputDecoration(labelText: 'Assigned trainer email'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _audience,
                  decoration: const InputDecoration(labelText: 'Target audience'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      decoration: const InputDecoration(labelText: 'Duration (hours)'),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      enabled: admin,
                      decoration: const InputDecoration(labelText: 'Price (RM, 0 = free)'),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _passing,
                      decoration: const InputDecoration(labelText: 'Pass mark (%)'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 0 || n > 100 ? '0 to 100' : null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final s in const ['Draft', 'Published', 'Archived'])
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: admin ? (v) => setState(() => _status = v!) : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _objectives,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Learning objectives (one per line)',
                    alignLabelWithHint: true,
                  ),
                ),
              ]),
            ),
            SectionTitle(
              'Modules',
              trailing: TextButton.icon(
                onPressed: () => setState(() => _modules.add(_ModuleDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Add module'),
              ),
            ),
            for (var i = 0; i < _modules.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Column(children: [
                    Row(children: [
                      Text('Module ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove module',
                        onPressed: () => setState(() => _modules.removeAt(i)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ]),
                    Row(children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _modules[i].title,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _modules[i].type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'text', child: Text('Text')),
                            DropdownMenuItem(value: 'video', child: Text('Video')),
                            DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                          ],
                          onChanged: (v) => setState(() => _modules[i].type = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _modules[i].minutes,
                          decoration: const InputDecoration(labelText: 'Minutes'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _modules[i].content,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Lesson content',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ]),
                ),
              ),
            SectionTitle(
              'Quiz questions',
              trailing: TextButton.icon(
                onPressed: () => setState(() => _questions.add(_QuestionDraft())),
                icon: const Icon(Icons.add),
                label: const Text('Add question'),
              ),
            ),
            for (var i = 0; i < _questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Column(children: [
                    Row(children: [
                      Text('Question ${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: navy)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove question',
                        onPressed: () => setState(() => _questions.removeAt(i)),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ]),
                    TextFormField(
                      controller: _questions[i].question,
                      decoration: const InputDecoration(labelText: 'Question'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _questions[i].options,
                      decoration: const InputDecoration(
                        labelText: 'Options, separated by |  (e.g. True | False)',
                      ),
                      validator: (v) => (v ?? '').split('|').where((s) => s.trim().isNotEmpty).length < 2
                          ? 'Give at least two options'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<int>(
                          initialValue: _questions[i].answer,
                          decoration: const InputDecoration(labelText: 'Correct option'),
                          items: [
                            for (var k = 0; k < 6; k++)
                              DropdownMenuItem(value: k, child: Text('Option ${k + 1}')),
                          ],
                          onChanged: (v) => setState(() => _questions[i].answer = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _questions[i].explanation,
                          decoration: const InputDecoration(labelText: 'Explanation'),
                        ),
                      ),
                    ]),
                  ]),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.all(18)),
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save course'),
            ),
          ],
        ),
      ),
    );
  }
}
