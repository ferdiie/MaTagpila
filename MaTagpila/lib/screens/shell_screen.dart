// lib/screens/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';
import 'add_item_screen.dart';
import 'dashboard_screen.dart';
import 'price_check_screen.dart';
import 'profile_screen.dart';
import 'pos_screen.dart';

// ─────────────────────────────────────────────
//  NAV ITEM DEFINITION
// ─────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

// ─────────────────────────────────────────────
//  SIDEBAR NAV ITEMS  (unchanged — Price Check stays at index 2)
// ─────────────────────────────────────────────
const _ownerNavItems = [
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
    label: 'Price Checker',
    icon: Icons.search_rounded,
    activeIcon: Icons.search_rounded,
  ),
  _NavItem(
    label: 'Add Item',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

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
    label: 'Price Checker',
    icon: Icons.search_rounded,
    activeIcon: Icons.search_rounded,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

// ─────────────────────────────────────────────
//  MOBILE PILL ITEMS  (Price Checker excluded — it's the detached FAB)
// ─────────────────────────────────────────────
const _ownerPillItems = [
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
    label: 'Add Item',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

const _cashierPillItems = [
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

// Screen order (shared by both sidebar and mobile IndexedStack):
//   Owner:   Home=0  POS=1  PriceCheck=2  AddItem=3  Profile=4
//   Cashier: Home=0  POS=1  PriceCheck=2  Profile=3
//
// Mobile pill taps map to screen indices (skipping PriceCheck=2):
//   Owner pill:   Home→0  POS→1  AddItem→3  Profile→4
//   Cashier pill: Home→0  POS→1  Profile→3
const _ownerPillToScreen = [0, 1, 3, 4];
const _cashierPillToScreen = [0, 1, 3];
const _priceCheckerScreenIndex = 2; // same for both roles

// ─────────────────────────────────────────────
//  BREAKPOINTS
// ─────────────────────────────────────────────
const double _mobileBreakpoint = 600;
const double _tabletBreakpoint = 900;

// ─────────────────────────────────────────────
//  CURRENT TAB PROVIDER  (tracks screen index)
// ─────────────────────────────────────────────
final _tabProvider = StateProvider<int>((_) => 0);

// ─────────────────────────────────────────────
//  SHELL SCREEN
// ─────────────────────────────────────────────
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isStoreAdminProvider);
    final sidebarNavItems = isAdmin ? _ownerNavItems : _cashierNavItems;
    final pillItems = isAdmin ? _ownerPillItems : _cashierPillItems;
    final pillToScreen = isAdmin ? _ownerPillToScreen : _cashierPillToScreen;
    final totalScreens = isAdmin ? 5 : 4;

    var tab = ref.watch(_tabProvider);
    if (tab >= totalScreens) {
      tab = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(_tabProvider.notifier).state = 0;
      });
    }

    final width = MediaQuery.of(context).size.width;

    final dashboard = DashboardScreen(
      onOpenPriceChecker: () =>
          ref.read(_tabProvider.notifier).state = _priceCheckerScreenIndex,
    );

    // Owner:   [Home=0, POS=1, PriceCheck=2, AddItem=3, Profile=4]
    // Cashier: [Home=0, POS=1, PriceCheck=2, Profile=3]
    final screens = isAdmin
        ? <Widget>[
            dashboard,
            const PosScreen(),
            const PriceCheckScreen(),
            const AddItemScreen(),
            const ProfileScreen(),
          ]
        : <Widget>[
            dashboard,
            const PosScreen(),
            const PriceCheckScreen(),
            const ProfileScreen(),
          ];

    if (width >= _mobileBreakpoint) {
      return _SidebarLayout(
        tab: tab,
        ref: ref,
        screens: screens,
        navItems: sidebarNavItems, // sidebar is UNCHANGED
      );
    }

    return _MobileLayout(
      tab: tab,
      ref: ref,
      screens: screens,
      pillItems: pillItems,
      pillToScreen: pillToScreen,
    );
  }
}

// ─────────────────────────────────────────────
//  SIDEBAR LAYOUT  (tablet / desktop) — UNCHANGED
// ─────────────────────────────────────────────
class _SidebarLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  final List<Widget> screens;
  final List<_NavItem> navItems;

  const _SidebarLayout({
    required this.tab,
    required this.ref,
    required this.screens,
    required this.navItems,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= _tabletBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Row(
        children: [
          // ── Card Sidebar ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: isWide ? 220 : 72,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 24,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: isWide
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          if (isWide) ...[
                            const SizedBox(width: 10),
                            Text(
                              'Ma.Tagpila',
                              style: AppTextStyles.headingMd
                                  .copyWith(color: AppColors.orange),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Nav items
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: navItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (_, i) => _SidebarNavItem(
                          item: navItems[i],
                          isActive: tab == i,
                          isExpanded: isWide,
                          onTap: () =>
                              ref.read(_tabProvider.notifier).state = i,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // ── Main Content ──────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: IndexedStack(
                index: tab,
                children: screens,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isExpanded;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? AppColors.orange.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 14 : 10,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                size: 22,
                color: isActive ? AppColors.orange : AppColors.textMuted,
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: AppTextStyles.labelMd.copyWith(
                    color:
                        isActive ? AppColors.orange : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE LAYOUT  (pill + detached FAB)
// ─────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  final List<Widget> screens;
  final List<_NavItem> pillItems;
  final List<int> pillToScreen;

  const _MobileLayout({
    required this.tab,
    required this.ref,
    required this.screens,
    required this.pillItems,
    required this.pillToScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: screens,
        ),
      ),
      bottomNavigationBar: _PillBottomNav(
        pillItems: pillItems,
        pillToScreen: pillToScreen,
        currentScreenTab: tab,
        onTap: (screenIndex) =>
            ref.read(_tabProvider.notifier).state = screenIndex,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAV — pill tabs + detached Price Checker FAB
//  Owner:   [Home | POS | Add Item | Profile]  [Prices FAB]
//  Cashier: [Home | POS | Profile]             [Prices FAB]
// ─────────────────────────────────────────────
class _PillBottomNav extends StatelessWidget {
  final List<_NavItem> pillItems;
  final List<int> pillToScreen;
  final int currentScreenTab;
  final ValueChanged<int> onTap;

  const _PillBottomNav({
    required this.pillItems,
    required this.pillToScreen,
    required this.currentScreenTab,
    required this.onTap,
  });

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
          // ── Pill ─────────────────────────────
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
                children: List.generate(pillItems.length, (i) {
                  final item = pillItems[i];
                  final screenIndex = pillToScreen[i];
                  final isActive = currentScreenTab == screenIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onTap(screenIndex),
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
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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
            onTap: () => onTap(_priceCheckerScreenIndex),
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
