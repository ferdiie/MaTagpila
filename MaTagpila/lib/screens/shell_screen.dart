// lib/screens/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
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

const _navItems = [
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

// ─────────────────────────────────────────────
//  BREAKPOINTS
// ─────────────────────────────────────────────
const double _mobileBreakpoint = 600;
const double _tabletBreakpoint = 900;

// ─────────────────────────────────────────────
//  CURRENT TAB PROVIDER
// ─────────────────────────────────────────────
final _tabProvider = StateProvider<int>((_) => 0);

// ─────────────────────────────────────────────
//  SHELL SCREEN
// ─────────────────────────────────────────────
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final width = MediaQuery.of(context).size.width;

    final screens = [
      DashboardScreen(
        onOpenPriceChecker: () => ref.read(_tabProvider.notifier).state = 2,
      ),
      const PosScreen(),
      const PriceCheckScreen(),
      const AddItemScreen(),
      const ProfileScreen(),
    ];

    if (width >= _mobileBreakpoint) {
      // Tablet & Desktop — sidebar layout
      return _SidebarLayout(tab: tab, ref: ref, screens: screens);
    } else {
      // Mobile — pill bottom nav
      return _MobileLayout(tab: tab, ref: ref, screens: screens);
    }
  }
}

// ─────────────────────────────────────────────
//  SIDEBAR LAYOUT  (tablet / desktop)
// ─────────────────────────────────────────────
class _SidebarLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  final List<Widget> screens;

  const _SidebarLayout({
    required this.tab,
    required this.ref,
    required this.screens,
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
                        itemCount: _navItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (_, i) => _SidebarNavItem(
                          item: _navItems[i],
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
//  MOBILE LAYOUT  (pill bottom nav)
// ─────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  final List<Widget> screens;

  const _MobileLayout({
    required this.tab,
    required this.ref,
    required this.screens,
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
        currentTab: tab,
        onTap: (i) => ref.read(_tabProvider.notifier).state = i,
      ),
    );
  }
}

class _PillBottomNav extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;

  const _PillBottomNav({
    required this.currentTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.cream, // background behind pill
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding + 12,
        top: 8,
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(40), // pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_navItems.length, (i) {
            if (i == 2) {
              // Center — Price Checker FAB-style
              return Expanded(
                child: _PillCenterItem(
                  item: _navItems[i],
                  isActive: currentTab == i,
                  onTap: () => onTap(i),
                ),
              );
            }
            return Expanded(
              child: _PillNavItem(
                item: _navItems[i],
                isActive: currentTab == i,
                onTap: () => onTap(i),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _PillNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.orange.withAlpha(25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 20,
                color: isActive ? AppColors.orange : AppColors.textMuted,
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
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.orange : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillCenterItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _PillCenterItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withAlpha(90),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
