// lib/screens/dashboard_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/presentation/providers/dashboard_catalog_providers.dart';
import '../features/dashboard/presentation/widgets/dashboard_category_filter_bar.dart';
import '../features/shared/models/app_user.dart';
import '../features/shared/models/price_item_model.dart';
import '../features/shared/services/firestore_services.dart';
import '../features/transactions/models/transaction_model.dart';
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

  late Future<String> _mostSearchedFuture;

  @override
  void initState() {
    super.initState();
    // getMostSearchedItem reads from /users/{uid}/searches — user-scoped.
    _mostSearchedFuture = getMostSearchedItem();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    // userStoreNameProvider reads from /users/{uid} — user-scoped.
    final displayName = ref.watch(userStoreNameProvider).value ?? 'Your Store';
    final categoriesAsync = ref.watch(dashboardCategoriesProvider);
    final filteredProductsAsync =
        ref.watch(dashboardFilteredProductsProvider(_query));
    final recentProductsAsync = ref.watch(dashboardRecentProductsProvider);
    final selectedCategory = ref.watch(selectedDashboardCategoryProvider);
    final categoryColorMap = ref.watch(dashboardCategoryColorMapProvider);
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dateFmt = DateFormat('MMM d');
    final fullDateFmt = DateFormat('MMM d, y');

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Welcome Banner ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _WelcomeBanner(
            greeting: _greeting(),
            displayName: displayName,
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────
        filteredProductsAsync.when(
          data: (filteredProducts) {
            final recentItems =
                recentProductsAsync.valueOrNull?.take(8).toList() ?? [];
            final categoryOptions =
                categoriesAsync.valueOrNull ?? const [allCategoryFilter];

            if (!categoryOptions.contains(selectedCategory)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                ref.read(selectedDashboardCategoryProvider.notifier).state =
                    allCategoryFilter;
              });
            }

            final allProducts = recentProductsAsync.valueOrNull ?? [];

            // Today's sales — reads from /users/{uid}/transactions — user-scoped.
            final transactionsAsync = ref.watch(userTransactionsStreamProvider);
            final transactions =
                transactionsAsync.valueOrNull ?? <TransactionModel>[];
            final now = DateTime.now();
            final todaySales = transactions.where((tx) {
              return tx.timestamp.year == now.year &&
                  tx.timestamp.month == now.month &&
                  tx.timestamp.day == now.day;
            }).fold(0.0, (sum, tx) => sum + tx.totalAmount);

            return SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 4),

                // ── Stat cards ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.inventory_2_outlined,
                          value: '${allProducts.length}',
                          label: 'Items',
                          sublabel: 'in catalog',
                          color: AppColors.catBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _mostSearchedFuture,
                          builder: (context, snapshot) {
                            final mostSearched = snapshot.data ?? '-';

                            return GestureDetector(
                              onTap: () {
                                final q =
                                    mostSearched == '-' ? '' : mostSearched;
                                _searchController.text = q;
                                setState(() => _query = q);
                              },
                              child: _StatCard(
                                icon: Icons.search_rounded,
                                value: mostSearched,
                                label: 'Most Searched',
                                sublabel: 'tap to search',
                                color: AppColors.catGreen,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.payments_outlined,
                          value: NumberFormat.compactCurrency(
                            symbol: '₱',
                            decimalDigits: 0,
                          ).format(todaySales),
                          label: 'Total Sales',
                          sublabel: 'today',
                          color: AppColors.catOrange,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search bar ─────────────────────────────────────────
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      onSubmitted: (value) {
                        // trackSearch saves to /users/{uid}/searches — user-scoped.
                        trackSearch(value);
                        widget.onOpenPriceChecker();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search item to verify price…',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.orange),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.clear_rounded),
                              ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: AppColors.orange, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                ),

                // ── Recent price changes ───────────────────────────────
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                  child: Row(
                    children: [
                      Text(
                        _query.isEmpty
                            ? 'Recent Price Changes'
                            : 'Search Results',
                        style: AppTextStyles.headingLg,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: widget.onOpenPriceChecker,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('See all'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 140,
                  child: recentItems.isEmpty
                      ? Center(
                          child: Text(
                            'No recent price entries yet.',
                            style: AppTextStyles.bodyMd,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: recentItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, index) => _RecentPriceCard(
                            item: recentItems[index],
                            currency: currency,
                            dateFmt: fullDateFmt,
                          ),
                        ),
                ),

                // ── Browse by category ─────────────────────────────────
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text('Browse by Category',
                      style: AppTextStyles.headingLg),
                ),
                DashboardCategoryFilterBar(
                  categories: categoryOptions,
                  selectedCategory: selectedCategory,
                  onCategorySelected: (category) {
                    ref.read(selectedDashboardCategoryProvider.notifier).state =
                        category;
                  },
                ),

                // ── All products ───────────────────────────────────────
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        selectedCategory == allCategoryFilter
                            ? 'All Products'
                            : '$selectedCategory Products',
                        style: AppTextStyles.headingLg,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${filteredProducts.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                                'No products found.',
                                style: AppTextStyles.bodyMd,
                              ),
                            ),
                          )
                        : _ProductListView(
                            key: ValueKey(
                              'list-$selectedCategory-'
                              '${filteredProducts.length}-$_query',
                            ),
                            items: filteredProducts,
                            currency: currency,
                            dateFmt: dateFmt,
                            categoryColorMap: categoryColorMap,
                          ),
                  ),
                ),
                const SizedBox(height: 28),
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

// ═══════════════════════════════════════════════════════════════════════════
//  Welcome Banner
// ═══════════════════════════════════════════════════════════════════════════

class _WelcomeBanner extends StatelessWidget {
  final String greeting;
  final String displayName;

  const _WelcomeBanner({
    required this.greeting,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE85D04), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'MA.TAGPILA',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.80),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '🟢  Store is open',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 150,
                  height: 140,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.fitHeight,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.storefront_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 56,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Stat card
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  List layout for All Products
// ═══════════════════════════════════════════════════════════════════════════

class _ProductListView extends StatelessWidget {
  final List<PriceItem> items;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final Map<String, int> categoryColorMap;

  const _ProductListView({
    super.key,
    required this.items,
    required this.currency,
    required this.dateFmt,
    required this.categoryColorMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
          color: AppColors.borderLight,
        ),
        itemBuilder: (_, index) => _ProductListTile(
          item: items[index],
          currency: currency,
          dateFmt: dateFmt,
          accentColor: _categoryColor(
            categoryColorMap[items[index].category] ?? 0,
          ),
        ),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final PriceItem item;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final Color accentColor;

  const _ProductListTile({
    required this.item,
    required this.currency,
    required this.dateFmt,
    required this.accentColor,
  });

  Color _freshnessColor() {
    final age = DateTime.now().difference(item.updatedAt);
    if (age.inDays <= 1) return AppColors.catGreen;
    if (age.inDays <= 7) return AppColors.catOrange;
    return AppColors.catRed;
  }

  String _updatedLabel() {
    final age = DateTime.now().difference(item.updatedAt);
    if (age.inDays == 0) return 'Today';
    if (age.inDays == 1) return 'Yesterday';
    return dateFmt.format(item.updatedAt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: _freshnessColor(),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(item.price),
                style: AppTextStyles.priceMd,
              ),
              const SizedBox(height: 2),
              Text(
                _updatedLabel(),
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Category → accent color helper
// ═══════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════
//  Recent price card (horizontal scroll)
// ═══════════════════════════════════════════════════════════════════════════

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
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.orangeSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: AppColors.orange, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSm,
          ),
          const SizedBox(height: 2),
          Text(
            item.store,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textGrey),
          ),
          const Spacer(),
          Text(
            currency.format(item.price),
            style:
                AppTextStyles.headingSm.copyWith(color: AppColors.orangeDark),
          ),
          Text(
            'Updated ${dateFmt.format(item.updatedAt)}',
            style: AppTextStyles.bodySm
                .copyWith(color: AppColors.textGrey, fontSize: 10),
          ),
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
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE85D04), Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headingLg.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.white,
                      size: 42,
                    ),
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
