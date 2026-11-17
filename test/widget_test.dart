import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mt_alchemy/models/course.dart';
import 'package:mt_alchemy/models/learning.dart';
import 'package:mt_alchemy/models/product.dart';
import 'package:mt_alchemy/state/cart.dart';
import 'package:mt_alchemy/widgets/ui.dart';

void main() {
  const workbook = Product(id: 'w', title: 'Workbook', type: 'Digital', price: 29);
  const kit = Product(id: 'k', title: 'Kit', type: 'Physical', price: 160, stock: 5);

  group('Cart', () {
    test('digital-only cart has no shipping and no discount under RM150', () {
      final cart = Cart()..add(workbook, 2);
      expect(cart.count, 2);
      expect(cart.subtotal, 58);
      expect(cart.shipping, 0);
      expect(cart.discount, 0);
      expect(cart.total, 58);
    });

    test('physical item adds flat shipping and 10% discount from RM150', () {
      final cart = Cart()
        ..add(kit)
        ..add(workbook);
      expect(cart.hasPhysical, isTrue);
      expect(cart.subtotal, 189);
      expect(cart.discount, closeTo(18.9, 0.001));
      expect(cart.shipping, Cart.shippingFlatRate);
      expect(cart.total, closeTo(189 - 18.9 + 10, 0.001));
    });

    test('adding the same product merges quantity and setQty(0) removes it', () {
      final cart = Cart()
        ..add(workbook)
        ..add(workbook);
      expect(cart.items.length, 1);
      expect(cart.items.first.qty, 2);
      cart.setQty('w', 0);
      expect(cart.isEmpty, isTrue);
    });
  });

  group('Quiz grading', () {
    const questions = [
      QuizQuestion(question: 'A', options: ['x', 'y'], answer: 0),
      QuizQuestion(question: 'B', options: ['x', 'y'], answer: 1),
      QuizQuestion(question: 'C', options: ['x', 'y'], answer: 1),
      QuizQuestion(question: 'D', options: ['x', 'y'], answer: 0),
    ];

    test('scores correct answers and applies pass mark', () {
      final r = gradeQuiz(questions, [0, 1, 0, 0], 70);
      expect(r.correct, 3);
      expect(r.percent, 75);
      expect(r.passed, isTrue);
    });

    test('fails below the pass mark and treats blanks as wrong', () {
      final r = gradeQuiz(questions, [0, null, 0, 1], 70);
      expect(r.correct, 1);
      expect(r.passed, isFalse);
    });
  });

  test('enrolment progress counts modules plus the quiz', () {
    const e = Enrolment(
      userId: 'u',
      userEmail: 'a@b.com',
      userName: 'A',
      courseId: 'c',
      courseTitle: 'C',
      moduleCount: 3,
      completed: [0, 1],
    );
    expect(e.progress, 50);
    expect(e.statusLabel, 'In Progress');
  });

  testWidgets('StatusChip renders its label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StatusChip('Delivered'))),
    );
    expect(find.text('Delivered'), findsOneWidget);
  });
}
