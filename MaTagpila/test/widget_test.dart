// Smoke test: stub router so Firebase is not required.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matagpila/core/providers/router_provider.dart';
import 'package:matagpila/main.dart';

void main() {
  testWidgets('MaTagpilaApp renders with stub router', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('Ma.Tagpila')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
        ],
        child: const MaTagpilaApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ma.Tagpila'), findsOneWidget);
  });
}
