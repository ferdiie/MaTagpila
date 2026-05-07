// lib/screens/price_check_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/models/price_item_model.dart';
import '../features/shared/services/firestore_services.dart';

// ─────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────
final _searchQueryProvider = StateProvider<String>((_) => '');

final _searchResultsProvider =
    FutureProvider.autoDispose<List<PriceItem>>((ref) async {
  final q = ref.watch(_searchQueryProvider);
  if (q.trim().isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 300)); // debounce
  return ref.read(pricesServiceProvider).searchByName(q);
});

/// Tracks which item (by id) is currently expanded for price editing.
final _expandedItemIdProvider = StateProvider<String?>((_) => null);

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class PriceCheckScreen extends ConsumerStatefulWidget {
  const PriceCheckScreen({super.key});

  @override
  ConsumerState<PriceCheckScreen> createState() => _PriceCheckScreenState();
}

class _PriceCheckScreenState extends ConsumerState<PriceCheckScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ma.Tagpila',
                        style: AppTextStyles.displayMd
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 62,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
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
                    controller: _searchController,
                    onChanged: (v) =>
                        ref.read(_searchQueryProvider.notifier).state = v,
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
                                _searchController.clear();
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Recently Added',
                  style: AppTextStyles.headingSm
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ),
          allAsync.when(
            data: (items) => items.isEmpty
                ? const SliverToBoxAdapter(
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
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
                child: _EmptyState(message: 'Failed to load: $e')),
          ),
        ] else ...[
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
              ),
            ),
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
//  PRICE CARD  (with inline edit panel)
// ─────────────────────────────────────────────
class _PriceCard extends ConsumerStatefulWidget {
  final PriceItem item;
  final NumberFormat formatter;

  const _PriceCard({required this.item, required this.formatter});

  @override
  ConsumerState<_PriceCard> createState() => _PriceCardState();
}

class _PriceCardState extends ConsumerState<_PriceCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _expandAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    final currentId = ref.read(_expandedItemIdProvider);

    if (currentId == widget.item.id) {
      // Collapse this card
      ref.read(_expandedItemIdProvider.notifier).state = null;
      _animCtrl.reverse();
    } else {
      // Expand this card, collapse any other
      ref.read(_expandedItemIdProvider.notifier).state = widget.item.id;
      _priceController.text = widget.item.price.toStringAsFixed(2);
      _animCtrl.forward();
    }
  }

  Future<void> _savePrice() async {
    final raw = _priceController.text.trim();
    final newPrice = double.tryParse(raw);

    if (newPrice == null || newPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
      await ref.read(pricesServiceProvider).updatePrice(
            docId: widget.item.id,
            newPrice: newPrice,
            updatedBy: uid,
          );
      if (mounted) {
        ref.read(_expandedItemIdProvider.notifier).state = null;
        _animCtrl.reverse();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.item.name} updated to ₱${newPrice.toStringAsFixed(2)}'),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep animation in sync if another card was expanded
    final expandedId = ref.watch(_expandedItemIdProvider);
    final shouldBeExpanded = expandedId == widget.item.id;
    if (shouldBeExpanded &&
        _animCtrl.status != AnimationStatus.forward &&
        _animCtrl.status != AnimationStatus.completed) {
      _animCtrl.forward();
    } else if (!shouldBeExpanded &&
        _animCtrl.status != AnimationStatus.reverse &&
        _animCtrl.status != AnimationStatus.dismissed) {
      _animCtrl.reverse();
    }

    final updated = DateFormat('MMM d, y').format(widget.item.updatedAt);

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main row ──────────────────────────────────
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            title: Text(widget.item.name, style: AppTextStyles.headingSm),
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
                        widget.item.store.isNotEmpty
                            ? widget.item.store
                            : 'Unknown Store',
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.formatter.format(widget.item.price),
                      style: AppTextStyles.priceMd
                          .copyWith(color: AppColors.orange),
                    ),
                    Text('per ${widget.item.unit}',
                        style: AppTextStyles.bodySm),
                  ],
                ),
                const SizedBox(width: 8),
                // Edit toggle button
                AnimatedBuilder(
                  animation: _expandAnim,
                  builder: (_, __) => IconButton(
                    onPressed: _toggleEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: shouldBeExpanded
                          ? AppColors.orange
                          : AppColors.orangeSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(36, 36),
                    ),
                    icon: Icon(
                      shouldBeExpanded
                          ? Icons.close_rounded
                          : Icons.edit_rounded,
                      size: 18,
                      color: shouldBeExpanded ? Colors.white : AppColors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Inline edit panel (animated) ──────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: _InlineEditPanel(
              item: widget.item,
              controller: _priceController,
              isSaving: _isSaving,
              onSave: _savePrice,
              onCancel: _toggleEdit,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INLINE EDIT PANEL
// ─────────────────────────────────────────────
class _InlineEditPanel extends StatelessWidget {
  final PriceItem item;
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _InlineEditPanel({
    required this.item,
    required this.controller,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Text(
            'Update price for ${item.name}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Price input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '₱',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          style: AppTextStyles.headingSm,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'per ${item.unit}',
                          style: AppTextStyles.bodySm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isSaving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.orange.withAlpha(120),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────
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
