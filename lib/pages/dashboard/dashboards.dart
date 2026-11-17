import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/learning.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../../services/pdf_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import '../admin/admin_portal.dart';
import '../admin/course_editor.dart';
import '../learning/certificate_page.dart';
import '../learning/course_pages.dart';
import '../learning/course_player.dart';
import '../store/order_pages.dart';
import '../store/payment_page.dart';

/// Picks the dashboard for the signed-in role.
class RoleDashboard extends StatelessWidget {
  final String role;
  final ValueChanged<String> onNavigate;

  const RoleDashboard({super.key, required this.role, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'Super Admin':
        return const AdminPortal();
      case 'Employer':
        return EmployerDashboard(onNavigate: onNavigate);
      case 'Trainer':
        return const TrainerDashboard();
      default:
        return LearnerDashboard(onNavigate: onNavigate);
    }
  }
}

// ======================= INDIVIDUAL LEARNER =======================

class LearnerDashboard extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const LearnerDashboard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome, ${app.name}',
            style: const TextStyle(color: navy, fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        StreamView<List<Enrolment>>(
          stream: Db.enrolmentsForUser(app.uid),
          builder: (context, enrolments) {
            final completed = enrolments.where((e) => e.passed).toList();
            final inProgress = enrolments.where((e) => !e.passed).toList();
            final hours = completed.fold<double>(0, (s, e) => s + e.courseHours);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  StatTile(label: 'Courses enrolled', value: '${enrolments.length}', icon: Icons.school_outlined),
                  StatTile(label: 'In progress', value: '${inProgress.length}', icon: Icons.timelapse),
                  StatTile(label: 'Completed', value: '${completed.length}', icon: Icons.task_alt),
                  StatTile(label: 'Certificates', value: '${completed.length}', icon: Icons.workspace_premium_outlined),
                  StatTile(label: 'Learning hours', value: hours.toStringAsFixed(1), icon: Icons.schedule),
                ]),
                const SizedBox(height: 24),
                _AssignedToMe(enrolledIds: enrolments.map((e) => e.courseId).toSet()),
                SectionTitle(
                  'My Learning',
                  trailing: TextButton(
                    onPressed: () => onNavigate('Upskilling'),
                    child: const Text('Browse courses'),
                  ),
                ),
                if (enrolments.isEmpty)
                  Panel(
                    child: EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No courses yet',
                      message: 'Enrol in a course to start learning.',
                      action: FilledButton(
                        onPressed: () => onNavigate('Upskilling'),
                        child: const Text('Explore the Learning Hub'),
                      ),
                    ),
                  ),
                for (final e in enrolments)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(e.courseTitle,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, color: navy, fontSize: 16)),
                                ),
                                StatusChip(e.statusLabel),
                              ]),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: e.progress / 100,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 6),
                              Text('${e.courseTitle} — ${e.progress}%',
                                  style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        e.passed
                            ? OutlinedButton.icon(
                                onPressed: () => openCertificate(context, e.courseId),
                                icon: const Icon(Icons.workspace_premium),
                                label: const Text('Certificate'),
                              )
                            : FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: navy),
                                onPressed: () => openPlayer(context, e.courseId),
                                child: const Text('Continue Course'),
                              ),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
        const SectionTitle('My Orders & Profile'),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _QuickAction(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyOrdersPage())),
          ),
          _QuickAction(
            icon: Icons.cloud_download_outlined,
            label: 'My Digital Products',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DigitalLibraryPage())),
          ),
          _QuickAction(
            icon: Icons.manage_accounts_outlined,
            label: 'Edit Profile',
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const ProfileDialog(),
            ),
          ),
          _QuickAction(
            icon: Icons.storefront_outlined,
            label: 'Shop',
            onTap: () => onNavigate('Store'),
          ),
        ]),
      ],
    );
  }
}

class _AssignedToMe extends StatelessWidget {
  final Set<String> enrolledIds;

  const _AssignedToMe({required this.enrolledIds});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return StreamView<List<Assignment>>(
      stream: Db.assignmentsForEmail(app.email),
      builder: (context, list) {
        final pending = list.where((a) => !enrolledIds.contains(a.courseId)).toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Assigned to you'),
            for (final a in pending)
              Card(
                color: yellow.withValues(alpha: 0.12),
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined, color: navy),
                  title: Text(a.courseTitle),
                  subtitle: Text('From ${a.orgName}'
                      '${a.deadline == null ? '' : ' • due ${shortDate(a.deadline)}'}'),
                  trailing: FilledButton(
                    onPressed: () => openCourse(context, a.courseId),
                    child: const Text('Start'),
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Icon(icon, color: navy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Lets any user edit their name, phone and preferences, or reset password.
class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _name = TextEditingController(text: app.name);
    _phone = TextEditingController(text: (app.profile?['phone'] ?? '') as String);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(app.email),
              subtitle: const Text('Email used to sign in'),
            ),
            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: app.email);
                if (context.mounted) showSnack(context, 'Password reset email sent.');
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text('Send password reset email'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            await Db.updateUser(app.uid, {
              'name': _name.text.trim(),
              'phone': _phone.text.trim(),
            });
            await app.refreshProfile();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ======================= EMPLOYER =======================

class EmployerDashboard extends StatelessWidget {
  final ValueChanged<String> onNavigate;

  const EmployerDashboard({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return StreamView<Organization?>(
      stream: Db.organization(app.uid),
      builder: (context, org) {
        if (org == null) return _OrgSetup(ownerId: app.uid);
        return StreamView<List<Employee>>(
          stream: Db.employees(org.id),
          builder: (context, employees) => StreamView<List<Assignment>>(
            stream: Db.assignmentsForOrg(org.id),
            builder: (context, assignments) => StreamView<List<Enrolment>>(
              stream: Db.enrolmentsForEmails(employees.map((e) => e.email).toList()),
              builder: (context, enrolments) => _EmployerBody(
                org: org,
                employees: employees,
                assignments: assignments,
                enrolments: enrolments,
                onNavigate: onNavigate,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportRow {
  final Employee employee;
  final Assignment assignment;
  final Enrolment? enrolment;

  _ReportRow(this.employee, this.assignment, this.enrolment);

  int get progress => enrolment?.progress ?? 0;
  String get status => enrolment == null ? 'Not started' : enrolment!.statusLabel;
}

class _EmployerBody extends StatelessWidget {
  final Organization org;
  final List<Employee> employees;
  final List<Assignment> assignments;
  final List<Enrolment> enrolments;
  final ValueChanged<String> onNavigate;

  const _EmployerBody({
    required this.org,
    required this.employees,
    required this.assignments,
    required this.enrolments,
    required this.onNavigate,
  });

  List<_ReportRow> get rows {
    final out = <_ReportRow>[];
    for (final a in assignments) {
      for (final email in a.employeeEmails) {
        final emp = employees.where((e) => e.email == email).firstOrNull;
        if (emp == null) continue;
        final enr = enrolments
            .where((e) => e.userEmail == email && e.courseId == a.courseId)
            .firstOrNull;
        out.add(_ReportRow(emp, a, enr));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final r = rows;
    final completed = r.where((x) => x.enrolment?.passed ?? false).length;
    final active = r.where((x) => x.enrolment != null).map((x) => x.employee.email).toSet().length;
    final hours = r
        .where((x) => x.enrolment?.passed ?? false)
        .fold<double>(0, (s, x) => s + (x.enrolment?.courseHours ?? 0));
    final rate = r.isEmpty ? 0 : (completed * 100 / r.length).round();
    final scores = r.map((x) => x.enrolment?.quizScore).whereType<int>().toList();
    final avgScore = scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Organization: ${org.name}',
            style: const TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.w800)),
        Text('${org.industry.isEmpty ? 'Industry not set' : org.industry} • Reg. ${org.registrationNo}',
            style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          StatTile(label: 'Total employees', value: '${employees.length}', icon: Icons.people_outline),
          StatTile(label: 'Active learners', value: '$active', icon: Icons.person_search_outlined),
          StatTile(label: 'Courses assigned', value: '${assignments.length}', icon: Icons.assignment_outlined),
          StatTile(label: 'Completion rate', value: '$rate%', icon: Icons.pie_chart_outline),
          StatTile(label: 'Certificates earned', value: '$completed', icon: Icons.workspace_premium_outlined),
          StatTile(label: 'Learning hours', value: hours.toStringAsFixed(1), icon: Icons.schedule),
          StatTile(label: 'Pending assignments', value: '${r.length - completed}', icon: Icons.pending_actions),
          StatTile(label: 'Average score', value: '$avgScore%', icon: Icons.grade_outlined),
        ]),
        const SectionTitle('Quick actions'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: navy),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _AddEmployeeDialog(orgId: org.id),
            ),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add Employee'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: navy),
            onPressed: employees.isEmpty
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AssignCoursePage(org: org, employees: employees),
                    )),
            icon: const Icon(Icons.assignment_add),
            label: const Text('Purchase & Assign Course'),
          ),
          OutlinedButton.icon(
            onPressed: r.isEmpty
                ? null
                : () => PdfService.employerReport(
                      organization: org.name,
                      summary: {
                        'Employees': '${employees.length}',
                        'Assignments': '${r.length}',
                        'Completion': '$rate%',
                        'Average score': '$avgScore%',
                        'Learning hours': hours.toStringAsFixed(1),
                      },
                      rows: [
                        for (final x in r)
                          [
                            x.employee.name,
                            x.employee.department,
                            x.assignment.courseTitle,
                            '${x.progress}%',
                            x.status,
                          ],
                      ],
                    ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export Report (PDF)'),
          ),
          OutlinedButton.icon(
            onPressed: () => onNavigate('Upskilling'),
            icon: const Icon(Icons.school_outlined),
            label: const Text('Browse Courses'),
          ),
        ]),
        const SectionTitle('Learning progress'),
        Panel(
          padding: const EdgeInsets.all(8),
          child: r.isEmpty
              ? const EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No assignments yet',
                  message: 'Add employees, then assign a course to track progress here.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: const [
                    DataColumn(label: Text('Employee')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('Course')),
                    DataColumn(label: Text('Progress')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Deadline')),
                  ], rows: [
                    for (final x in r)
                      DataRow(cells: [
                        DataCell(Text(x.employee.name)),
                        DataCell(Text(x.employee.department)),
                        DataCell(Text(x.assignment.courseTitle)),
                        DataCell(SizedBox(
                          width: 120,
                          child: Row(children: [
                            Expanded(child: LinearProgressIndicator(value: x.progress / 100)),
                            const SizedBox(width: 6),
                            Text('${x.progress}%'),
                          ]),
                        )),
                        DataCell(StatusChip(x.status)),
                        DataCell(Text(shortDate(x.assignment.deadline))),
                      ]),
                  ]),
                ),
        ),
        const SectionTitle('Employees'),
        Panel(
          padding: const EdgeInsets.all(8),
          child: employees.isEmpty
              ? const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No employees added',
                  message: 'Use "Add Employee" to build your team list. Employees sign up '
                      'with the same email to see their assigned courses.',
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Department')),
                    DataColumn(label: Text('')),
                  ], rows: [
                    for (final e in employees)
                      DataRow(cells: [
                        DataCell(Text(e.name)),
                        DataCell(Text(e.email)),
                        DataCell(Text(e.department)),
                        DataCell(IconButton(
                          tooltip: 'Remove employee',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => Db.removeEmployee(e.id),
                        )),
                      ]),
                  ]),
                ),
        ),
      ],
    );
  }
}

const departments = ['HR', 'Management', 'Finance', 'Sales', 'Operations', 'IT'];

class _AddEmployeeDialog extends StatefulWidget {
  final String orgId;

  const _AddEmployeeDialog({required this.orgId});

  @override
  State<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _dept = departments.first;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add employee'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Work email'),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                  ? null
                  : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _dept,
              decoration: const InputDecoration(labelText: 'Department'),
              items: [for (final d in departments) DropdownMenuItem(value: d, child: Text(d))],
              onChanged: (v) => setState(() => _dept = v ?? _dept),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            await Db.addEmployee(Employee(
              orgId: widget.orgId,
              name: _name.text.trim(),
              email: _email.text.trim().toLowerCase(),
              department: _dept,
            ));
            if (context.mounted) {
              Navigator.pop(context);
              showSnack(context, 'Employee added.');
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Course → Employees → Deadline → Pay for seats → Assign.
class AssignCoursePage extends StatefulWidget {
  final Organization org;
  final List<Employee> employees;

  const AssignCoursePage({super.key, required this.org, required this.employees});

  @override
  State<AssignCoursePage> createState() => _AssignCoursePageState();
}

class _AssignCoursePageState extends State<AssignCoursePage> {
  Course? _course;
  final Set<String> _selected = {};
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  bool _busy = false;

  Future<void> _assign() async {
    final course = _course!;
    final seats = _selected.length;
    final amount = course.price * seats;
    if (amount > 0) {
      final result = await openPayment(
        context,
        amount: amount,
        description: '$seats seat(s) for ${course.title}',
      );
      if (result == null || !mounted) return;
      if (result.status != PaymentStatus.successful) {
        showSnack(context, result.message);
        return;
      }
    }
    setState(() => _busy = true);
    await Db.addAssignment(Assignment(
      orgId: widget.org.id,
      orgName: widget.org.name,
      courseId: course.id,
      courseTitle: course.title,
      employeeEmails: _selected.toList(),
      deadline: _deadline,
    ));
    if (!mounted) return;
    showSnack(context, 'Course assigned to $seats employee(s). They will see it on their dashboard.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final byDept = <String, List<Employee>>{};
    for (final e in widget.employees) {
      byDept.putIfAbsent(e.department, () => []).add(e);
    }
    return PageScaffold(
      title: 'Assign a Course',
      maxWidth: 760,
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('1. Choose a course'),
            StreamView<List<Course>>(
              stream: Db.publishedCourses(),
              builder: (context, courses) => DropdownButtonFormField<String>(
                initialValue: _course?.id,
                hint: const Text('Select course'),
                items: [
                  for (final c in courses)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.title} (${c.isFree ? 'Free' : money(c.price)}/seat)'),
                    ),
                ],
                onChanged: (id) =>
                    setState(() => _course = courses.firstWhere((c) => c.id == id)),
              ),
            ),
            const SectionTitle('2. Choose employees'),
            for (final entry in byDept.entries) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${entry.key} department',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                value: entry.value.every((e) => _selected.contains(e.email)),
                onChanged: (on) => setState(() {
                  for (final e in entry.value) {
                    on == true ? _selected.add(e.email) : _selected.remove(e.email);
                  }
                }),
              ),
              for (final e in entry.value)
                CheckboxListTile(
                  contentPadding: const EdgeInsets.only(left: 28),
                  title: Text(e.name),
                  subtitle: Text(e.email),
                  value: _selected.contains(e.email),
                  onChanged: (on) => setState(() =>
                      on == true ? _selected.add(e.email) : _selected.remove(e.email)),
                ),
            ],
            const SectionTitle('3. Deadline'),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
              icon: const Icon(Icons.event),
              label: Text(shortDate(_deadline)),
            ),
            const SizedBox(height: 20),
            if (_course != null)
              Text(
                'Total: ${_selected.length} seat(s) × ${money(_course!.price)} = '
                '${money(_course!.price * _selected.length)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                padding: const EdgeInsets.all(18),
              ),
              onPressed: _course == null || _selected.isEmpty || _busy ? null : _assign,
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Assign Course'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrgSetup extends StatefulWidget {
  final String ownerId;

  const _OrgSetup({required this.ownerId});

  @override
  State<_OrgSetup> createState() => _OrgSetupState();
}

class _OrgSetupState extends State<_OrgSetup> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _reg = TextEditingController();
  final _industry = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _reg.dispose();
    _industry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Panel(
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Set up your organization'),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Organization name'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reg,
            decoration: const InputDecoration(labelText: 'Company registration no.'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _industry,
            decoration: const InputDecoration(labelText: 'Industry'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              await Db.saveOrganization(Organization(
                id: widget.ownerId,
                name: _name.text.trim(),
                registrationNo: _reg.text.trim(),
                industry: _industry.text.trim(),
                contactPerson: app.name,
                email: app.email,
              ));
            },
            child: const Text('Create organization'),
          ),
        ]),
      ),
    );
  }
}

// ======================= TRAINER =======================

class TrainerDashboard extends StatelessWidget {
  const TrainerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return StreamView<List<Course>>(
      stream: Db.trainerCourses(app.email),
      builder: (context, courses) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome, ${app.name}',
                style: const TextStyle(color: navy, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Courses assigned to you, your learners and their assessment results.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const Panel(
                child: EmptyState(
                  icon: Icons.co_present_outlined,
                  title: 'No courses assigned yet',
                  message: 'An administrator assigns courses to trainers by email '
                      'in the admin portal.',
                ),
              ),
            for (final c in courses)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(c.icon, color: c.color, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(c.title,
                              style: const TextStyle(
                                  color: navy, fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        StatusChip(c.status),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CourseEditorPage(course: c, trainerMode: true),
                          )),
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Manage materials'),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      StreamView<List<Enrolment>>(
                        stream: Db.enrolmentsForCourse(c.id),
                        builder: (context, learners) => learners.isEmpty
                            ? const Text('No learners enrolled yet.',
                                style: TextStyle(color: Colors.black54))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(columns: const [
                                  DataColumn(label: Text('Learner')),
                                  DataColumn(label: Text('Progress')),
                                  DataColumn(label: Text('Quiz score')),
                                  DataColumn(label: Text('Status')),
                                ], rows: [
                                  for (final l in learners)
                                    DataRow(cells: [
                                      DataCell(Text(l.userName.isEmpty ? l.userEmail : l.userName)),
                                      DataCell(Text('${l.progress}%')),
                                      DataCell(Text(l.quizScore == null ? '-' : '${l.quizScore}%')),
                                      DataCell(StatusChip(l.statusLabel)),
                                    ]),
                                ]),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
