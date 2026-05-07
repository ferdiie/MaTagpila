// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final uid = auth.currentUserId;
    final myItemsAsync = ref.watch(myPricesStreamProvider);
    final fmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFmt = DateFormat('MMM d, y  h:mm a');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text('My Submissions', style: AppTextStyles.displayMd),
                    ),
                    Image.asset(
                      'assets/images/logo.png',
                      height: 62,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.orange,
                        size: 34,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Price entries you\'ve contributed.',
                    style: AppTextStyles.bodyMd),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (uid.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text('Log in to see your history.',
                    style: AppTextStyles.bodyMd),
              ),
            ),
          )
        else
          myItemsAsync.when(
            data: (items) => items.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const Icon(Icons.history_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('No submissions yet.',
                              style: AppTextStyles.bodyMd),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final item = items[i];
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
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            title:
                                Text(item.name, style: AppTextStyles.headingSm),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(item.store, style: AppTextStyles.bodySm),
                                Text(dateFmt.format(item.updatedAt),
                                    style: AppTextStyles.bodySm),
                              ],
                            ),
                            trailing: Text(
                              fmt.format(item.price),
                              style: AppTextStyles.priceMd
                                  .copyWith(color: AppColors.orange),
                            ),
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $e', style: AppTextStyles.bodyMd),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
