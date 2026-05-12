// lib/core/providers/router_provider.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/login_screen.dart';
import '../../screens/shell_screen.dart';
import '../../screens/cashier_shell_screen.dart';
import '../../screens/transaction_screen.dart';
import 'auth_provider.dart';

// ─────────────────────────────────────────────
//  AUTH + ROLE REFRESH LISTENABLE
//  Notifies GoRouter whenever auth state changes
//  OR when the Firestore user doc changes role.
// ─────────────────────────────────────────────
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(FirebaseAuth auth) {
    _authSub = auth.authStateChanges().listen((_) => notifyListeners());
  }
  late final StreamSubscription<User?> _authSub;

  @override
  void dispose() {
    unawaited(_authSub.cancel());
    super.dispose();
  }
}

final _authRefreshProvider = Provider<_AuthRefresh>((ref) {
  final n = _AuthRefresh(ref.watch(firebaseAuthProvider));
  ref.onDispose(n.dispose);
  return n;
});

// ─────────────────────────────────────────────
//  ROLE PROVIDER
//  Reads Firestore once per session to get role.
//  Returns null while loading (router waits).
// ─────────────────────────────────────────────
final _userRoleProvider = FutureProvider<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

  return doc.data()?['role'] as String?;
});

// ─────────────────────────────────────────────
//  ROUTER
// ─────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;

      // Not logged in → always send to login
      if (!isLoggedIn) {
        return location == '/login' ? null : '/login';
      }

      // On login page but already logged in → fetch role and redirect
      if (location == '/login') {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final role = doc.data()?['role'] as String? ?? 'cashier';

        if (role == 'admin') return '/';
        if (role == 'cashier') return '/cashier';
        // disabled account
        await FirebaseAuth.instance.signOut();
        return '/login';
      }

      // Already on the correct shell — check they're not on the wrong one
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role'] as String? ?? 'cashier';

      // Cashier trying to access owner routes
      if (role == 'cashier' && !location.startsWith('/cashier')) {
        return '/cashier';
      }

      // Owner trying to access cashier routes
      if (role == 'admin' && location.startsWith('/cashier')) {
        return '/';
      }

      // Disabled account
      if (role == 'disabled') {
        await FirebaseAuth.instance.signOut();
        return '/login';
      }

      return null;
    },
    routes: [
      // ── Login ──────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthScreen(),
      ),

      // ── Owner / Admin shell ─────────────────
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const ShellScreen(),
        routes: [
          GoRoute(
            path: 'transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionScreen(),
          ),
        ],
      ),

      // ── Cashier shell ───────────────────────
      GoRoute(
        path: '/cashier',
        name: 'cashier_home',
        builder: (context, state) => const CashierShellScreen(),
      ),
    ],
  );
});
