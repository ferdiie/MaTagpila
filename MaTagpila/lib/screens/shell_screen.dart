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
    final isWide = MediaQuery.of(context).size.width >= 720;
    final screens = [
      DashboardScreen(
        onOpenPriceChecker: () => ref.read(_tabProvider.notifier).state = 2,
      ),
      const PosScreen(),
      const PriceCheckScreen(),
      const AddItemScreen(),
      const ProfileScreen(),
    ];

    return isWide
        ? _WebLayout(tab: tab, ref: ref, screens: screens)
        : _MobileLayout(tab: tab, ref: ref, screens: screens);
  }
}

// ─────────────────────────────────────────────
//  WEB LAYOUT  (top navbar)
// ─────────────────────────────────────────────
class _WebLayout extends StatelessWidget {
  final int tab;
  final WidgetRef ref;
  final List<Widget> screens;

  const _WebLayout({
    required this.tab,
    required this.ref,
    required this.screens,
  });

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
              children: screens,
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
                  Image.asset(
                    'assets/images/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 18),
                    ),
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
      height: 86,
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
        child: Row(
          children: List.generate(_navItems.length, (i) {
            if (i == 2) {
              return Expanded(
                child: _CenterBottomNavItem(
                  item: _navItems[i],
                  isActive: currentTab == i,
                  onTap: () => onTap(i),
                ),
              );
            }
            return Expanded(
              child: _BottomNavItem(
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              size: 20,
              color: isActive ? AppColors.orange : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterBottomNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _CenterBottomNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              height: 1.1,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.orange : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
