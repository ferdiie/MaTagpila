// lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  // ─── App version ───────────────────────────────────────────────────────────
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    final displayName = email.split('@').first;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: AppTextStyles.displayMd,
              ),
              Image.asset(
                'assets/images/logo.png',
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.orange,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // User Avatar & Identity
          _buildUserHeader(displayName, email),

          const SizedBox(height: 40),

          // Account Overview
          _buildSectionLabel('Account Overview'),
          _ProfileMenuTile(
            icon: Icons.receipt_long_rounded,
            label: 'My Transactions',
            onTap: () => context.pushNamed('transactions'),
          ),
          _ProfileMenuTile(
            icon: Icons.email_rounded,
            label: 'Contact Email',
            trailing: Text(
              email,
              style: AppTextStyles.bodySm.copyWith(color: Colors.grey),
            ),
            onTap: null,
          ),

          const SizedBox(height: 24),

          // Support & Settings
          _buildSectionLabel('Support & Settings'),
          _ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HelpSupportScreen(),
              ),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.info_outline_rounded,
            label: 'About Ma.Tagpila',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AboutScreen(),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Sign-Out Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // App version footer
          Text(
            'Ma.Tagpila v$_appVersion',
            style: AppTextStyles.bodySm.copyWith(color: Colors.grey[400]),
          ),
          const SizedBox(height: 4),
          Text(
            'Price Checker for Community Stores',
            style: AppTextStyles.bodySm.copyWith(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String name, String email) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.orangeSurface,
            border: Border.all(color: AppColors.orange, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: AppTextStyles.displayMd.copyWith(
                color: AppColors.orange,
                fontSize: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(name.toUpperCase(), style: AppTextStyles.headingLg),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Community Contributor',
            style: AppTextStyles.bodySm.copyWith(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.bodySm.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: AppColors.orange, size: 24),
        title: Text(label, style: AppTextStyles.headingSm),
        trailing: trailing ??
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
