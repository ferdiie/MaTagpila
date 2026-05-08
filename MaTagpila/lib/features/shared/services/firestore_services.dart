// lib/features/shared/services/firestore_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

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
//  PRICES SERVICE
// ─────────────────────────────────────────────
class PricesService {
  final FirebaseFirestore _firestore;

  PricesService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('prices');

  Stream<List<PriceItem>> watchAll() {
    return _col
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PriceItem.fromSnapshot).toList());
  }

  Stream<List<PriceItem>> watchMine(String userId) {
    return _col
        .where('addedBy', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PriceItem.fromSnapshot).toList());
  }

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

  Future<void> deleteItem(String docId) async {
    await _col.doc(docId).delete();
  }

  /// Updates the name, unit, and category of a product document.
  Future<void> updateDetails({
    required String docId,
    required String name,
    required String unit,
    required String category,
    required String updatedBy,
  }) async {
    await _firestore.collection('prices').doc(docId).update({
      'name': name,
      'name_lowercase': name.toLowerCase(), // keep search index in sync
      'unit': unit,
      'category': category,
      'updatedBy': updatedBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently deletes a product document from Firestore.
  Future<void> deleteProduct({required String docId}) async {
    await _firestore.collection('prices').doc(docId).delete();
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

// ─────────────────────────────────────────────
//  TRANSACTIONS SERVICE
// ─────────────────────────────────────────────
class TransactionsService {
  final FirebaseFirestore _firestore;
  TransactionsService(this._firestore);

  CollectionReference get _col => _firestore.collection('transactions');

  Stream<List<TransactionModel>> watchUserTransactions(String userId) {
    return _col
        .where('sellerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map(TransactionModel.fromSnapshot).toList());
  }

  Future<void> saveTransaction({
    required String sellerId,
    required List<Map<String, dynamic>> items,
    required double total,
    required double tendered,
    required double change,
  }) async {
    await _col.add({
      'sellerId': sellerId,
      'items': items,
      'total': total,
      'tendered': tendered,
      'change': change,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

// ── THESE TWO WERE MISSING — root cause of the error ──────────────────────────

@riverpod
TransactionsService transactionsService(Ref ref) {
  return TransactionsService(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<TransactionModel>> userTransactionsStream(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(transactionsServiceProvider).watchUserTransactions(user.uid);
}

// ─────────────────────────────────────────────
//  MOST SEARCHED ITEM
// ─────────────────────────────────────────────

Future<void> trackSearch(String query) async {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return;

  final ref = FirebaseFirestore.instance.collection('searches').doc(q);

  await ref.set(
    {'query': q, 'count': FieldValue.increment(1)},
    SetOptions(merge: true), // creates doc if not exists
  );
}

Future<String> getMostSearchedItem() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('searches')
        .orderBy('count', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'No searches yet'; // Return a placeholder string, not null
    }

    // Ensure we access the correct field name ('query')
    return snapshot.docs.first.data()['query'] as String? ?? 'None';
  } catch (e) {
    debugPrint('Error fetching most searched: $e');
    return '-'; // Fallback string on error
  }
}
