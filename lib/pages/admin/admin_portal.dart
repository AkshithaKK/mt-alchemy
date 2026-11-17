import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../models/learning.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../services/seed_data.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';
import 'course_editor.dart';

/// Administrator portal, separate from the public pages.
class AdminPortal extends StatelessWidget {
  const AdminPortal({super.key});

  static const tabs = [
    (Icons.space_dashboard_outlined, 'Overview'),
    (Icons.school_outlined, 'Courses'),
    (Icons.inventory_2_outlined, 'Products'),
    (Icons.receipt_long_outlined, 'Orders'),
    (Icons.people_outline, 'Users'),
    (Icons.mark_email_unread_outlined, 'Enquiries'),
    (Icons.business_outlined, 'Organizations'),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Panel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Admin Portal',
                  style: TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.w800)),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final t in tabs) Tab(icon: Icon(t.$1), text: t.$2)],
            ),
            const SizedBox(height: 12),
            const SizedBox(
              height: 720,
              child: TabBarView(children: [
                _Overview(),
                _CoursesTab(),
                _ProductsTab(),
                _OrdersTab(),
                _UsersTab(),
                _EnquiriesTab(),
                _OrganizationsTab(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 12, children: [
            StreamView<List<Map<String, dynamic>>>(
              stream: Db.users(),
              builder: (_, u) =>
                  StatTile(label: 'Users', value: '${u.length}', icon: Icons.people_outline),
            ),
            StreamView<List<Course>>(
              stream: Db.allCourses(),
              builder: (_, c) =>
                  StatTile(label: 'Courses', value: '${c.length}', icon: Icons.school_outlined),
            ),
            StreamView<List<Product>>(
              stream: Db.allProducts(),
              builder: (_, p) => StatTile(
                  label: 'Products', value: '${p.length}', icon: Icons.inventory_2_outlined),
            ),
            StreamView<List<ShopOrder>>(
              stream: Db.allOrders(),
              builder: (_, o) {
                final revenue = o.where((x) => x.isPaid).fold<double>(0, (s, x) => s + x.total);
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  StatTile(label: 'Orders', value: '${o.length}', icon: Icons.receipt_long_outlined),
                  StatTile(label: 'Revenue', value: money(revenue), icon: Icons.payments_outlined),
                ]);
              },
            ),
            StreamView<List<Enquiry>>(
              stream: Db.enquiries(),
              builder: (_, e) => StatTile(
                  label: 'New enquiries',
                  value: '${e.where((x) => x.status == 'New').length}',
                  icon: Icons.mark_email_unread_outlined),
            ),
          ]),
          const SizedBox(height: 24),
          const SectionTitle('Demo data'),
          const Text(
            'Load the sample catalogue (4 courses with modules and quizzes, 6 products). '
            'Safe to run again: it overwrites the same records.',
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () async {
              try {
                final n = await seedDemoData();
                if (context.mounted) showSnack(context, 'Seeded $n records.');
              } catch (e) {
                if (context.mounted) showSnack(context, 'Seeding failed: $e');
              }
            },
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Seed demo data'),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Please confirm'),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger),
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _CoursesTab extends StatelessWidget {
  const _CoursesTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CourseEditorPage()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create course'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamView<List<Course>>(
            stream: Db.allCourses(),
            builder: (context, courses) => ListView(
              children: [
                for (final c in courses)
                  Card(
                    child: ListTile(
                      leading: Icon(c.icon, color: c.color),
                      title: Text(c.title),
                      subtitle: Text('${c.category} • ${c.isFree ? 'Free' : money(c.price)} • '
                          '${c.modules.length} modules • ${c.questions.length} questions'
                          '${c.trainerEmail.isEmpty ? '' : ' • trainer ${c.trainerEmail}'}'),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          StatusChip(c.status),
                          StreamView<List<Enrolment>>(
                            stream: Db.enrolmentsForCourse(c.id),
                            builder: (_, e) => Text('  ${e.length} enrolled  '),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => CourseEditorPage(course: c)),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await _confirm(context, 'Delete "${c.title}"?')) {
                                await Db.deleteCourse(c.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _ProductDialog(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add product'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamView<List<Product>>(
            stream: Db.allProducts(),
            builder: (context, products) => ListView(
              children: [
                for (final p in products)
                  Card(
                    child: ListTile(
                      leading: Icon(p.icon, color: p.color),
                      title: Text(p.title),
                      subtitle: Text('${p.type} • ${p.category} • ${money(p.price)}'
                          '${p.isDigital ? '' : ' • stock ${p.stock}'}'),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(p.status),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => _ProductDialog(product: p),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await _confirm(context, 'Delete "${p.title}"?')) {
                                await Db.deleteProduct(p.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;

  const _ProductDialog({this.product});

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _weight;
  late String _type;
  late String _category;
  late String _status;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _stock = TextEditingController(text: '${p?.stock ?? 0}');
    _weight = TextEditingController(text: '${p?.weightKg ?? 0}');
    _type = p?.type ?? 'Digital';
    _category = productCategories.contains(p?.category) ? p!.category : productCategories.first;
    _status = p?.status ?? 'Published';
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _price, _stock, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add product' : 'Edit product'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'Digital', child: Text('Digital')),
                      DropdownMenuItem(value: 'Physical', child: Text('Physical')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c in productCategories) DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price (RM)'),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Number' : null,
                  ),
                ),
                if (_type == 'Physical') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Whole number' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      decoration: const InputDecoration(labelText: 'Weight (kg)'),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Published', child: Text('Published')),
                  DropdownMenuItem(value: 'Draft', child: Text('Draft (hidden)')),
                ],
                onChanged: (v) => setState(() => _status = v!),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            await Db.saveProduct(Product(
              id: widget.product?.id ?? '',
              title: _title.text.trim(),
              description: _description.text.trim(),
              category: _category,
              type: _type,
              price: double.parse(_price.text),
              stock: _type == 'Physical' ? int.parse(_stock.text) : 0,
              weightKg: double.tryParse(_weight.text) ?? 0,
              status: _status,
            ));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return StreamView<List<ShopOrder>>(
      stream: Db.allOrders(),
      builder: (context, orders) {
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message: 'Orders placed in the store appear here.',
          );
        }
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: const [
              DataColumn(label: Text('Order')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Products')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Payment')),
              DataColumn(label: Text('Order status')),
            ], rows: [
              for (final o in orders)
                DataRow(cells: [
                  DataCell(Text('#${o.orderNumber}\n${shortDate(o.createdAt)}')),
                  DataCell(Text(o.userEmail)),
                  DataCell(SizedBox(
                    width: 220,
                    child: Text(o.items.map((i) => '${i.qty}× ${i.title}').join(', '),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Text(money(o.total))),
                  DataCell(StatusChip(o.paymentStatus)),
                  DataCell(
                    o.status == 'Cancelled'
                        ? const StatusChip('Cancelled')
                        : DropdownButton<String>(
                            value: o.flow.contains(o.status) ? o.status : o.flow.first,
                            items: [
                              for (final s in o.flow) DropdownMenuItem(value: s, child: Text(s)),
                            ],
                            onChanged: (s) => Db.updateOrder(o.id, {
                              'status': s,
                              // Marking a pending order as paid confirms the payment.
                              if (s != 'Pending' && o.paymentStatus == 'Pending')
                                'paymentStatus': 'Successful',
                            }),
                          ),
                  ),
                ]),
            ]),
          ),
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  static const roles = ['Individual', 'Employer', 'Trainer', 'Super Admin'];

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Map<String, dynamic>>>(
      stream: Db.users(),
      builder: (context, users) => SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Status')),
          ], rows: [
            for (final u in users)
              DataRow(cells: [
                DataCell(Text('${u['name'] ?? ''}')),
                DataCell(Text('${u['email'] ?? ''}')),
                DataCell(DropdownButton<String>(
                  value: roles.contains(u['role']) ? u['role'] as String : 'Individual',
                  items: [for (final r in roles) DropdownMenuItem(value: r, child: Text(r))],
                  onChanged: (r) => Db.updateUser(u['uid'] as String, {'role': r}),
                )),
                DataCell(Row(children: [
                  Switch(
                    value: (u['status'] ?? 'Active') == 'Active',
                    onChanged: (on) => Db.updateUser(
                        u['uid'] as String, {'status': on ? 'Active' : 'Inactive'}),
                  ),
                  Text('${u['status'] ?? 'Active'}'),
                ])),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _EnquiriesTab extends StatelessWidget {
  const _EnquiriesTab();

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Enquiry>>(
      stream: Db.enquiries(),
      builder: (context, list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.mark_email_unread_outlined,
            title: 'No enquiries yet',
            message: 'Messages from the Contact page appear here.',
          );
        }
        return ListView(
          children: [
            for (final e in list)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.mail_outline, color: navy),
                  title: Text('${e.name} • ${e.type}'),
                  subtitle: Text('${e.email}'
                      '${e.organization.isEmpty ? '' : ' • ${e.organization}'} • ${shortDate(e.createdAt)}'),
                  trailing: DropdownButton<String>(
                    value: enquiryStatuses.contains(e.status) ? e.status : 'New',
                    items: [
                      for (final s in enquiryStatuses) DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (s) => Db.setEnquiryStatus(e.id, s!),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.phone.isNotEmpty) Text('Phone: ${e.phone}'),
                    const SizedBox(height: 6),
                    Text(e.message, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OrganizationsTab extends StatelessWidget {
  const _OrganizationsTab();

  @override
  Widget build(BuildContext context) {
    return StreamView<List<Organization>>(
      stream: Db.organizations(),
      builder: (context, orgs) => orgs.isEmpty
          ? const EmptyState(
              icon: Icons.business_outlined,
              title: 'No organizations yet',
              message: 'Employer registrations create organizations automatically.',
            )
          : ListView(
              children: [
                for (final o in orgs)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.business, color: navy),
                      title: Text(o.name),
                      subtitle: Text('Reg. ${o.registrationNo} • ${o.industry} • '
                          'Contact ${o.contactPerson} (${o.email})'),
                      trailing: StreamView<List<Employee>>(
                        stream: Db.employees(o.id),
                        builder: (_, e) => Text('${e.length} employees'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
