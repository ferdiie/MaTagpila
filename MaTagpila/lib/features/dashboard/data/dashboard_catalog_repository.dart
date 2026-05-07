import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/price_item_model.dart';
import '../../shared/services/firestore_services.dart';

class DashboardCatalogRepository {
  const DashboardCatalogRepository(this._pricesService);

  final PricesService _pricesService;

  Stream<List<PriceItem>> watchProducts() {
    return _pricesService.watchAll();
  }
}

final dashboardCatalogRepositoryProvider = Provider<DashboardCatalogRepository>(
  (ref) => DashboardCatalogRepository(ref.watch(pricesServiceProvider)),
);
