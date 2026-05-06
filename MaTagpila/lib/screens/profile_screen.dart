// lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    final displayName = email.split('@').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orangeSurface,
              border: Border.all(color: AppColors.orange, width: 2),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style:
                    AppTextStyles.displayMd.copyWith(color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(displayName.toUpperCase(), style: AppTextStyles.headingLg),
          const SizedBox(height: 4),
          Text(email, style: AppTextStyles.bodyMd),
          const SizedBox(height: 32),

          // Info cards
          _InfoCard(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          const SizedBox(height: 12),
          const _InfoCard(
            icon: Icons.storefront_rounded,
            label: 'Contributor',
            value: 'Ma.Tagpila Community',
          ),
          const SizedBox(height: 32),

          // Sign out button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Icon(icon, color: AppColors.orange, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySm),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.headingSm),
            ],
          ),
        ],
      ),
    );
  }
}
