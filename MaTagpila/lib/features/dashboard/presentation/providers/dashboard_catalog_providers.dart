import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/price_item_model.dart';
import '../../../shared/services/firestore_services.dart';

const String allCategoryFilter = 'All';

final selectedDashboardCategoryProvider = StateProvider<String>(
  (ref) => allCategoryFilter,
);

final dashboardProductsProvider = StreamProvider<List<PriceItem>>((ref) {
  final storeId = ref.watch(effectiveStoreIdProvider);
  if (storeId.isEmpty) return const Stream.empty();
  return ref.watch(pricesServiceProvider).watchStore(storeId);
});

final dashboardCategoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final productsAsync = ref.watch(dashboardProductsProvider);
  return productsAsync.whenData((items) {
    final uniqueCategories = items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [allCategoryFilter, ...uniqueCategories];
  });
});

/// All products unaffected by category filter — used for Recent Price Changes.
final dashboardRecentProductsProvider =
    Provider<AsyncValue<List<PriceItem>>>((ref) {
  final productsAsync = ref.watch(dashboardProductsProvider);
  return productsAsync.whenData((items) =>
      [...items]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
});

/// Stable color index keyed by category name (derived from sorted category list).
final dashboardCategoryColorMapProvider = Provider<Map<String, int>>((ref) {
  final categories = ref.watch(dashboardCategoriesProvider).valueOrNull ?? [];
  // Skip the 'All' entry at index 0 so real categories start at index 0
  final realCategories =
      categories.where((c) => c != allCategoryFilter).toList();
  return {for (var i = 0; i < realCategories.length; i++) realCategories[i]: i};
});

final dashboardFilteredProductsProvider =
    Provider.family<AsyncValue<List<PriceItem>>, String>((ref, query) {
  final productsAsync = ref.watch(dashboardProductsProvider);
  final selectedCategory = ref.watch(selectedDashboardCategoryProvider);
  final normalizedQuery = query.trim().toLowerCase();

  return productsAsync.whenData((items) {
    return items.where((item) {
      final matchesCategory = selectedCategory == allCategoryFilter
          ? true
          : item.category.toLowerCase() == selectedCategory.toLowerCase();

      if (!matchesCategory) return false;
      if (normalizedQuery.isEmpty) return true;

      return item.nameLower.contains(normalizedQuery) ||
          item.store.toLowerCase().contains(normalizedQuery) ||
          item.category.toLowerCase().contains(normalizedQuery);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  });
});

/// Highest search count for this store among terms that match the live catalog.
final mostSearchedInStoreProvider = FutureProvider<String>((ref) async {
  final storeId = ref.watch(effectiveStoreIdProvider);
  if (storeId.isEmpty) return '-';
  final items = await ref.watch(dashboardProductsProvider.future);
  return fetchMostSearchedForStore(storeId, items);
});
