import 'package:cloud_firestore/cloud_firestore.dart';

/// Links a learner to a course and tracks their progress.
/// Document id is `${userId}_${courseId}` so each learner has one per course.
class Enrolment {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String courseId;
  final String courseTitle;
  final int moduleCount;
  final double courseHours;
  final List<int> completed;
  final int? quizScore;
  final bool passed;
  final String certificateId;
  final String source; // Purchased, Free, Assigned
  final DateTime? enrolledAt;
  final DateTime? completedAt;

  const Enrolment({
    this.id = '',
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.courseId,
    required this.courseTitle,
    required this.moduleCount,
    this.courseHours = 1,
    this.completed = const [],
    this.quizScore,
    this.passed = false,
    this.certificateId = '',
    this.source = 'Purchased',
    this.enrolledAt,
    this.completedAt,
  });

  static String idFor(String userId, String courseId) => '${userId}_$courseId';

  /// Modules count as one step each and the quiz counts as the final step.
  int get progress {
    final steps = moduleCount + 1;
    final done = completed.length + (passed ? 1 : 0);
    return steps == 0 ? 0 : (done * 100 / steps).round().clamp(0, 100);
  }

  String get statusLabel => passed
      ? 'Completed'
      : completed.isEmpty
          ? 'Not started'
          : 'In Progress';

  factory Enrolment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Enrolment(
      id: doc.id,
      userId: (m['userId'] ?? '') as String,
      userEmail: (m['userEmail'] ?? '') as String,
      userName: (m['userName'] ?? '') as String,
      courseId: (m['courseId'] ?? '') as String,
      courseTitle: (m['courseTitle'] ?? '') as String,
      moduleCount: (m['moduleCount'] as num?)?.toInt() ?? 0,
      courseHours: (m['courseHours'] as num?)?.toDouble() ?? 1,
      completed: List<int>.from(
          (m['completed'] as List? ?? const []).map((e) => (e as num).toInt())),
      quizScore: (m['quizScore'] as num?)?.toInt(),
      passed: (m['passed'] ?? false) as bool,
      certificateId: (m['certificateId'] ?? '') as String,
      source: (m['source'] ?? 'Purchased') as String,
      enrolledAt: (m['enrolledAt'] as Timestamp?)?.toDate(),
      completedAt: (m['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'moduleCount': moduleCount,
        'courseHours': courseHours,
        'completed': completed,
        'quizScore': quizScore,
        'passed': passed,
        'certificateId': certificateId,
        'source': source,
        'enrolledAt': FieldValue.serverTimestamp(),
      };
}

class Organization {
  final String id; // same as the employer's user id
  final String name;
  final String registrationNo;
  final String industry;
  final int employeeCount;
  final String contactPerson;
  final String email;
  final String phone;

  const Organization({
    required this.id,
    required this.name,
    this.registrationNo = '',
    this.industry = '',
    this.employeeCount = 0,
    this.contactPerson = '',
    this.email = '',
    this.phone = '',
  });

  factory Organization.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Organization(
      id: doc.id,
      name: (m['name'] ?? '') as String,
      registrationNo: (m['registrationNo'] ?? '') as String,
      industry: (m['industry'] ?? '') as String,
      employeeCount: (m['employeeCount'] as num?)?.toInt() ?? 0,
      contactPerson: (m['contactPerson'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'registrationNo': registrationNo,
        'industry': industry,
        'employeeCount': employeeCount,
        'contactPerson': contactPerson,
        'email': email,
        'phone': phone,
        'ownerId': id,
      };
}

class Employee {
  final String id;
  final String orgId;
  final String name;
  final String email;
  final String department;

  const Employee({
    this.id = '',
    required this.orgId,
    required this.name,
    required this.email,
    required this.department,
  });

  factory Employee.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Employee(
      id: doc.id,
      orgId: (m['orgId'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      department: (m['department'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'name': name,
        'email': email.toLowerCase(),
        'department': department,
      };
}

class Assignment {
  final String id;
  final String orgId;
  final String orgName;
  final String courseId;
  final String courseTitle;
  final List<String> employeeEmails;
  final DateTime? deadline;

  const Assignment({
    this.id = '',
    required this.orgId,
    required this.orgName,
    required this.courseId,
    required this.courseTitle,
    required this.employeeEmails,
    this.deadline,
  });

  factory Assignment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Assignment(
      id: doc.id,
      orgId: (m['orgId'] ?? '') as String,
      orgName: (m['orgName'] ?? '') as String,
      courseId: (m['courseId'] ?? '') as String,
      courseTitle: (m['courseTitle'] ?? '') as String,
      employeeEmails: List<String>.from(m['employeeEmails'] ?? const []),
      deadline: (m['deadline'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'orgName': orgName,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'employeeEmails': employeeEmails,
        'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class Enquiry {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String organization;
  final String type;
  final String message;
  final String status; // New, Contacted, Consultation, Proposal Sent, Closed
  final DateTime? createdAt;

  const Enquiry({
    this.id = '',
    required this.name,
    required this.email,
    this.phone = '',
    this.organization = '',
    required this.type,
    required this.message,
    this.status = 'New',
    this.createdAt,
  });

  factory Enquiry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Enquiry(
      id: doc.id,
      name: (m['name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      organization: (m['organization'] ?? '') as String,
      type: (m['type'] ?? '') as String,
      message: (m['message'] ?? '') as String,
      status: (m['status'] ?? 'New') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'organization': organization,
        'type': type,
        'message': message,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

const enquiryTypes = [
  'Individual Coaching',
  'Corporate Training',
  'Leadership Development',
  'Team Development',
  'Products',
  'Partnership',
  'Other',
];

const enquiryStatuses = [
  'New',
  'Contacted',
  'Consultation',
  'Proposal Sent',
  'Closed',
];
