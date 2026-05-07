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
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      cashGiven: (data['cashGiven'] ?? 0.0).toDouble(),
      change: (data['change'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: data['items'] ?? [],
      sellerId: data['sellerId'] ?? '',
    );
  }
}
