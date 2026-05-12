// lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import 'manage_cashiers_screen.dart';
import 'reports_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Unknown';
    final isAdmin = ref.watch(isStoreAdminProvider);

    // ✅ Read the name from Firestore via the provider
    final storeNameAsync = ref.watch(userStoreNameProvider);
    final displayName = storeNameAsync.valueOrNull ?? '...';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Header ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile', style: AppTextStyles.displayMd),
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

          // ── User Avatar & Identity ─────────────────
          _buildUserHeader(displayName, email),
          const SizedBox(height: 40),

          // ── Account Overview ──────────────────────
          _buildSectionLabel('Account Overview'),
          _ProfileMenuTile(
            icon: Icons.receipt_long_rounded,
            label: 'My Transactions',
            onTap: () => context.pushNamed('transactions'),
          ),

          if (isAdmin) ...[
            _ProfileMenuTile(
              icon: Icons.group_add_outlined,
              label: 'Store attendants',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCashiersScreen()),
              ),
            ),
            _ProfileMenuTile(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'PDF',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Support & Settings ────────────────────
          _buildSectionLabel('Support & Settings'),
          _ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.info_outline_rounded,
            label: 'About MaTAGPILA',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),

          const SizedBox(height: 48),

          // ── Sign-Out ──────────────────────────────
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

          // ── Version footer ────────────────────────
          Text(
            'MaTAGPILA v$_appVersion',
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
        // Avatar with gradient ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE85D04), Color(0xFFFF8C42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orangeSurface,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: AppTextStyles.displayMd.copyWith(
                    color: AppColors.orange,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ✅ Name from Firestore (not email-derived)
        Text(
          name,
          style: AppTextStyles.headingLg.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),

        // ✅ Email shown as subtitle (replaces "Community Contributor")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mail_outline_rounded,
                  size: 13, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text(
                email,
                style: AppTextStyles.bodySm.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
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

// ─────────────────────────────────────────────
//  PROFILE MENU TILE
// ─────────────────────────────────────────────
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.orangeSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.orange, size: 20),
        ),
        title: Text(label, style: AppTextStyles.headingSm),
        trailing: trailing ??
            (onTap != null
                ? const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
