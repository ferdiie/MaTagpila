import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/models/app_user.dart';
import 'pos_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;
  bool _promptShown = false;

  @override
  void initState() {
    super.initState();
  }

  void _maybeShowYesterdayPrompt() {
    if (_promptShown) return;
    _promptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Yesterday's Sales", style: AppTextStyles.headingLg),
                const SizedBox(height: 10),
                Text(
                  "Review and export yesterday's transactions from your profile reports.",
                  style: AppTextStyles.bodyMd,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase() ?? '';
    final role = email.startsWith('admin') ? UserRole.admin : UserRole.cashier;
    final tabs = _tabsForRole(role);
    final index = _tabIndex >= tabs.length ? 0 : _tabIndex;

    if (role == UserRole.admin) {
      _maybeShowYesterdayPrompt();
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(bottom: false, child: tabs[index].screen),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.textGrey,
        onTap: (value) => setState(() => _tabIndex = value),
        type: BottomNavigationBarType.fixed,
        items: tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }

  List<_TabData> _tabsForRole(UserRole role) {
    if (role == UserRole.admin) {
      return [
        _TabData(
          label: 'Dashboard',
          icon: Icons.dashboard_rounded,
          screen: _DashboardBody(
            onOpenPriceChecker: () => setState(() => _tabIndex = 2),
          ),
        ),
        const _TabData(
          label: 'POS',
          icon: Icons.point_of_sale_rounded,
          screen: PosScreen(),
        ),
        const _TabData(
          label: 'Price Checker',
          icon: Icons.search_rounded,
          screen: _SimpleTab(title: 'Price Checker'),
        ),
        const _TabData(
          label: 'Inventory',
          icon: Icons.inventory_2_rounded,
          screen: _SimpleTab(title: 'Inventory'),
        ),
        const _TabData(
          label: 'Profile',
          icon: Icons.person_rounded,
          screen: _SimpleTab(title: 'Profile & Reports'),
        ),
      ];
    }

    // Cashier / fallback
    return [
      const _TabData(
        label: 'POS',
        icon: Icons.point_of_sale_rounded,
        screen: PosScreen(),
      ),
      const _TabData(
        label: 'Price Checker',
        icon: Icons.search_rounded,
        screen: _SimpleTab(title: 'Price Checker'),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Tab model
// ═══════════════════════════════════════════════════════════════════════════

class _TabData {
  final String label;
  final IconData icon;
  final Widget screen;

  const _TabData({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  Dashboard body
// ═══════════════════════════════════════════════════════════════════════════

class _DashboardBody extends StatelessWidget {
  final VoidCallback onOpenPriceChecker;

  const _DashboardBody({required this.onOpenPriceChecker});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              'MA.TAGPILA',
              style: AppTextStyles.displayMd.copyWith(color: AppColors.orange),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(color: AppColors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email?.split('@').first.toUpperCase() ??
                            'YOUR STORE',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Your store is looking good.',
                        style: TextStyle(
                          color:
                              AppColors.white.withAlpha((0.92 * 255).toInt()),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 0,
                  top: 10,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.white,
                      size: 72,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(30),
              elevation: 0,
              child: InkWell(
                onTap: onOpenPriceChecker,
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.orangeLight
                            .withAlpha((0.85 * 255).toInt()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search item to verify price.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'POS and inventory widgets can be customized from mockups next.',
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Placeholder tab
// ═══════════════════════════════════════════════════════════════════════════

class _SimpleTab extends StatelessWidget {
  final String title;

  const _SimpleTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title module in progress', style: AppTextStyles.headingMd),
    );
  }
}
