// lib/screens/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'add_item_screen.dart';
import 'price_check_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'sales_screen.dart';

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
    label: 'Price Check',
    icon: Icons.search_rounded,
    activeIcon: Icons.search_rounded,
  ),
  _NavItem(
    label: 'Add Item',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
  ),
  _NavItem(
    label: 'Sales',
    icon: Icons.point_of_sale_outlined,
    activeIcon: Icons.point_of_sale_rounded,
  ),
  _NavItem(
    label: 'History',
    icon: Icons.history_rounded,
    activeIcon: Icons.history_rounded,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
  ),
];

// ─────────────────────────────────────────────
//  CURRENT TAB PROVIDER
// ─────────────────────────────────────────────
final _tabProvider = StateProvider<int>((_) => 0);

// ─────────────────────────────────────────────
//  SHELL SCREEN
// ─────────────────────────────────────────────
class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  static const _screens = [
    PriceCheckScreen(),
    AddItemScreen(),
    SalesScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_tabProvider);
    final isWide = MediaQuery.of(context).size.width >= 720;

    return isWide
        ? _WebLayout(tab: tab, ref: ref)
        : _MobileLayout(tab: tab, ref: ref);
  }
}

// ─────────────────────────────────────────────
//  WEB LAYOUT  (top navbar)
// ─────────────────────────────────────────────
class _WebLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;

  const _WebLayout({required this.tab, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _TopNavBar(currentTab: tab, ref: ref),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: ShellScreen._screens,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final int currentTab;
  final WidgetRef ref;

  const _TopNavBar({required this.currentTab, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),
              // Logo / Brand
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.search_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ma.Tagpila',
                    style: AppTextStyles.headingMd
                        .copyWith(color: AppColors.orange),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              // Nav links
              Expanded(
                child: Row(
                  children: List.generate(
                    _navItems.length,
                    (i) => _WebNavLink(
                      item: _navItems[i],
                      isActive: currentTab == i,
                      onTap: () => ref.read(_tabProvider.notifier).state = i,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebNavLink extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _WebNavLink({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.orange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 18,
              color: isActive ? AppColors.orange : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: AppTextStyles.labelMd.copyWith(
                color: isActive ? AppColors.orange : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE LAYOUT  (bottom navbar)
// ─────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;

  const _MobileLayout({required this.tab, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: tab,
          children: ShellScreen._screens,
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentTab: tab,
        onTap: (i) => ref.read(_tabProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentTab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              _navItems.length,
              (i) => _BottomNavItem(
                item: _navItems[i],
                isActive: currentTab == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 22,
              color: isActive ? AppColors.orange : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
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
