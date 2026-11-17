import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course.dart';
import '../models/learning.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Single place for all Firestore reads and writes.
/// Pages never talk to Firestore directly, which keeps queries consistent
/// with the security rules in firestore.rules.
class Db {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> col(String name) =>
      _db.collection(name);

  static List<T> _sorted<T>(List<T> list, int Function(T a, T b) compare) =>
      list..sort(compare);

  // ---------------- Courses ----------------

  /// Public catalogue: only published courses (required by the rules for guests).
  static Stream<List<Course>> publishedCourses() => col('courses')
      .where('status', isEqualTo: 'Published')
      .snapshots()
      .map((s) => _sorted(s.docs.map(Course.fromDoc).toList(),
          (a, b) => a.title.compareTo(b.title)));

  static Stream<List<Course>> allCourses() => col('courses').snapshots().map(
      (s) => _sorted(s.docs.map(Course.fromDoc).toList(),
          (a, b) => a.title.compareTo(b.title)));

  static Stream<List<Course>> trainerCourses(String email) => col('courses')
      .where('trainerEmail', isEqualTo: email)
      .snapshots()
      .map((s) => s.docs.map(Course.fromDoc).toList());

  static Stream<Course?> course(String id) => col('courses')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Course.fromDoc(d) : null);

  static Future<void> saveCourse(Course c) => c.id.isEmpty
      ? col('courses').add(c.toMap())
      : col('courses').doc(c.id).set(c.toMap());

  static Future<void> deleteCourse(String id) => col('courses').doc(id).delete();

  // ---------------- Products ----------------

  static Stream<List<Product>> publishedProducts() => col('products')
      .where('status', isEqualTo: 'Published')
      .snapshots()
      .map((s) => _sorted(s.docs.map(Product.fromDoc).toList(),
          (a, b) => a.title.compareTo(b.title)));

  static Stream<List<Product>> allProducts() => col('products')
      .snapshots()
      .map((s) => _sorted(s.docs.map(Product.fromDoc).toList(),
          (a, b) => a.title.compareTo(b.title)));

  static Future<void> saveProduct(Product p) => p.id.isEmpty
      ? col('products').add(p.toMap())
      : col('products').doc(p.id).set(p.toMap());

  static Future<void> deleteProduct(String id) =>
      col('products').doc(id).delete();

  static Future<void> reduceStock(String productId, int qty) =>
      col('products').doc(productId).update({'stock': FieldValue.increment(-qty)});

  // ---------------- Orders ----------------

  static Future<String> createOrder(ShopOrder order) async {
    final ref = await col('orders').add(order.toMap());
    return ref.id;
  }

  static Stream<ShopOrder?> order(String id) => col('orders')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? ShopOrder.fromDoc(d) : null);

  static int _newestFirst(ShopOrder a, ShopOrder b) =>
      (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());

  static Stream<List<ShopOrder>> ordersForUser(String uid) => col('orders')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) =>
          _sorted(s.docs.map(ShopOrder.fromDoc).toList(), _newestFirst));

  static Stream<List<ShopOrder>> allOrders() => col('orders').snapshots().map(
      (s) => _sorted(s.docs.map(ShopOrder.fromDoc).toList(), _newestFirst));

  static Future<void> updateOrder(String id, Map<String, dynamic> data) =>
      col('orders').doc(id).update(data);

  // ---------------- Enrolments ----------------

  static Stream<Enrolment?> enrolment(String uid, String courseId) =>
      col('enrolments')
          .doc(Enrolment.idFor(uid, courseId))
          .snapshots()
          .map((d) => d.exists ? Enrolment.fromDoc(d) : null);

  static Future<void> enrol(Enrolment e) => col('enrolments')
      .doc(Enrolment.idFor(e.userId, e.courseId))
      .set(e.toMap());

  static Future<void> updateEnrolment(
          String uid, String courseId, Map<String, dynamic> data) =>
      col('enrolments').doc(Enrolment.idFor(uid, courseId)).update(data);

  static Stream<List<Enrolment>> enrolmentsForUser(String uid) =>
      col('enrolments')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((s) => s.docs.map(Enrolment.fromDoc).toList());

  static Stream<List<Enrolment>> enrolmentsForCourse(String courseId) =>
      col('enrolments')
          .where('courseId', isEqualTo: courseId)
          .snapshots()
          .map((s) => s.docs.map(Enrolment.fromDoc).toList());

  /// Firestore allows up to 30 values in a whereIn filter.
  static Stream<List<Enrolment>> enrolmentsForEmails(List<String> emails) {
    if (emails.isEmpty) return Stream.value(const []);
    return col('enrolments')
        .where('userEmail', whereIn: emails.take(30).toList())
        .snapshots()
        .map((s) => s.docs.map(Enrolment.fromDoc).toList());
  }

  // ---------------- Enquiries ----------------

  static Future<void> addEnquiry(Enquiry e) => col('enquiries').add(e.toMap());

  static Stream<List<Enquiry>> enquiries() => col('enquiries')
      .snapshots()
      .map((s) => _sorted(
          s.docs.map(Enquiry.fromDoc).toList(),
          (a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now())));

  static Future<void> setEnquiryStatus(String id, String status) =>
      col('enquiries').doc(id).update({'status': status});

  // ---------------- Users ----------------

  static Stream<List<Map<String, dynamic>>> users() => col('users')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'uid': d.id}).toList());

  static Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      col('users').doc(uid).update(data);

  // ---------------- Organisations ----------------

  static Stream<Organization?> organization(String ownerId) => col('organizations')
      .doc(ownerId)
      .snapshots()
      .map((d) => d.exists ? Organization.fromDoc(d) : null);

  static Future<void> saveOrganization(Organization o) =>
      col('organizations').doc(o.id).set(o.toMap());

  static Stream<List<Organization>> organizations() => col('organizations')
      .snapshots()
      .map((s) => s.docs.map(Organization.fromDoc).toList());

  static Stream<List<Employee>> employees(String orgId) => col('employees')
      .where('orgId', isEqualTo: orgId)
      .snapshots()
      .map((s) => _sorted(s.docs.map(Employee.fromDoc).toList(),
          (a, b) => a.name.compareTo(b.name)));

  static Future<void> addEmployee(Employee e) => col('employees').add(e.toMap());

  static Future<void> removeEmployee(String id) =>
      col('employees').doc(id).delete();

  static Future<void> addAssignment(Assignment a) =>
      col('assignments').add(a.toMap());

  static Stream<List<Assignment>> assignmentsForOrg(String orgId) =>
      col('assignments')
          .where('orgId', isEqualTo: orgId)
          .snapshots()
          .map((s) => s.docs.map(Assignment.fromDoc).toList());

  static Stream<List<Assignment>> assignmentsForEmail(String email) =>
      col('assignments')
          .where('employeeEmails', arrayContains: email)
          .snapshots()
          .map((s) => s.docs.map(Assignment.fromDoc).toList());
}
