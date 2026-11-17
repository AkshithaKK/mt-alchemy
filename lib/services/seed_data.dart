import '../models/course.dart';
import '../models/product.dart';
import 'firestore_service.dart';

/// Demo catalogue written for this project. Fixed document ids make seeding
/// safe to run more than once (it overwrites rather than duplicates).
const _courses = <String, Course>{
  'eq-fundamentals': Course(
    title: 'Emotional Intelligence Fundamentals',
    category: 'Emotional Intelligence',
    description:
        'Learn to notice, name and work with emotions so you can respond '
        'calmly and build stronger working relationships.',
    instructor: 'Mabel Tan KH',
    level: 'Beginner',
    audience: 'Professionals and team members at any level',
    durationHours: 3,
    price: 120,
    rating: 4.9,
    status: 'Published',
    passingScore: 70,
    objectives: [
      'Explain the four areas of emotional intelligence',
      'Recognise personal emotional triggers at work',
      'Use a simple pause routine before reacting',
    ],
    modules: [
      CourseModule(
        title: 'What emotional intelligence really means',
        type: 'video',
        minutes: 12,
        content:
            'Emotional intelligence is the skill of noticing emotions in '
            'ourselves and others and using that awareness to choose how we act. '
            'In this lesson we look at self-awareness, self-management, social '
            'awareness and relationship skills, and why each matters in a team.',
      ),
      CourseModule(
        title: 'Spotting your triggers',
        type: 'text',
        minutes: 15,
        content:
            'A trigger is a situation that produces a strong reaction before we '
            'have time to think. Common workplace triggers include unclear '
            'feedback, tight deadlines and feeling unheard. Keep a short log for '
            'one week: what happened, what you felt, and what you did next. '
            'Patterns appear quickly and give you a place to start.',
      ),
      CourseModule(
        title: 'The pause routine',
        type: 'text',
        minutes: 10,
        content:
            'Stop, breathe, name, choose. When you feel a spike, stop for a '
            'moment, take one slow breath, name the emotion in a word, then '
            'choose the response that fits your goal rather than the feeling.',
      ),
      CourseModule(
        title: 'Practice worksheet',
        type: 'pdf',
        minutes: 20,
        content:
            'Download the worksheet and complete the trigger log and pause '
            'routine plan before taking the quiz.',
      ),
    ],
    questions: [
      QuizQuestion(
        question: 'Which of these is NOT one of the four areas covered?',
        options: ['Self-awareness', 'Social awareness', 'Time management', 'Relationship skills'],
        answer: 2,
        explanation: 'Time management is useful, but it is not one of the four areas.',
      ),
      QuizQuestion(
        question: 'What is the first step of the pause routine?',
        options: ['Breathe', 'Stop', 'Name', 'Choose'],
        answer: 1,
        explanation: 'The routine is Stop, Breathe, Name, Choose.',
      ),
      QuizQuestion(
        question: 'Why keep a trigger log for a week?',
        options: [
          'To report colleagues',
          'To find patterns in your reactions',
          'To avoid difficult tasks',
          'To track working hours',
        ],
        answer: 1,
        explanation: 'The log reveals repeating situations you can prepare for.',
      ),
      QuizQuestion(
        question: 'Naming an emotion in one word helps because it…',
        options: [
          'Makes the emotion disappear',
          'Creates a little distance so you can choose a response',
          'Proves you are right',
          'Is required by HR',
        ],
        answer: 1,
        explanation: 'Labelling an emotion slows the reaction and gives you choice.',
      ),
    ],
  ),
  'mindful-leader': Course(
    title: 'The Mindful Leader',
    category: 'Leadership',
    description:
        'Practical habits that help team leads stay focused, listen well and '
        'make steady decisions under pressure.',
    instructor: 'Mabel Tan KH',
    level: 'Intermediate',
    audience: 'Supervisors, managers and new team leads',
    durationHours: 4,
    price: 180,
    rating: 4.8,
    status: 'Published',
    passingScore: 75,
    objectives: [
      'Run a focused one-to-one conversation',
      'Give feedback that is specific and kind',
      'Use a short reset practice between meetings',
    ],
    modules: [
      CourseModule(
        title: 'Leading from a steady place',
        type: 'video',
        minutes: 14,
        content:
            'Teams take their cue from the leader. This lesson shows how a calm '
            'leader lowers the temperature in a room and why that improves '
            'decision quality.',
      ),
      CourseModule(
        title: 'Listening that people notice',
        type: 'text',
        minutes: 12,
        content:
            'Put the screen away, summarise what you heard before you respond, '
            'and ask one open question. These three moves change how heard '
            'people feel within a single conversation.',
      ),
      CourseModule(
        title: 'Feedback that lands',
        type: 'text',
        minutes: 15,
        content:
            'Describe the situation, the specific behaviour, and its impact, then '
            'invite their view. Keep it about actions rather than personality.',
      ),
    ],
    questions: [
      QuizQuestion(
        question: 'What should you do before responding in a conversation?',
        options: ['Interrupt politely', 'Summarise what you heard', 'Check email', 'Change topic'],
        answer: 1,
        explanation: 'Summarising shows the other person they were understood.',
      ),
      QuizQuestion(
        question: 'Good feedback focuses on…',
        options: ['Personality', 'Specific behaviour and impact', 'Rumours', 'Past mistakes only'],
        answer: 1,
        explanation: 'Behaviour and impact are concrete and can be changed.',
      ),
      QuizQuestion(
        question: 'A calm leader mainly helps the team to…',
        options: ['Work longer hours', 'Make better decisions', 'Avoid meetings', 'Skip planning'],
        answer: 1,
        explanation: 'Lower stress in the room supports clearer thinking.',
      ),
    ],
  ),
  'team-engagement': Course(
    title: 'Building Engaged Teams',
    category: 'Team Effectiveness',
    description:
        'Tools to build trust, run better team check-ins and turn conflict '
        'into useful conversation.',
    instructor: 'MT Alchemy Facilitator',
    level: 'Intermediate',
    audience: 'Team leads and HR partners',
    durationHours: 2.5,
    price: 150,
    rating: 4.7,
    status: 'Published',
    passingScore: 70,
    objectives: [
      'Run a 10-minute weekly team check-in',
      'Recognise early signs of disengagement',
    ],
    modules: [
      CourseModule(
        title: 'What engagement looks like',
        type: 'text',
        minutes: 10,
        content:
            'Engaged people volunteer ideas, ask questions and help each other. '
            'Disengagement often shows first as silence in meetings.',
      ),
      CourseModule(
        title: 'The weekly check-in',
        type: 'video',
        minutes: 12,
        content:
            'A short structure: one win, one challenge, one request for help. '
            'Rotate who starts so every voice is heard.',
      ),
    ],
    questions: [
      QuizQuestion(
        question: 'An early sign of disengagement is often…',
        options: ['More questions', 'Silence in meetings', 'Helping others', 'Sharing ideas'],
        answer: 1,
      ),
      QuizQuestion(
        question: 'The check-in structure includes one win, one challenge and…',
        options: ['One complaint', 'One request for help', 'One deadline', 'One report'],
        answer: 1,
      ),
    ],
  ),
  'workplace-wellbeing': Course(
    title: 'Everyday Workplace Well-being',
    category: 'Workplace Well-being',
    description:
        'A free starter course with simple routines to manage stress and '
        'protect energy during a busy week.',
    instructor: 'MT Alchemy Facilitator',
    level: 'Beginner',
    audience: 'Anyone who wants a calmer working week',
    durationHours: 1,
    price: 0,
    rating: 4.6,
    status: 'Published',
    passingScore: 60,
    objectives: ['Use a two-minute breathing reset', 'Plan recovery breaks'],
    modules: [
      CourseModule(
        title: 'The two-minute reset',
        type: 'text',
        minutes: 6,
        content:
            'Breathe in for four counts, hold for four, out for six. Repeat for '
            'two minutes between tasks to settle your nervous system.',
      ),
      CourseModule(
        title: 'Planning recovery breaks',
        type: 'text',
        minutes: 8,
        content:
            'Schedule short breaks after demanding tasks, not just at lunch. '
            'Step away from the screen and move for a few minutes.',
      ),
    ],
    questions: [
      QuizQuestion(
        question: 'In the reset, the out-breath is…',
        options: ['Shorter than the in-breath', 'Longer than the in-breath', 'Skipped', 'Held'],
        answer: 1,
        explanation: 'A longer out-breath helps the body relax.',
      ),
      QuizQuestion(
        question: 'When are recovery breaks most useful?',
        options: ['Only at lunch', 'After demanding tasks', 'Never', 'Before leaving work'],
        answer: 1,
      ),
    ],
  ),
};

const _products = <String, Product>{
  'emotional-clarity-workbook': Product(
    title: 'Emotional Clarity Workbook',
    description:
        'A printable workbook of reflection prompts to understand your '
        'emotional patterns. Instant download after payment.',
    category: 'Workbooks',
    type: 'Digital',
    price: 29,
  ),
  'leadership-reflection-templates': Product(
    title: 'Leadership Reflection Templates',
    description:
        'Ready-to-use templates for one-to-ones, feedback notes and weekly '
        'reflection. Delivered as a PDF.',
    category: 'Templates',
    type: 'Digital',
    price: 19,
  ),
  'mindful-week-journal-digital': Product(
    title: 'Mindful Week Digital Journal',
    description: 'A seven-day guided journal for building a calmer routine.',
    category: 'Journals',
    type: 'Digital',
    price: 15,
  ),
  'printed-eq-workbook': Product(
    title: 'Printed EQ Workbook',
    description:
        'A bound, full-colour workbook used in our workshops. Shipped within '
        'Malaysia in 3 to 5 working days.',
    category: 'Workbooks',
    type: 'Physical',
    price: 59,
    stock: 40,
    weightKg: 0.6,
  ),
  'conversation-cards': Product(
    title: 'Team Conversation Cards',
    description:
        'A deck of 52 prompt cards to open honest team conversations and '
        'build trust in meetings.',
    category: 'Cards',
    type: 'Physical',
    price: 45,
    stock: 25,
    weightKg: 0.3,
  ),
  'workshop-learning-kit': Product(
    title: 'Workshop Learning Kit',
    description:
        'Everything a facilitator needs for a half-day team session: '
        'cards, worksheets and a facilitator guide.',
    category: 'Learning Kits',
    type: 'Physical',
    price: 160,
    stock: 10,
    weightKg: 1.5,
  ),
};

/// Writes the demo catalogue. Returns how many documents were written.
Future<int> seedDemoData() async {
  var count = 0;
  for (final e in _courses.entries) {
    await Db.col('courses').doc(e.key).set(e.value.toMap());
    count++;
  }
  for (final e in _products.entries) {
    await Db.col('products').doc(e.key).set(e.value.toMap());
    count++;
  }
  return count;
}
