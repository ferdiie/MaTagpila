// lib/screens/sales_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.point_of_sale_rounded,
              size: 64, color: AppColors.orange),
          const SizedBox(height: 16),
          Text('Sales / POS', style: AppTextStyles.headingLg),
          const SizedBox(height: 8),
          Text('Coming soon', style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}
