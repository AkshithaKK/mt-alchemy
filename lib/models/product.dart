import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
String productImage(String title) {
  switch (title) {
    case 'Emotional Clarity Workbook':
      return 'assets/images/photo13.jpg';
    case 'Leadership Reflection Templates':
      return 'assets/images/photo14.jpg';
    case 'Mindful Week Digital Journal':
      return 'assets/images/photo15.jpg';
    case 'Printed EQ Workbook':
      return 'assets/images/photo16.jpg';
    case 'Team Conversation Cards':
      return 'assets/images/photo17.jpg';
    case 'Workshop Learning Kit':
      return 'assets/images/photo18.jpg';
    default:
      return 'assets/images/resources.jpg';
  }
}
class Product {
  final String id;
  final String title;
  final String description;
  final String category;
  final String type; // Digital or Physical
  final double price;
  final int stock;
  final double weightKg;
  final String status; // Published or Draft

  const Product({
    this.id = '',
    required this.title,
    this.description = '',
    this.category = 'Workbooks',
    this.type = 'Digital',
    this.price = 0,
    this.stock = 0,
    this.weightKg = 0,
    this.status = 'Published',
  });

  bool get isDigital => type == 'Digital';
  bool get inStock => isDigital || stock > 0;
  IconData get icon => categoryVisual(category).icon;
  Color get color => categoryVisual(category).color;

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return Product(
      id: doc.id,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      category: (m['category'] ?? 'Workbooks') as String,
      type: (m['type'] ?? 'Digital') as String,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      stock: (m['stock'] as num?)?.toInt() ?? 0,
      weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0,
      status: (m['status'] ?? 'Published') as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'type': type,
        'price': price,
        'stock': stock,
        'weightKg': weightKg,
        'status': status,
      };
}
