// lib/features/shared/services/firestore_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/price_item_model.dart';
import '../../transactions/models/transaction_model.dart';

part 'firestore_services.g.dart';

// ─────────────────────────────────────────────
//  FIREBASE INSTANCES
// ─────────────────────────────────────────────
@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) => FirebaseFirestore.instance;

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

// ─────────────────────────────────────────────
//  AUTH SERVICE
// ─────────────────────────────────────────────
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  User? get currentUser => _auth.currentUser;
  String get currentUserEmail => _auth.currentUser?.email ?? '';
  String get currentUserId => _auth.currentUser?.uid ?? '';

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> signUp(
      {required String email, required String password}) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}

@riverpod
AuthService authService(Ref ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
}

// ─────────────────────────────────────────────
//  PRICES SERVICE  (main collection)
// ─────────────────────────────────────────────
class PricesService {
  final FirebaseFirestore _firestore;

  PricesService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('prices');

  // Watch all items
  Stream<List<PriceItem>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PriceItem.fromSnapshot).toList());
  }

  // Watch items added by current user only
  Stream<List<PriceItem>> watchMine(String userId) {
    return _col
        .where('addedBy', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PriceItem.fromSnapshot).toList());
  }

  // Search by name (client-side fuzzy after fetching)
  Future<List<PriceItem>> searchByName(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final snap = await _col
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThanOrEqualTo: '$q\uf8ff')
        .limit(50)
        .get();
    return snap.docs.map(PriceItem.fromSnapshot).toList();
  }

  // Add new item
  Future<void> addItem({
    required String name,
    required double price,
    required String unit,
    required String category,
    required String store,
    required String addedBy,
    String? barcode,
    String? imageUrl,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _col.add({
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'price': price,
      'unit': unit,
      'category': category,
      'store': store,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'addedBy': addedBy,
      'updatedAt': now,
      'createdAt': now,
    });
  }

  // Update item price
  Future<void> updatePrice({
    required String docId,
    required double newPrice,
    required String updatedBy,
  }) async {
    await _col.doc(docId).update({
      'price': newPrice,
      'addedBy': updatedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete item
  Future<void> deleteItem(String docId) async {
    await _col.doc(docId).delete();
  }
}

@riverpod
PricesService pricesService(Ref ref) {
  return PricesService(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<PriceItem>> allPricesStream(Ref ref) {
  return ref.watch(pricesServiceProvider).watchAll();
}

@riverpod
Stream<List<PriceItem>> myPricesStream(Ref ref) {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return ref.watch(pricesServiceProvider).watchMine(uid);
}

class TransactionsService {
  final FirebaseFirestore _firestore;
  TransactionsService(this._firestore);

  CollectionReference get _col => _firestore.collection('transactions');

  // Watch transactions for a specific user
  Stream<List<TransactionModel>> watchUserTransactions(String userId) {
    return _col
        .where('sellerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromSnapshot).toList());
  }
}

// Provider for the service
@riverpod
TransactionsService transactionsService(Ref ref) {
  return TransactionsService(ref.watch(firebaseFirestoreProvider));
}

// Stream provider for the UI
@riverpod
Stream<List<TransactionModel>> userTransactionsStream(Ref ref) {
  // 1. Get the current user from your existing auth state provider
  final user = ref.watch(authStateChangesProvider).value;

  // 2. Return an empty stream if no user is logged in
  if (user == null) return const Stream.empty();

  // 3. IMPORTANT: Use the generated name 'transactionsServiceProvider'
  // and watch it to get the service instance.
  return ref.watch(transactionsServiceProvider).watchUserTransactions(user.uid);
}
