// lib/screens/price_check_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/dashboard/presentation/providers/dashboard_catalog_providers.dart';
import '../features/shared/models/price_item_model.dart';
import '../features/shared/services/firestore_services.dart';

// ─────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────
final _searchQueryProvider = StateProvider<String>((_) => '');

/// Search results are scoped to [effectiveStoreId] (same store as POS).
final _searchResultsProvider =
    FutureProvider.autoDispose<List<PriceItem>>((ref) async {
  final q = ref.watch(_searchQueryProvider);
  if (q.trim().isEmpty) return [];
  final storeId = ref.watch(effectiveStoreIdProvider);
  if (storeId.isEmpty) return [];
  await Future.delayed(const Duration(milliseconds: 300));
  return ref.read(pricesServiceProvider).searchByNameForStore(
        storeId: storeId,
        query: q,
      );
});

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
    final allAsync = ref.watch(storePricesStreamProvider);
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      color: const Color(0xFFFFF5EE),
      child: CustomScrollView(
        slivers: [
          // ── Header card ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.orangeSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MaTAGPILA',
                              style: AppTextStyles.displayMd.copyWith(
                                color: AppColors.white,
                              )),
                          Text(
                            'Check prices in your store',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      fit: BoxFit.fitHeight,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.orangeSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.orange,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search bar ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(_searchQueryProvider.notifier).state = v,
                  onSubmitted: (v) async {
                    final q = v.trim();
                    if (q.isEmpty) return;
                    final storeId = ref.read(effectiveStoreIdProvider);
                    if (storeId.isEmpty) return;
                    final results = await ref
                        .read(pricesServiceProvider)
                        .searchByNameForStore(storeId: storeId, query: q);
                    if (results.isNotEmpty) {
                      await trackStoreSearch(q, storeId, results);
                      ref.invalidate(mostSearchedInStoreProvider);
                    }
                  },
                  style: AppTextStyles.headingSm,
                  decoration: InputDecoration(
                    hintText: 'Search item (e.g. Camia, rice, soap…)',
                    hintStyle:
                        AppTextStyles.bodyMd.copyWith(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.orange,
                    ),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
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
            ),
          ),

          // ── Section label ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    query.isEmpty ? 'Recently Added' : 'Search Results',
                    style: AppTextStyles.headingSm
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  if (query.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orangeSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '"$query"',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Results ───────────────────────────────────
          if (query.isEmpty) ...[
            allAsync.when(
              data: (items) => items.isEmpty
                  ? const SliverToBoxAdapter(
                      child: _EmptyState(
                          message:
                              'No items yet. Add your first product above!'),
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
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.orange,
                      strokeWidth: 2.5,
                    ),
                  ),
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
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.orange,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                  child: _EmptyState(message: 'Search error: $e')),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRICE CARD
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
      ref.read(_expandedItemIdProvider.notifier).state = null;
      _animCtrl.reverse();
    } else {
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
      // updatePrice writes to /users/{uid}/prices/{docId} — user-scoped.
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
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsMenuSheet(
        item: widget.item,
        onEditDetails: () {
          Navigator.of(context).pop();
          _showEditDetailsSheet(context);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _showDeleteDialog(context);
        },
      ),
    );
  }

  void _showEditDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditDetailsSheet(
        item: widget.item,
        onSaved: (name, unit, category) async {
          try {
            final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? '';
            // updateDetails writes to /users/{uid}/prices/{docId} — user-scoped.
            await ref.read(pricesServiceProvider).updateDetails(
                  docId: widget.item.id,
                  name: name,
                  unit: unit,
                  category: category,
                  updatedBy: uid,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name updated successfully.'),
                  backgroundColor: AppColors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update details: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        itemName: widget.item.name,
        onConfirm: () async {
          try {
            // deleteProduct removes /users/{uid}/prices/{docId} — user-scoped.
            await ref
                .read(pricesServiceProvider)
                .deleteProduct(docId: widget.item.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.item.name} deleted.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Main content row ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.orangeSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: AppColors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: AppTextStyles.headingSm,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (widget.item.category.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orangeSurface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.category,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          const Icon(Icons.storefront_rounded,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              widget.item.store.isNotEmpty
                                  ? widget.item.store
                                  : 'Unknown Store',
                              style: AppTextStyles.bodySm,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(updated, style: AppTextStyles.bodySm),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.formatter.format(widget.item.price),
                      style: AppTextStyles.priceMd
                          .copyWith(color: AppColors.orange),
                    ),
                    Text(
                      'per ${widget.item.unit}',
                      style: AppTextStyles.bodySm,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _expandAnim,
                          builder: (_, __) => _ActionButton(
                            onTap: _toggleEdit,
                            icon: shouldBeExpanded
                                ? Icons.close_rounded
                                : Icons.edit_rounded,
                            backgroundColor: shouldBeExpanded
                                ? AppColors.orange
                                : AppColors.orangeSurface,
                            iconColor: shouldBeExpanded
                                ? Colors.white
                                : AppColors.orange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _ActionButton(
                          onTap: () => _showOptionsMenu(context),
                          icon: Icons.more_horiz_rounded,
                          backgroundColor: const Color(0xFFF0F0F0),
                          iconColor: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Inline price edit panel ──────────────────
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
//  ACTION BUTTON
// ─────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: iconColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  OPTIONS MENU SHEET
// ─────────────────────────────────────────────
class _OptionsMenuSheet extends StatelessWidget {
  final PriceItem item;
  final VoidCallback onEditDetails;
  final VoidCallback onDelete;

  const _OptionsMenuSheet({
    required this.item,
    required this.onEditDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orangeSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded,
                      color: AppColors.orange, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.headingSm),
                      if (item.category.isNotEmpty)
                        Text(
                          item.category,
                          style:
                              AppTextStyles.bodySm.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 8),
          ListTile(
            onTap: onEditDetails,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded,
                  color: Color(0xFF4A7EFF), size: 22),
            ),
            title: Text('Edit Details', style: AppTextStyles.headingSm),
            subtitle: Text(
              'Change name, unit, or category',
              style: AppTextStyles.bodySm.copyWith(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ),
          ListTile(
            onTap: onDelete,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 22),
            ),
            title: Text(
              'Delete Product',
              style: AppTextStyles.headingSm.copyWith(color: AppColors.error),
            ),
            subtitle: Text(
              'Permanently remove this item',
              style: AppTextStyles.bodySm.copyWith(color: Colors.grey),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Colors.grey, size: 20),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EDIT DETAILS BOTTOM SHEET
// ─────────────────────────────────────────────
class _EditDetailsSheet extends StatefulWidget {
  final PriceItem item;
  final Future<void> Function(String name, String unit, String category)
      onSaved;

  const _EditDetailsSheet({required this.item, required this.onSaved});

  @override
  State<_EditDetailsSheet> createState() => _EditDetailsSheetState();
}

class _EditDetailsSheetState extends State<_EditDetailsSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late String _selectedCategory;
  bool _isSaving = false;

  static const _categories = [
    'Food Grocery',
    'Frozen Goods',
    'Canned Goods',
    'Powdered Sachets',
    'Snacks',
    'Alcoholic Drinks',
    'Beverages',
    'School Supplies',
    'Household & Personal Care',
    'Condiments',
    'Cigarettes',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _unitCtrl = TextEditingController(text: widget.item.unit);
    _selectedCategory = _categories.contains(widget.item.category)
        ? widget.item.category
        : 'Food Grocery';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final unit = _unitCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name cannot be empty.')),
      );
      return;
    }
    if (unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit cannot be empty.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSaved(name, unit, _selectedCategory);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Color(0xFF4A7EFF), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Details', style: AppTextStyles.headingLg),
                      Text(
                        'Update name, unit, or category',
                        style:
                            AppTextStyles.bodySm.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _FieldLabel(label: 'Product Name'),
              const SizedBox(height: 8),
              _InputField(
                controller: _nameCtrl,
                hintText: 'e.g. Camia Sardines',
                prefixIcon: Icons.label_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              const _FieldLabel(label: 'Unit'),
              const SizedBox(height: 8),
              _InputField(
                controller: _unitCtrl,
                hintText: 'e.g. piece, kilo, pack, sachet',
                prefixIcon: Icons.straighten_rounded,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'Used as "per ___" in the price display.',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 20),
              const _FieldLabel(label: 'Category'),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.orange),
                    style: AppTextStyles.headingSm,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                const Icon(Icons.category_outlined,
                                    size: 16, color: AppColors.orange),
                                const SizedBox(width: 10),
                                Text(c),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.headingSm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.orange.withAlpha(120),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFDDC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_rounded, size: 14, color: AppColors.orange),
              const SizedBox(width: 6),
              Text(
                'Update price for ${item.name}',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.white,
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
//  DELETE CONFIRM DIALOG
// ─────────────────────────────────────────────
class _DeleteConfirmDialog extends StatefulWidget {
  final String itemName;
  final Future<void> Function() onConfirm;

  const _DeleteConfirmDialog({required this.itemName, required this.onConfirm});

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Delete Product?', style: AppTextStyles.headingLg),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.bodySm
                  .copyWith(color: Colors.grey[600], height: 1.5),
              children: [
                const TextSpan(text: 'You are about to permanently delete '),
                TextSpan(
                  text: '"${widget.itemName}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const TextSpan(text: '. This action cannot be undone.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed:
                        _isDeleting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.headingSm
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isDeleting
                        ? null
                        : () async {
                            setState(() => _isDeleting = true);
                            await widget.onConfirm();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.error.withAlpha(120),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
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
//  SHARED SMALL WIDGETS
// ─────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bodySm.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        style: AppTextStyles.headingSm,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: AppTextStyles.bodySm.copyWith(color: Colors.grey[400]),
          prefixIcon: Icon(prefixIcon, color: AppColors.orange, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.orangeSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
