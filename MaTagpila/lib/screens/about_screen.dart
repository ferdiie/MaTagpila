// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Keep this in sync with the version shown in ProfileScreen.
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.orange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('About Ma.Tagpila', style: AppTextStyles.headingLg),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo / hero
            const SizedBox(height: 8),
            const _AppHero(version: appVersion),

            const SizedBox(height: 36),

            // About description
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeading(
                      icon: Icons.info_outline_rounded,
                      label: 'What is Ma.Tagpila?'),
                  const SizedBox(height: 12),
                  Text(
                    'Ma.Tagpila is a price-checking solution built for community '
                    'stores (sari-sari stores). It empowers the tigbantay sa '
                    'tindhan — the store attendant — to look up the price of any '
                    'product instantly, without interrupting the owner with '
                    'repeated price inquiries.\n\n'
                    'Prices are managed by the store owner in real time, keeping '
                    'staff and customers always informed and reducing errors at '
                    'the point of sale.',
                    style: AppTextStyles.bodySm
                        .copyWith(color: Colors.grey[700], height: 1.7),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Key features
            const _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeading(
                      icon: Icons.rocket_launch_rounded, label: 'Key Features'),
                  SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.search_rounded,
                    title: 'Instant Price Lookup',
                    description:
                        'Search products by name or barcode and get the price '
                        'right away.',
                  ),
                  _FeatureItem(
                    icon: Icons.edit_rounded,
                    title: 'Owner-Controlled Pricing',
                    description:
                        'Only authorized owners can update prices, ensuring '
                        'accuracy and control.',
                  ),
                  _FeatureItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Transaction History',
                    description:
                        'Keep track of every price check and sale for easy '
                        'record-keeping.',
                  ),
                  _FeatureItem(
                    icon: Icons.cloud_done_rounded,
                    title: 'Cloud Sync',
                    description:
                        'Powered by Firebase — data is always up-to-date across '
                        'all devices.',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Developer info
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeading(
                      icon: Icons.code_rounded, label: 'Developer'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.orange,
                              AppColors.orange.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'F',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ferdinand Roy Lopez',
                                style: AppTextStyles.headingLg),
                            const SizedBox(height: 2),
                            Text(
                              'Lead Developer & Designer',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 14),
                  const _InfoRow(
                      label: 'Email', value: 'ferdinandroy.lopez@gmail.com'),
                  const SizedBox(height: 6),
                  const _InfoRow(
                      label: 'Platform', value: 'Flutter · Firebase'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Version info
            const _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeading(
                      icon: Icons.new_releases_outlined, label: 'Version Info'),
                  SizedBox(height: 12),
                  _InfoRow(label: 'App Version', value: 'v$appVersion'),
                  SizedBox(height: 6),
                  _InfoRow(label: 'Build', value: buildNumber),
                  SizedBox(height: 6),
                  _InfoRow(label: 'Platform', value: 'Android · iOS'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Text(
              '© ${DateTime.now().year} Ma.Tagpila. All rights reserved.',
              style: AppTextStyles.bodySm.copyWith(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local widgets
// ---------------------------------------------------------------------------

class _AppHero extends StatelessWidget {
  final String version;
  const _AppHero({required this.version});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.orangeSurface,
            border: Border.all(color: AppColors.orange, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 58,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                color: AppColors.orange,
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Ma.Tagpila', style: AppTextStyles.displayMd),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.orangeSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'v$version',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Price Checker for Community Stores',
          style: AppTextStyles.bodySm.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeading extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardHeading({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.orange, size: 20),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.headingLg),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.orangeSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.orange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSm),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySm
                        .copyWith(color: Colors.grey[600], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF5F5F5)),
          )
        else
          const SizedBox(height: 4),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodySm.copyWith(color: Colors.grey[500])),
        Text(value,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
