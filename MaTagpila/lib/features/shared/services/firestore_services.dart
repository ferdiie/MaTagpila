import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/app_user.dart';
import '../models/item_model.dart';
import '../models/sale_model.dart';

part 'firestore_services.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) =>
    FirebaseFirestore.instance;

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

@riverpod
Stream<AppUser?> currentAppUser(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final authChanges = ref.watch(authStateChangesProvider);

  return authChanges.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      return firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) => doc.exists ? AppUser.fromSnapshot(doc) : null);
    },
    error: (_, __) => Stream.value(null),
    loading: () => Stream.value(null),
  );
}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService(this._auth, this._firestore);

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<AppUser?> loadCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (!userDoc.exists) return null;
    return AppUser.fromSnapshot(userDoc);
  }
}

@riverpod
AuthService authService(Ref ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firebaseFirestoreProvider),
  );
}

class ItemsService {
  final FirebaseFirestore _firestore;

  ItemsService(this._firestore);

  Stream<List<ItemModel>> watchItems() {
    return _firestore.collection('items').snapshots().map(
          (snapshot) => snapshot.docs.map(ItemModel.fromSnapshot).toList(),
        );
  }
}

@riverpod
ItemsService itemsService(Ref ref) {
  return ItemsService(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<ItemModel>> itemsStream(Ref ref) {
  return ref.watch(itemsServiceProvider).watchItems();
}

class PosCheckoutItem {
  final String itemId;
  final int qty;
  final double priceAtSale;

  const PosCheckoutItem({
    required this.itemId,
    required this.qty,
    required this.priceAtSale,
  });
}

class PosService {
  final FirebaseFirestore _firestore;

  PosService(this._firestore);

  Future<void> checkout({
    required String cashierId,
    required List<PosCheckoutItem> items,
  }) async {
    if (items.isEmpty) {
      throw Exception('Cart is empty.');
    }

    final salesCollection = _firestore.collection('sales');
    final itemsCollection = _firestore.collection('items');
    final saleRef = salesCollection.doc();

    await _firestore.runTransaction((transaction) async {
      double totalAmount = 0;
      final soldItems = <SoldItem>[];

      for (final line in items) {
        final itemRef = itemsCollection.doc(line.itemId);
        final itemSnapshot = await transaction.get(itemRef);

        if (!itemSnapshot.exists) {
          throw Exception('Item not found: ${line.itemId}');
        }

        final item = ItemModel.fromSnapshot(itemSnapshot);
        if (item.stockQty < line.qty) {
          throw Exception('Insufficient stock for ${item.name}');
        }

        transaction.update(itemRef, {
          'stockQty': item.stockQty - line.qty,
        });

        soldItems.add(
          SoldItem(
            itemId: line.itemId,
            qty: line.qty,
            priceAtSale: line.priceAtSale,
          ),
        );
        totalAmount += line.qty * line.priceAtSale;
      }

      final sale = SaleModel(
        id: saleRef.id,
        timestamp: DateTime.now(),
        itemsSold: soldItems,
        totalAmount: totalAmount,
        cashierId: cashierId,
      );

      transaction.set(saleRef, sale.toMap());
    });
  }
}

@riverpod
PosService posService(Ref ref) {
  return PosService(ref.watch(firebaseFirestoreProvider));
}
