// lib/screens/transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // REQUIRED
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
// Ensure these paths match where you saved the previous steps
import '../features/shared/services/firestore_services.dart';
import '../features/transactions/models/transaction_model.dart';

class TransactionScreen extends ConsumerWidget {
  // Changed to ConsumerWidget
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    // 1. Watch the stream provider we created in firestore_services
    final transactionsAsync = ref.watch(userTransactionsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Transactions', style: AppTextStyles.headingLg),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      // 2. Handle the AsyncValue states (Data, Loading, Error)
      body: transactionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading transactions: $err'),
        ),
        data: (transactions) {
          return Column(
            children: [
              _buildSummaryCard(transactions),
              Expanded(
                child: transactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return _TransactionTile(
                            transaction: tx,
                            onTap: () => _showTransactionDetails(context, tx),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'No transactions found',
        style: AppTextStyles.bodyMd.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _buildSummaryCard(List<TransactionModel> transactions) {
    // Calculate total sales for the current day
    final now = DateTime.now();
    final todayTotal = transactions.where((tx) {
      return tx.timestamp.year == now.year &&
          tx.timestamp.month == now.month &&
          tx.timestamp.day == now.day;
    }).fold(0.0, (sum, item) => sum + item.totalAmount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Sales Today',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white70)),
              Text(
                '₱${NumberFormat('#,##0.00').format(todayTotal)}',
                style: AppTextStyles.displayMd.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 40),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _TransactionDetailSheet(transaction: tx),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  const _TransactionTile({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.orangeSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${transaction.id.substring(0, 5).toUpperCase()}',
                    style: AppTextStyles.headingSm,
                  ),
                  Text(
                    '${transaction.items.length} items bought',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${transaction.totalAmount.toStringAsFixed(2)}',
                  style:
                      AppTextStyles.headingSm.copyWith(color: AppColors.orange),
                ),
                Text(
                  DateFormat.jm().format(transaction.timestamp),
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionDetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Receipt Details', style: AppTextStyles.headingLg),
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(transaction.timestamp),
            style: AppTextStyles.bodySm,
          ),
          const Divider(height: 40),

          // Dynamic Items List from Transaction Model
          ...transaction.items.map((item) => _buildDetailRow(
                '${item['name']} (x${item['quantity']})',
                '₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
              )),

          const Divider(height: 40),
          _buildDetailRow(
            'Total Amount',
            '₱${transaction.totalAmount.toStringAsFixed(2)}',
            isBold: true,
          ),
          _buildDetailRow(
            'Cash Given',
            '₱${transaction.cashGiven.toStringAsFixed(2)}',
          ),
          _buildDetailRow(
            'Change',
            '₱${transaction.change.toStringAsFixed(2)}',
            color: AppColors.orange,
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Dismiss',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: isBold ? AppTextStyles.headingSm : AppTextStyles.bodyMd),
          Text(value,
              style: (isBold ? AppTextStyles.headingSm : AppTextStyles.bodyMd)
                  .copyWith(color: color)),
        ],
      ),
    );
  }
}
