import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DashboardCategoryFilterBar extends StatelessWidget {
  const DashboardCategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('No categories yet.', style: AppTextStyles.bodyMd),
      );
    }

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final category = categories[index];
          final isActive = category == selectedCategory;
          return _AnimatedCategoryChip(
            label: category,
            isActive: isActive,
            onTap: () => onCategorySelected(category),
          );
        },
      ),
    );
  }
}

class _AnimatedCategoryChip extends StatelessWidget {
  const _AnimatedCategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive ? AppColors.orange : AppColors.orangeSurface;
    final foregroundColor = isActive ? AppColors.white : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? AppColors.orangeDark : AppColors.borderLight,
        ),
        boxShadow: isActive ? AppShadows.orange : const [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: AppTextStyles.labelMd.copyWith(color: foregroundColor),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
