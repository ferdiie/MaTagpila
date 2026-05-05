// lib/core/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────
//  FIREBASE SINGLETONS
// ─────────────────────────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

// ─────────────────────────────────────────────
//  CURRENT USER (Firebase Auth only — no Firestore)
// ─────────────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});
