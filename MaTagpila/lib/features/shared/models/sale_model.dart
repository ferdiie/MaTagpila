import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SoldItem extends Equatable {
  final String itemId;
  final int qty;
  final double priceAtSale;

  const SoldItem({
    required this.itemId,
    required this.qty,
    required this.priceAtSale,
  });

  factory SoldItem.fromMap(Map<String, dynamic> data) {
    return SoldItem(
      itemId: (data['itemId'] ?? '') as String,
      qty: (data['qty'] as num?)?.toInt() ?? 0,
      priceAtSale: (data['priceAtSale'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'qty': qty,
        'priceAtSale': priceAtSale,
      };

  @override
  List<Object?> get props => [itemId, qty, priceAtSale];
}

class SaleModel extends Equatable {
  final String id;
  final DateTime timestamp;
  final List<SoldItem> itemsSold;
  final double totalAmount;
  final String cashierId;

  const SaleModel({
    required this.id,
    required this.timestamp,
    required this.itemsSold,
    required this.totalAmount,
    required this.cashierId,
  });

  factory SaleModel.fromMap(Map<String, dynamic> data) {
    final soldRaw = (data['itemsSold'] as List<dynamic>? ?? []);
    final rawStamp = data['timestamp'];
    final timestamp = rawStamp is Timestamp
        ? rawStamp.toDate()
        : DateTime.tryParse(rawStamp?.toString() ?? '') ?? DateTime.now();

    return SaleModel(
      id: (data['id'] ?? '') as String,
      timestamp: timestamp,
      itemsSold: soldRaw
          .map((e) =>
              SoldItem.fromMap((e as Map<Object?, Object?>).cast<String, dynamic>()))
          .toList(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      cashierId: (data['cashierId'] ?? '') as String,
    );
  }

  factory SaleModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SaleModel.fromMap({
      ...?doc.data(),
      'id': doc.id,
    });
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': Timestamp.fromDate(timestamp),
        'itemsSold': itemsSold.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'cashierId': cashierId,
      };

  @override
  List<Object?> get props => [id, timestamp, itemsSold, totalAmount, cashierId];
}
