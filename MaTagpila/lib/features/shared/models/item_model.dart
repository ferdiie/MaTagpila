import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PriceHistoryEntry extends Equatable {
  final DateTime date;
  final double price;

  const PriceHistoryEntry({
    required this.date,
    required this.price,
  });

  factory PriceHistoryEntry.fromMap(Map<String, dynamic> data) {
    final rawDate = data['date'];
    final date = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

    return PriceHistoryEntry(
      date: date,
      price: (data['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'price': price,
      };

  @override
  List<Object?> get props => [date, price];
}

class ItemModel extends Equatable {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final int stockQty;
  final String category;
  final List<PriceHistoryEntry> priceHistory;

  const ItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stockQty,
    required this.category,
    required this.priceHistory,
  });

  factory ItemModel.fromMap(Map<String, dynamic> data) {
    final historyRaw = (data['priceHistory'] as List<dynamic>? ?? []);
    return ItemModel(
      id: (data['id'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0,
      stockQty: (data['stockQty'] as num?)?.toInt() ?? 0,
      category: (data['category'] ?? 'Uncategorized') as String,
      priceHistory: historyRaw
          .map((entry) => PriceHistoryEntry.fromMap(
              (entry as Map<Object?, Object?>).cast<String, dynamic>()))
          .toList(),
    );
  }

  factory ItemModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ItemModel.fromMap({
      ...?doc.data(),
      'id': doc.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'stockQty': stockQty,
      'category': category,
      'priceHistory': priceHistory.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props =>
      [id, name, price, costPrice, stockQty, category, priceHistory];
}
