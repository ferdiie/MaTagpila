import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/presentation/providers/dashboard_catalog_providers.dart';
import '../features/dashboard/presentation/widgets/dashboard_category_filter_bar.dart';
import '../features/dashboard/presentation/widgets/dashboard_product_card.dart';
import '../features/shared/models/app_user.dart';
import '../features/shared/models/price_item_model.dart';
import 'pos_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class DashboardScreen extends StatelessWidget {
  final VoidCallback onOpenPriceChecker;

  const DashboardScreen({super.key, required this.onOpenPriceChecker});

  @override
  Widget build(BuildContext context) {
    return _DashboardBody(onOpenPriceChecker: onOpenPriceChecker);
  }
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

class _DashboardBody extends ConsumerStatefulWidget {
  final VoidCallback onOpenPriceChecker;

  const _DashboardBody({required this.onOpenPriceChecker});

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final categoriesAsync = ref.watch(dashboardCategoriesProvider);
    final filteredProductsAsync = ref.watch(dashboardFilteredProductsProvider(_query));
    final selectedCategory = ref.watch(selectedDashboardCategoryProvider);
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, y');

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
            height: 142,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 172, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back!',
                        style: TextStyle(color: Colors.black87, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email?.split('@').first.toUpperCase() ??
                            'YOUR STORE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your store is looking good.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withAlpha((0.75 * 255).toInt()),
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
                  width: 160,
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
        filteredProductsAsync.when(
          data: (filteredProducts) {
            final recentItems = filteredProducts.take(8).toList();
            final categoryOptions =
                categoriesAsync.valueOrNull ?? const [allCategoryFilter];

            if (!categoryOptions.contains(selectedCategory)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(selectedDashboardCategoryProvider.notifier).state =
                    allCategoryFilter;
              });
            }

            final topItemName = () {
              if (filteredProducts.isEmpty) return '-';
              final nameCounts = <String, int>{};
              for (final item in filteredProducts) {
                nameCounts[item.name] = (nameCounts[item.name] ?? 0) + 1;
              }
              final sortedNames = nameCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return sortedNames.first.key;
            }();

            final totalValue =
                filteredProducts.fold<double>(0, (sum, item) => sum + item.price);

            return SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DashboardStatCard(
                          value: '${filteredProducts.length}',
                          label: 'No. of Items',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardStatCard(
                          value: topItemName,
                          label: 'Most Searched',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DashboardStatCard(
                          value: currency.format(totalValue),
                          label: 'Total Sales',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onSubmitted: (_) => widget.onOpenPriceChecker(),
                    decoration: InputDecoration(
                      hintText: 'Search item to verify price.',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        _query.isEmpty ? 'Recent Price Changes' : 'Search Results',
                        style: AppTextStyles.headingLg,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onOpenPriceChecker,
                        child: const Text('See more'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 132,
                  child: recentItems.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'No recent price entries yet.'
                                : 'No matching items.',
                            style: AppTextStyles.bodyMd,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: recentItems.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, index) => _RecentPriceCard(
                            item: recentItems[index],
                            currency: currency,
                            dateFmt: dateFmt,
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Browse by Category', style: AppTextStyles.headingLg),
                ),
                DashboardCategoryFilterBar(
                  categories: categoryOptions,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (category) {
                    ref.read(selectedDashboardCategoryProvider.notifier).state =
                        category;
                  },
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    selectedCategory == allCategoryFilter
                        ? 'All Products (${filteredProducts.length})'
                        : '$selectedCategory Products (${filteredProducts.length})',
                    style: AppTextStyles.headingLg,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: filteredProducts.isEmpty
                        ? SizedBox(
                            key: ValueKey('empty-$selectedCategory-$_query'),
                            height: 120,
                            child: Center(
                              child: Text(
                                'No products found for this category.',
                                style: AppTextStyles.bodyMd,
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            key: ValueKey(
                              'grid-$selectedCategory-${filteredProducts.length}-$_query',
                            ),
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;
                              final cardWidth =
                                  (constraints.maxWidth - ((crossAxisCount - 1) * 12)) /
                                      crossAxisCount;
                              final childAspectRatio = cardWidth / 122;

                              return GridView.builder(
                                itemCount: filteredProducts.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemBuilder: (_, index) => DashboardProductCard(
                                  item: filteredProducts[index],
                                  currency: currency,
                                  accent: _categoryColor(index),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 22),
              ]),
            );
          },
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load dashboard data: $error',
                  style: AppTextStyles.bodyMd,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Color _categoryColor(int index) {
  const colors = [
    AppColors.catOrange,
    AppColors.catGreen,
    AppColors.catBlue,
    AppColors.catRed,
    AppColors.catBrown,
    AppColors.catPurple,
  ];
  return colors[index % colors.length];
}

class _DashboardStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _DashboardStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orangeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMd.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RecentPriceCard extends StatelessWidget {
  final PriceItem item;
  final NumberFormat currency;
  final DateFormat dateFmt;

  const _RecentPriceCard({
    required this.item,
    required this.currency,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingMd,
          ),
          const SizedBox(height: 2),
          Text(
            item.store,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm,
          ),
          const Spacer(),
          Text(
            currency.format(item.price),
            style: AppTextStyles.headingMd.copyWith(color: AppColors.orangeDark),
          ),
          Text('Updated ${dateFmt.format(item.updatedAt)}',
              style: AppTextStyles.bodySm),
        ],
      ),
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headingLg.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/logo.png',
                  height: 68,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text('$title module in progress',
                style: AppTextStyles.headingMd),
          ),
        ),
      ],
    );
  }
}
