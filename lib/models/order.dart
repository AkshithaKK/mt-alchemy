import 'package:cloud_firestore/cloud_firestore.dart';

/// Order lifecycle used by the admin portal.
const physicalOrderFlow = ['Pending', 'Paid', 'Processing', 'Shipped', 'Delivered'];
const digitalOrderFlow = ['Pending', 'Paid', 'Available'];

class OrderItem {
  final String productId;
  final String title;
  final String type; // Digital, Physical or Course
  final double price;
  final int qty;

  const OrderItem({
    required this.productId,
    required this.title,
    required this.type,
    required this.price,
    required this.qty,
  });

  double get lineTotal => price * qty;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: (m['productId'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        type: (m['type'] ?? 'Digital') as String,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        qty: (m['qty'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'type': type,
        'price': price,
        'qty': qty,
      };
}

class ShopOrder {
  final String id;
  final String orderNumber;
  final String userId;
  final String userEmail;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final Map<String, dynamic> customer;
  final Map<String, dynamic> billing;
  final Map<String, dynamic>? shipping;
  final String paymentStatus; // Successful, Failed, Pending
  final String paymentRef;
  final String status;
  final DateTime? createdAt;

  const ShopOrder({
    this.id = '',
    required this.orderNumber,
    required this.userId,
    required this.userEmail,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.shippingFee = 0,
    required this.total,
    this.customer = const {},
    this.billing = const {},
    this.shipping,
    required this.paymentStatus,
    this.paymentRef = '',
    required this.status,
    this.createdAt,
  });

  bool get hasPhysical => items.any((i) => i.type == 'Physical');
  bool get isPaid => paymentStatus == 'Successful';
  List<String> get flow => hasPhysical ? physicalOrderFlow : digitalOrderFlow;

  factory ShopOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return ShopOrder(
      id: doc.id,
      orderNumber: (m['orderNumber'] ?? '') as String,
      userId: (m['userId'] ?? '') as String,
      userEmail: (m['userEmail'] ?? '') as String,
      items: [
        for (final x in (m['items'] as List? ?? const []))
          OrderItem.fromMap(Map<String, dynamic>.from(x as Map)),
      ],
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (m['discount'] as num?)?.toDouble() ?? 0,
      shippingFee: (m['shippingFee'] as num?)?.toDouble() ?? 0,
      total: (m['total'] as num?)?.toDouble() ?? 0,
      customer: Map<String, dynamic>.from(m['customer'] ?? const {}),
      billing: Map<String, dynamic>.from(m['billing'] ?? const {}),
      shipping: m['shipping'] == null
          ? null
          : Map<String, dynamic>.from(m['shipping'] as Map),
      paymentStatus: (m['paymentStatus'] ?? 'Pending') as String,
      paymentRef: (m['paymentRef'] ?? '') as String,
      status: (m['status'] ?? 'Pending') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'orderNumber': orderNumber,
        'userId': userId,
        'userEmail': userEmail,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'shippingFee': shippingFee,
        'total': total,
        'customer': customer,
        'billing': billing,
        'shipping': shipping,
        'paymentStatus': paymentStatus,
        'paymentRef': paymentRef,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Human-friendly order number such as MA482913.
String newOrderNumber() =>
    'MA${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
