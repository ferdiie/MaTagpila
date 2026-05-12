import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/models/price_item_model.dart';
import '../features/shared/services/firestore_services.dart';

final _posSearchProvider = StateProvider<String>((_) => '');

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _cashController = TextEditingController();
  final Map<String, int> _cart = {};
  bool _isSaving = false;
  bool _catalogCollapsed = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _addToCart(PriceItem item) {
    setState(() {
      _cart[item.id] = (_cart[item.id] ?? 0) + 1;
      // Auto-collapse catalog on first item so cart gets full focus
      if (_cart.length == 1 && _cart[item.id] == 1) {
        _catalogCollapsed = true;
      }
    });
  }

  void _decreaseQty(String itemId) {
    final current = _cart[itemId] ?? 0;
    if (current <= 1) {
      setState(() => _cart.remove(itemId));
    } else {
      setState(() => _cart[itemId] = current - 1);
    }
  }

  void _increaseQty(String itemId) =>
      setState(() => _cart[itemId] = (_cart[itemId] ?? 0) + 1);

  void _clearSale() {
    setState(() {
      _cart.clear();
      _isSaving = false;
      _catalogCollapsed = false; // Re-open catalog so cashier can start fresh
    });
    _cashController.clear();
  }

  Future<void> _completeSale({
    required Map<String, PriceItem> itemsById,
    required double total,
    required double tendered,
    required double change,
  }) async {
    if (_isSaving) return;

    final freshTendered = double.tryParse(_cashController.text.trim()) ?? 0;
    final freshChange = freshTendered - total;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      _showDialog(
        icon: Icons.lock_outline_rounded,
        iconColor: Colors.red,
        title: 'Not Signed In',
        message: 'You must be logged in to complete a sale.',
      );
      return;
    }

    final lineItems = _cart.entries.map((entry) {
      final item = itemsById[entry.key]!;
      return {
        'itemId': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': entry.value,
        'lineTotal': item.price * entry.value,
      };
    }).toList();

    setState(() => _isSaving = true);

    try {
      final storeId = ref.read(effectiveStoreIdProvider);
      final isCashier = ref.read(isStoreAdminProvider) == false;
      await ref.read(transactionsServiceProvider).saveTransaction(
            sellerId: storeId.isNotEmpty ? storeId : user.uid,
            items: lineItems,
            total: total,
            tendered: freshTendered,
            change: freshChange,
            cashierUid: isCashier ? user.uid : null,
            cashierEmail: isCashier ? user.email : null,
          );

      _clearSale();

      if (mounted) {
        _showDialog(
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green,
          title: 'Sale Complete!',
          message: 'Total: ₱${total.toStringAsFixed(2)}\n'
              'Cash: ₱${freshTendered.toStringAsFixed(2)}\n'
              'Change: ₱${freshChange.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        _showDialog(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          title: 'Sale Failed',
          message: 'Could not save transaction.\n\nError: $e',
        );
      }
    }
  }

  void _showDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: AppTextStyles.headingMd, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(message,
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.textSecondary, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(storePricesStreamProvider);
    final query = ref.watch(_posSearchProvider).trim().toLowerCase();
    final currency = NumberFormat.currency(symbol: '₱ ');

    return pricesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text('Failed to load items',
                style: AppTextStyles.headingSm
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
      data: (items) {
        final itemsById = {for (final item in items) item.id: item};
        final filtered = query.isEmpty
            ? items
            : items
                .where((item) =>
                    item.nameLower.contains(query) ||
                    item.name.toLowerCase().contains(query))
                .toList();

        final total = _cart.entries.fold<double>(0, (sum, entry) {
          final item = itemsById[entry.key];
          if (item == null) return sum;
          return sum + (item.price * entry.value);
        });

        final tendered = double.tryParse(_cashController.text.trim()) ?? 0;
        final change = tendered - total;
        final canCheckout = _cart.isNotEmpty && tendered >= total && !_isSaving;

        return Column(
          children: [
            // ── Header ────────────────────────────────
            _PosHeader(
              onSearchChanged: (value) =>
                  ref.read(_posSearchProvider.notifier).state = value,
              cartCount: _cart.values.fold(0, (a, b) => a + b),
            ),
            // ── Body ──────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final cartPanel = _CartPanel(
                    items: items,
                    cart: _cart,
                    formatter: currency,
                    total: total,
                    tenderedController: _cashController,
                    change: change,
                    canCheckout: canCheckout,
                    isSaving: _isSaving,
                    onCashChanged: (_) => setState(() {}),
                    onDecrease: _decreaseQty,
                    onIncrease: _increaseQty,
                    onClear: _clearSale,
                    onCheckout: () => _completeSale(
                      itemsById: itemsById,
                      total: total,
                      tendered: tendered,
                      change: change,
                    ),
                  );

                  // ── Catalog toggle bar (narrow only) ──
                  final cartItemCount = _cart.values.fold(0, (a, b) => a + b);
                  final catalogToggleBar = GestureDetector(
                    onTap: () =>
                        setState(() => _catalogCollapsed = !_catalogCollapsed),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grid_view_rounded,
                              size: 14, color: AppColors.orange),
                          const SizedBox(width: 6),
                          Text(
                            _catalogCollapsed ? 'Show catalog' : 'Hide catalog',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Cart badge — visible when catalog is open
                          if (cartItemCount > 0 && !_catalogCollapsed) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$cartItemCount in cart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          AnimatedRotation(
                            turns: _catalogCollapsed ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.keyboard_arrow_up_rounded,
                                size: 18, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );

                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _CatalogList(
                                items: filtered,
                                formatter: currency,
                                onAdd: _addToCart,
                                cart: _cart,
                              ),
                            ),
                            Container(width: 1, color: AppColors.borderLight),
                            Expanded(flex: 2, child: cartPanel),
                          ],
                        )
                      : Column(
                          children: [
                            // Toggle bar always visible
                            catalogToggleBar,
                            // Catalog — collapses to zero height when hidden
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: _catalogCollapsed
                                  ? const SizedBox.shrink()
                                  : SizedBox(
                                      // Catalog gets flex-3 equivalent height
                                      height: constraints.maxHeight * 0.32,
                                      child: _CatalogList(
                                        items: filtered,
                                        formatter: currency,
                                        onAdd: _addToCart,
                                        cart: _cart,
                                      ),
                                    ),
                            ),
                            // Cart panel fills remaining space
                            Expanded(child: cartPanel),
                          ],
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────
class _PosHeader extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final int cartCount;

  const _PosHeader({
    required this.onSearchChanged,
    required this.cartCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.point_of_sale_rounded,
                    color: AppColors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Point of Sale', style: AppTextStyles.headingMd),
                    if (cartCount > 0)
                      Text(
                        '$cartCount item${cartCount == 1 ? '' : 's'} in cart',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.orange, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: AppTextStyles.bodySm,
              decoration: InputDecoration(
                hintText: 'Search item name…',
                hintStyle:
                    AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 18),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CATALOG LIST  (compact)
// ─────────────────────────────────────────────
class _CatalogList extends StatelessWidget {
  final List<PriceItem> items;
  final NumberFormat formatter;
  final ValueChanged<PriceItem> onAdd;
  final Map<String, int> cart;

  const _CatalogList({
    required this.items,
    required this.formatter,
    required this.onAdd,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text('No matching items',
                style: AppTextStyles.bodySm
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final inCart = cart[item.id] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: inCart > 0
                  ? AppColors.orange.withAlpha(80)
                  : AppColors.borderLight,
              width: inCart > 0 ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            // ↓ Reduced vertical padding for compact rows
            padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
            child: Row(
              children: [
                // Category dot
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withAlpha(180),
                    shape: BoxShape.circle,
                  ),
                ),
                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.category} · ${item.unit} · ${item.store}',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Price + in-cart badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatter.format(item.price),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.orangeDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    if (inCart > 0)
                      Text(
                        '×$inCart',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.orange,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                // Add button — slightly smaller
                GestureDetector(
                  onTap: () => onAdd(item),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withAlpha(50),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  CART PANEL
// ─────────────────────────────────────────────
class _CartPanel extends StatelessWidget {
  final List<PriceItem> items;
  final Map<String, int> cart;
  final NumberFormat formatter;
  final double total;
  final TextEditingController tenderedController;
  final double change;
  final bool canCheckout;
  final bool isSaving;
  final ValueChanged<String> onCashChanged;
  final ValueChanged<String> onDecrease;
  final ValueChanged<String> onIncrease;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  const _CartPanel({
    required this.items,
    required this.cart,
    required this.formatter,
    required this.total,
    required this.tenderedController,
    required this.change,
    required this.canCheckout,
    required this.isSaving,
    required this.onCashChanged,
    required this.onDecrease,
    required this.onIncrease,
    required this.onClear,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final itemsById = {for (final item in items) item.id: item};
    final cartEntries = cart.entries
        .where((entry) => itemsById.containsKey(entry.key))
        .toList();
    final hasInsufficientCash = cart.isNotEmpty && !canCheckout && !isSaving;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: const Color(0xFFF9F9FB),
        child: Column(
          children: [
            // ── Cart header ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      size: 15, color: AppColors.orange),
                  const SizedBox(width: 5),
                  Text('Cart',
                      style: AppTextStyles.headingSm
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  if (cart.isNotEmpty)
                    GestureDetector(
                      onTap: isSaving ? null : onClear,
                      child: Text(
                        'Clear all',
                        style: AppTextStyles.bodySm.copyWith(
                          color: isSaving
                              ? AppColors.textMuted
                              : Colors.red.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Cart items (scrollable, Expanded so it never overflows) ──
            Expanded(
              child: cartEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              size: 32, color: AppColors.textMuted),
                          const SizedBox(height: 5),
                          Text('Cart is empty',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
                      itemCount: cartEntries.length,
                      itemBuilder: (context, index) {
                        final entry = cartEntries[index];
                        final item = itemsById[entry.key]!;
                        final lineTotal = item.price * entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(4),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTextStyles.bodySm.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      formatter.format(lineTotal),
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.orangeDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QtyButton(
                                    icon: Icons.remove_rounded,
                                    onTap: () => onDecrease(entry.key),
                                  ),
                                  SizedBox(
                                    width: 22,
                                    child: Text(
                                      '${entry.value}',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodySm.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  _QtyButton(
                                    icon: Icons.add_rounded,
                                    onTap: () => onIncrease(entry.key),
                                    filled: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Pinned checkout panel ────────────────
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total + Change row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total',
                                  style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                              Text(
                                formatter.format(total),
                                style: AppTextStyles.headingMd
                                    .copyWith(color: AppColors.orangeDark),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (cart.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: change >= 0
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Change',
                                    style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 9)),
                                Text(
                                  formatter.format(change < 0 ? 0 : change),
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: change >= 0
                                        ? Colors.green.shade600
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Cash input
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: TextField(
                        controller: tenderedController,
                        onChanged: onCashChanged,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: AppTextStyles.bodySm
                            .copyWith(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Cash tendered',
                          hintStyle: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textMuted),
                          prefixText: '₱  ',
                          prefixStyle: AppTextStyles.bodySm.copyWith(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                        ),
                      ),
                    ),
                    if (hasInsufficientCash) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 11, color: Colors.red.shade400),
                          const SizedBox(width: 3),
                          Text('Insufficient cash tendered',
                              style: AppTextStyles.bodySm.copyWith(
                                  color: Colors.red.shade400, fontSize: 10)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Checkout button
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: canCheckout ? onCheckout : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          disabledBackgroundColor:
                              AppColors.orange.withAlpha(60),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11)),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 5),
                                  Text('Complete Sale',
                                      style: AppTextStyles.bodySm.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QTY BUTTON
// ─────────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: filled ? AppColors.orange : AppColors.textMuted,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: filled ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }
}
