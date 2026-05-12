// lib/screens/cashier_shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'price_check_screen.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────
//  TAB PROVIDER
// ─────────────────────────────────────────────
final _cashierTabProvider = StateProvider<int>((_) => 0);

// ─────────────────────────────────────────────
//  NAV ITEMS
//  Pill nav: Home(0) | POS(1) | Profile(2)   +   detached FAB = Prices(3)
// ─────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(
      {required this.label, required this.icon, required this.activeIcon});
}

const _cashierNavItems = [
  _NavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  _NavItem(
    label: 'POS',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale_rounded,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

// ─────────────────────────────────────────────
//  CASHIER SHELL SCREEN
// ─────────────────────────────────────────────
class CashierShellScreen extends ConsumerWidget {
  const CashierShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_cashierTabProvider);

    // Index 0 → DashboardScreen  (Home icon)
    // Index 1 → PosScreen        (POS icon)
    // Index 2 → ProfileScreen    (Profile icon — isStoreAdminProvider=false hides
    //                              cashier management & reports automatically)
    // Index 3 → PriceCheckScreen (detached FAB — kept in IndexedStack so state
    //                              is preserved between visits)
    final screens = [
      DashboardScreen(
        onOpenPriceChecker: () =>
            ref.read(_cashierTabProvider.notifier).state = 3,
      ),
      const PosScreen(),
      const ProfileScreen(),
      const PriceCheckScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: screens,
        ),
      ),
      bottomNavigationBar: _CashierBottomNav(
        currentTab: tab,
        onTap: (i) => ref.read(_cashierTabProvider.notifier).state = i,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAV — pill (3 tabs) + detached FAB
//  Layout: [pill: Home | POS | Profile]  [FAB: Prices]
// ─────────────────────────────────────────────
class _CashierBottomNav extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;

  const _CashierBottomNav({required this.currentTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.cream,
      padding: EdgeInsets.only(
        left: 16,
        right: 10,
        bottom: bottomPadding + 12,
        top: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Pill with 3 tabs ──────────────────
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_cashierNavItems.length, (i) {
                  final item = _cashierNavItems[i];
                  final isActive = currentTab == i;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(40),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.orange.withAlpha(25)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                size: 20,
                                color: isActive
                                    ? AppColors.orange
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 9,
                                height: 1.1,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? AppColors.orange
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Detached Price Checker FAB ────────
          GestureDetector(
            onTap: () => onTap(3), // index 3 → PriceCheckScreen
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Prices',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
