// lib/features/shared/models/price_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PriceItem extends Equatable {
  final String id;
  final String name;
  final String nameLower;
  final double price;
  final String unit;
  final String category;
  final String store;
  final String addedBy;
  final String? barcode;
  final String? imageUrl;
  final DateTime updatedAt;
  final DateTime createdAt;

  const PriceItem({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.price,
    required this.unit,
    required this.category,
    required this.store,
    required this.addedBy,
    this.barcode,
    this.imageUrl,
    required this.updatedAt,
    required this.createdAt,
  });

  factory PriceItem.fromMap(String id, Map<String, dynamic> data) {
    DateTime toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return PriceItem(
      id: id,
      name: (data['name'] ?? '') as String,
      nameLower: (data['nameLower'] ?? '') as String,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      unit: (data['unit'] ?? 'pc') as String,
      category: (data['category'] ?? 'General') as String,
      store: (data['store'] ?? '') as String,
      addedBy: (data['addedBy'] ?? '') as String,
      barcode: data['barcode'] as String?,
      imageUrl: data['imageUrl'] as String?,
      updatedAt: toDate(data['updatedAt']),
      createdAt: toDate(data['createdAt']),
    );
  }

  factory PriceItem.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return PriceItem.fromMap(doc.id, doc.data() ?? {});
  }

  @override
  List<Object?> get props =>
      [id, name, price, unit, category, store, addedBy, updatedAt];
}
