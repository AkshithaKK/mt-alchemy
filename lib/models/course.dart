import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// One unit of learning content inside a course.
/// [type] decides which viewer the course player uses (text, video, pdf).
class CourseModule {
  final String title;
  final String type;
  final String content;
  final int minutes;

  const CourseModule({
    required this.title,
    this.type = 'text',
    this.content = '',
    this.minutes = 10,
  });

  factory CourseModule.fromMap(Map<String, dynamic> m) => CourseModule(
        title: (m['title'] ?? '') as String,
        type: (m['type'] ?? 'text') as String,
        content: (m['content'] ?? '') as String,
        minutes: (m['minutes'] as num?)?.toInt() ?? 10,
      );

  Map<String, dynamic> toMap() =>
      {'title': title, 'type': type, 'content': content, 'minutes': minutes};
}

/// A multiple-choice question. [answer] is the index of the correct option.
class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    this.explanation = '',
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> m) => QuizQuestion(
        question: (m['question'] ?? '') as String,
        options: List<String>.from(m['options'] ?? const []),
        answer: (m['answer'] as num?)?.toInt() ?? 0,
        explanation: (m['explanation'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'question': question,
        'options': options,
        'answer': answer,
        'explanation': explanation,
      };
}

/// Result of marking a quiz attempt.
class QuizResult {
  final int correct;
  final int total;
  final int passingScore;

  const QuizResult(this.correct, this.total, this.passingScore);

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();
  bool get passed => percent >= passingScore;
}

/// Marks [answers] (selected option index per question, null = unanswered).
QuizResult gradeQuiz(
  List<QuizQuestion> questions,
  List<int?> answers,
  int passingScore,
) {
  var correct = 0;
  for (var i = 0; i < questions.length; i++) {
    if (i < answers.length && answers[i] == questions[i].answer) correct++;
  }
  return QuizResult(correct, questions.length, passingScore);
}

class Course {
  final String id;
  final String title;
  final String category;
  final String description;
  final String instructor;
  final String trainerEmail;
  final String level;
  final String audience;
  final double durationHours;
  final double price;
  final double rating;
  final String status; // Draft, Published, Archived
  final int passingScore;
  final List<String> objectives;
  final List<CourseModule> modules;
  final List<QuizQuestion> questions;

  const Course({
    this.id = '',
    required this.title,
    required this.category,
    this.description = '',
    this.instructor = '',
    this.trainerEmail = '',
    this.level = 'Beginner',
    this.audience = '',
    this.durationHours = 1,
    this.price = 0,
    this.rating = 4.8,
    this.status = 'Draft',
    this.passingScore = 70,
    this.objectives = const [],
    this.modules = const [],
    this.questions = const [],
  });

  IconData get icon => categoryVisual(category).icon;
  Color get color => categoryVisual(category).color;
  bool get isFree => price <= 0;

  factory Course.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Course(
      id: doc.id,
      title: (m['title'] ?? '') as String,
      category: (m['category'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      instructor: (m['instructor'] ?? '') as String,
      trainerEmail: (m['trainerEmail'] ?? '') as String,
      level: (m['level'] ?? 'Beginner') as String,
      audience: (m['audience'] ?? '') as String,
      durationHours: (m['durationHours'] as num?)?.toDouble() ?? 1,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      rating: (m['rating'] as num?)?.toDouble() ?? 4.8,
      status: (m['status'] ?? 'Draft') as String,
      passingScore: (m['passingScore'] as num?)?.toInt() ?? 70,
      objectives: List<String>.from(m['objectives'] ?? const []),
      modules: [
        for (final x in (m['modules'] as List? ?? const []))
          CourseModule.fromMap(Map<String, dynamic>.from(x as Map)),
      ],
      questions: [
        for (final x in (m['questions'] as List? ?? const []))
          QuizQuestion.fromMap(Map<String, dynamic>.from(x as Map)),
      ],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'description': description,
        'instructor': instructor,
        'trainerEmail': trainerEmail,
        'level': level,
        'audience': audience,
        'durationHours': durationHours,
        'price': price,
        'rating': rating,
        'status': status,
        'passingScore': passingScore,
        'objectives': objectives,
        'modules': modules.map((m) => m.toMap()).toList(),
        'questions': questions.map((q) => q.toMap()).toList(),
      };
}
