// lib/core/providers/router_provider.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/login_screen.dart';
import '../../screens/shell_screen.dart';
import 'auth_provider.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(FirebaseAuth auth) {
    _sub = auth.authStateChanges().listen((_) => notifyListeners());
  }
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

final _authRefreshProvider = Provider<_AuthRefresh>((ref) {
  final n = _AuthRefresh(ref.watch(firebaseAuthProvider));
  ref.onDispose(n.dispose);
  return n;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_authRefreshProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final onLogin = state.matchedLocation == '/login';

      if (!isLoggedIn) return onLogin ? null : '/login';
      if (onLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const ShellScreen(),
      ),
    ],
  );
});
