// lib/features/transactions/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final double totalAmount;
  final double cashGiven;
  final double change;
  final DateTime timestamp;
  final List<dynamic> items;
  final String sellerId;

  TransactionModel({
    required this.id,
    required this.totalAmount,
    required this.cashGiven,
    required this.change,
    required this.timestamp,
    required this.items,
    required this.sellerId,
  });

  factory TransactionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0, // ✅
      cashGiven: (data['cashGiven'] as num?)?.toDouble() ?? 0.0, // ✅
      change: (data['change'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
