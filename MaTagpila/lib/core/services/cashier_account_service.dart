import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

const _secondaryAppName = 'CashierSignup';

/// Creates cashier Auth users without signing the owner out, using a secondary
/// [FirebaseApp] with the same options as the default project.
class CashierAccountService {
  CashierAccountService(this._firestore);

  final FirebaseFirestore _firestore;

  static Future<FirebaseApp> ensureSecondaryApp() async {
    try {
      return Firebase.app(_secondaryAppName);
    } catch (_) {
      return Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  /// Creates Firebase Auth user + `users/{cashierUid}` + `users/{ownerUid}/cashiers/{cashierUid}`.
  Future<void> createCashierAccount({
    required String ownerUid,
    required String ownerStoreName,
    required String displayName,
    required String email,
    required String password,
  }) async {
    final app = await ensureSecondaryApp();
    final secondaryAuth = FirebaseAuth.instanceFor(app: app);

    UserCredential cred;
    try {
      cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      await secondaryAuth.signOut();
    }

    final uid = cred.user!.uid;
    final batch = _firestore.batch();

    final cashierRef = _firestore.collection('users').doc(uid);
    batch.set(cashierRef, {
      'uid': uid,
      'name': displayName.trim(),
      'displayName': displayName.trim(),
      'email': email.trim(),
      'role': 'cashier',
      'storeId': ownerUid,
      'storeName': ownerStoreName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final indexRef = _firestore
        .collection('users')
        .doc(ownerUid)
        .collection('cashiers')
        .doc(uid);
    batch.set(indexRef, {
      'uid': uid,
      'name': displayName.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
