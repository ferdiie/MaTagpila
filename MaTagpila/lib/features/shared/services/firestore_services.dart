// lib/features/shared/services/firestore_services.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';

import '../models/price_item_model.dart';
import '../../transactions/models/transaction_model.dart';
import '../models/app_user.dart';

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

/// Firestore `users/{uid}` for the signed-in account (role, storeId, storeName).
@riverpod
Stream<Map<String, dynamic>?> currentUserProfileData(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges().asyncExpand((u) {
    if (u == null) return Stream<Map<String, dynamic>?>.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .snapshots()
        .map((s) => s.data());
  });
}

/// Owner uid this session operates under (admin: own uid; cashier: owner uid).
@riverpod
String effectiveStoreId(Ref ref) {
  final u = ref.watch(firebaseAuthProvider).currentUser;
  if (u == null) return '';
  final async = ref.watch(currentUserProfileDataProvider);
  return async.maybeWhen(
    data: (d) {
      final sid = d?['storeId'] as String?;
      if (sid != null && sid.isNotEmpty) return sid;
      return u.uid;
    },
    orElse: () => u.uid,
  );
}

/// True when profile says store owner (not a cashier attendant).
@riverpod
bool isStoreAdmin(Ref ref) {
  final async = ref.watch(currentUserProfileDataProvider);
  return async.maybeWhen(
    data: (d) => (d?['role'] as String?) != 'cashier',
    orElse: () => true,
  );
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

  /// Catalog for one store (owner uid). Requires `storeId` on documents.
  Stream<List<PriceItem>> watchStore(String storeId) {
    if (storeId.isEmpty) {
      return Stream.value(const <PriceItem>[]);
    }
    return _col
        .where('storeId', isEqualTo: storeId)
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

  Future<List<PriceItem>> searchByNameForStore({
    required String storeId,
    required String query,
  }) async {
    if (storeId.isEmpty || query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final snap = await _col
        .where('storeId', isEqualTo: storeId)
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
    required String storeId,
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
      'storeId': storeId,
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

  /// Returns every product document for a store, sorted by name.
  /// Used by the Full Price List and Products by Category reports.
  Future<List<PriceItem>> getPricesForStore(String storeId) async {
    if (storeId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('prices')
        .where('storeId', isEqualTo: storeId)
        .orderBy('nameLower')
        .get();

    return snapshot.docs.map((doc) => PriceItem.fromSnapshot(doc)).toList();
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

/// POS, price checker, and dashboard use this — scoped to the owner store.
@riverpod
Stream<List<PriceItem>> storePricesStream(Ref ref) {
  final storeId = ref.watch(effectiveStoreIdProvider);
  if (storeId.isEmpty) return const Stream.empty();
  return ref.watch(pricesServiceProvider).watchStore(storeId);
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

  Stream<List<TransactionModel>> watchStoreTransactions(String storeId) {
    if (storeId.isEmpty) {
      return Stream.value(const <TransactionModel>[]);
    }
    return _col
        .where('sellerId', isEqualTo: storeId)
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
    String? cashierUid,
    String? cashierEmail,
  }) async {
    final payload = <String, dynamic>{
      'sellerId': sellerId,
      'items': items,
      'totalAmount': total,
      'cashGiven': tendered,
      'change': change,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (cashierUid != null) payload['cashierUid'] = cashierUid;
    if (cashierEmail != null) payload['cashierEmail'] = cashierEmail;
    await _col.add(payload);
  }

  /// Returns all transactions between [from] (inclusive) and [to] (inclusive),
  /// ordered by createdAt ascending.
  /// Used by the Transaction Report.
  Future<List<TransactionModel>> getTransactionsByRange({
    required String sellerId,
    required DateTime from,
    required DateTime to,
  }) async {
    // Make 'to' cover the full end day (up to 23:59:59)
    final toEndOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('transactions')
        .where('sellerId', isEqualTo: sellerId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(toEndOfDay))
        .orderBy('createdAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => TransactionModel.fromSnapshot(doc))
        .toList();
  }
}

// ── THESE TWO WERE MISSING — root cause of the error ──────────────────────────

@riverpod
TransactionsService transactionsService(Ref ref) {
  return TransactionsService(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<TransactionModel>> userTransactionsStream(Ref ref) {
  final storeId = ref.watch(effectiveStoreIdProvider);
  if (storeId.isEmpty) return const Stream.empty();
  return ref.watch(transactionsServiceProvider).watchStoreTransactions(storeId);
}

// ─────────────────────────────────────────────
//  STORE-SCOPED SEARCH STATS  (stores/{storeId}/searches/{docId})
//  Only counts queries that match at least one product in [catalogForMatch].
// ─────────────────────────────────────────────

bool storeCatalogContainsQuery(String rawQuery, List<PriceItem> catalog) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty || catalog.isEmpty) return false;
  for (final p in catalog) {
    if (p.nameLower.contains(q) || p.name.toLowerCase().contains(q)) {
      return true;
    }
  }
  return false;
}

String _storeSearchDocId(String normalizedQuery) {
  var id = normalizedQuery.trim().toLowerCase().replaceAll('/', '_');
  if (id.isEmpty) return '_';
  if (id.length > 800) id = id.substring(0, 800);
  return id;
}

/// Increments search stats for this store only when [rawQuery] matches the
/// given catalog slice (e.g. full store list or non-empty search hits).
Future<void> trackStoreSearch(
  String rawQuery,
  String storeId,
  List<PriceItem> catalogForMatch,
) async {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty || storeId.isEmpty) return;
  if (!storeCatalogContainsQuery(q, catalogForMatch)) return;

  final docRef = FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('searches')
      .doc(_storeSearchDocId(q));

  await docRef.set(
    {
      'query': q,
      'storeId': storeId,
      'count': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

/// Top search term for this store that still matches at least one catalog item.
Future<String> fetchMostSearchedForStore(
  String storeId,
  List<PriceItem> catalog,
) async {
  if (storeId.isEmpty) return '-';
  if (catalog.isEmpty) return 'Add products first';

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('searches')
        .orderBy('count', descending: true)
        .limit(40)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'No searches yet';
    }

    for (final doc in snapshot.docs) {
      final term = (doc.data()['query'] as String?)?.trim().toLowerCase() ?? '';
      if (term.isEmpty) continue;
      if (storeCatalogContainsQuery(term, catalog)) {
        return term;
      }
    }
    return 'No trending matches yet';
  } catch (e) {
    debugPrint('Error fetching most searched: $e');
    return '-';
  }
}

@riverpod
Future<String> userStoreName(Ref ref) async {
  final uid = ref.watch(firebaseAuthProvider).currentUser?.uid;
  if (uid == null) return 'Your Store';

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

  return doc.data()?['storeName'] ?? 'Your Store';
}

@riverpod
Stream<AppUser?> appUser(Ref ref) {
  return ref.watch(currentUserProfileDataProvider).when(
        data: (data) {
          if (data == null) return Stream.value(null);
          final uid = ref.watch(firebaseAuthProvider).currentUser?.uid ?? '';
          return Stream.value(AppUser.fromMap({...data, 'uid': uid}));
        },
        loading: () => Stream.value(null),
        error: (_, __) => Stream.value(null),
      );
}
