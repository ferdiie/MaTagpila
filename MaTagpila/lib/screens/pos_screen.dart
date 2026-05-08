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
  bool _isSaving = false; // ← prevents double-tap

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  void _addToCart(PriceItem item) {
    setState(() => _cart[item.id] = (_cart[item.id] ?? 0) + 1);
  }

  void _decreaseQty(String itemId) {
    final current = _cart[itemId] ?? 0;
    if (current <= 1) {
      setState(() => _cart.remove(itemId));
      return;
    }
    setState(() => _cart[itemId] = current - 1);
  }

  void _increaseQty(String itemId) {
    setState(() => _cart[itemId] = (_cart[itemId] ?? 0) + 1);
  }

  void _clearSale() {
    setState(() {
      _cart.clear();
      _isSaving = false;
    });
    _cashController.clear();
  }

  Future<void> _completeSale({
    required Map<String, PriceItem> itemsById,
    required double total,
    required double tendered,
    required double change,
  }) async {
    if (_isSaving) return; // guard against double-tap

    // Read the cash value fresh from the controller at the moment of tap,
    // not the stale value captured when build() last ran.
    final freshTendered = double.tryParse(_cashController.text.trim()) ?? 0;
    final freshChange = freshTendered - total;

    // Re-check auth — read directly from FirebaseAuth, not the AutoDispose stream
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

    // Build items list
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
      await ref.read(transactionsServiceProvider).saveTransaction(
            sellerId: user.uid,
            items: lineItems,
            total: total,
            tendered: freshTendered,
            change: freshChange,
          );

      // Only clear AFTER confirmed success
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
      setState(() => _isSaving = false); // allow retry on error
      if (mounted) {
        _showDialog(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          title: 'Sale Failed',
          // Show the full error so you can diagnose Firestore rules issues
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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Icon(icon, color: iconColor, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMd,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('OK',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(allPricesStreamProvider);
    final query = ref.watch(_posSearchProvider).trim().toLowerCase();
    final currency = NumberFormat.currency(symbol: '₱ ');

    return pricesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load items: $e',
          style: AppTextStyles.bodyMd,
          textAlign: TextAlign.center,
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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _PosHeader(
                onSearchChanged: (value) =>
                    ref.read(_posSearchProvider.notifier).state = value,
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
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

                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _CatalogList(
                                items: filtered,
                                formatter: currency,
                                onAdd: _addToCart,
                              ),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(flex: 2, child: cartPanel),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: _CatalogList(
                                items: filtered,
                                formatter: currency,
                                onAdd: _addToCart,
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(flex: 2, child: cartPanel),
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
  const _PosHeader({required this.onSearchChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Point of Sale', style: AppTextStyles.headingLg)),
              Image.asset(
                'assets/images/logo.png',
                height: 42,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.orange,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search item name',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CATALOG LIST
// ─────────────────────────────────────────────
class _CatalogList extends StatelessWidget {
  final List<PriceItem> items;
  final NumberFormat formatter;
  final ValueChanged<PriceItem> onAdd;

  const _CatalogList({
    required this.items,
    required this.formatter,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
          child: Text('No matching items.', style: AppTextStyles.bodyMd));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.name, style: AppTextStyles.headingSm),
            subtitle: Text(
              '${item.category} • ${item.unit} • ${item.store}',
              style: AppTextStyles.bodySm,
            ),
            trailing: SizedBox(
              width: 132,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      formatter.format(item.price),
                      style: AppTextStyles.priceMd
                          .copyWith(color: AppColors.orangeDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onAdd(item),
                    icon: const Icon(Icons.add_circle_rounded),
                    color: AppColors.orange,
                    tooltip: 'Add to cart',
                  ),
                ],
              ),
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

    return Container(
      color: AppColors.white,
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: EdgeInsets.only(
            left: 12,
            top: 12,
            right: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            if (cartEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text('Cart is empty.', style: AppTextStyles.bodyMd)),
              )
            else
              ...cartEntries.map((entry) {
                final item = itemsById[entry.key]!;
                final lineTotal = item.price * entry.value;
                return Card(
                  child: ListTile(
                    leading: Text(
                      formatter.format(lineTotal),
                      style: AppTextStyles.bodyMd
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    title: Text(item.name, style: AppTextStyles.headingSm),
                    subtitle: Text(
                      '${entry.value} x ${formatter.format(item.price)}',
                      style: AppTextStyles.bodySm,
                    ),
                    trailing: SizedBox(
                      width: 116,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => onDecrease(entry.key),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('${entry.value}'),
                          IconButton(
                            onPressed: () => onIncrease(entry.key),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderLight)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: AppTextStyles.headingMd),
                      Text(
                        formatter.format(total),
                        style: AppTextStyles.headingLg
                            .copyWith(color: AppColors.orangeDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: tenderedController,
                    onChanged: onCashChanged,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cash tendered',
                      prefixText: 'PHP ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Change', style: AppTextStyles.bodyMd),
                      Text(
                        formatter.format(change < 0 ? 0 : change),
                        style: AppTextStyles.headingMd,
                      ),
                    ],
                  ),
                  if (hasInsufficientCash) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Insufficient amount tendered.',
                      style:
                          AppTextStyles.bodySm.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              (cart.isEmpty || isSaving) ? null : onClear,
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canCheckout ? onCheckout : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Complete Sale',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
