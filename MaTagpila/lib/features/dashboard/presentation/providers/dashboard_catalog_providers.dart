import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/price_item_model.dart';
import '../../data/dashboard_catalog_repository.dart';

const String allCategoryFilter = 'All';

final selectedDashboardCategoryProvider = StateProvider<String>(
  (ref) => allCategoryFilter,
);

final dashboardProductsProvider = StreamProvider<List<PriceItem>>(
  (ref) => ref.watch(dashboardCatalogRepositoryProvider).watchProducts(),
);

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
