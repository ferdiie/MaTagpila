// lib/screens/price_check_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/models/price_item_model.dart';
import '../features/shared/services/firestore_services.dart';

// ─────────────────────────────────────────────
//  SEARCH PROVIDER
// ─────────────────────────────────────────────
final _searchQueryProvider = StateProvider<String>((_) => '');

final _searchResultsProvider =
    FutureProvider.autoDispose<List<PriceItem>>((ref) async {
  final q = ref.watch(_searchQueryProvider);
  if (q.trim().isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 300)); // debounce
  return ref.read(pricesServiceProvider).searchByName(q);
});

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class PriceCheckScreen extends ConsumerStatefulWidget {
  const PriceCheckScreen({super.key});

  @override
  ConsumerState<PriceCheckScreen> createState() => _PriceCheckScreenState();
}

class _PriceCheckScreenState extends ConsumerState<PriceCheckScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchQueryProvider);
    final resultsAsync = ref.watch(_searchResultsProvider);
    final allAsync = ref.watch(allPricesStreamProvider);
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return CustomScrollView(
      slivers: [
        // ── Hero header ──────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF8C38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ma.Tagpila',
                  style: AppTextStyles.displayMd.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Check prices in your community',
                  style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) {
                      ref.read(_searchQueryProvider.notifier).state = v;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search item (e.g. Camia, rice, soap…)',
                      hintStyle: AppTextStyles.bodyMd,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.orange),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: AppColors.textMuted),
                              onPressed: () {
                                _controller.clear();
                                ref.read(_searchQueryProvider.notifier).state =
                                    '';
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────
        if (query.isEmpty) ...[
          // Recent items header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Recently Added',
                  style: AppTextStyles.headingSm
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ),
          // Recent list from stream
          allAsync.when(
            data: (items) => items.isEmpty
                ? SliverToBoxAdapter(
                    child: _EmptyState(
                        message: 'No items yet. Be the first to add!'),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PriceCard(item: items[i], formatter: fmt),
                      childCount: items.take(20).length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )),
            error: (e, _) => SliverToBoxAdapter(
                child: _EmptyState(message: 'Failed to load: $e')),
          ),
        ] else ...[
          // Search results
          resultsAsync.when(
            data: (items) => items.isEmpty
                ? SliverToBoxAdapter(
                    child: _EmptyState(message: 'No results for "$query"'),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PriceCard(item: items[i], formatter: fmt),
                      childCount: items.length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )),
            error: (e, _) => SliverToBoxAdapter(
                child: _EmptyState(message: 'Search error: $e')),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PRICE CARD
// ─────────────────────────────────────────────
class _PriceCard extends StatelessWidget {
  final PriceItem item;
  final NumberFormat formatter;

  const _PriceCard({required this.item, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final updated = DateFormat('MMM d, y').format(item.updatedAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.orangeSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_rounded,
              color: AppColors.orange, size: 22),
        ),
        title: Text(item.name, style: AppTextStyles.headingSm),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.storefront_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.store.isNotEmpty ? item.store : 'Unknown Store',
                    style: AppTextStyles.bodySm,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Updated $updated', style: AppTextStyles.bodySm),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter.format(item.price),
              style: AppTextStyles.priceMd.copyWith(color: AppColors.orange),
            ),
            Text(
              'per ${item.unit}',
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
