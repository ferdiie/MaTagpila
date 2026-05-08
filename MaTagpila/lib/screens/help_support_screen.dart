// lib/screens/help_support_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: Text('Help & Support', style: AppTextStyles.headingLg),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange,
                    AppColors.orange.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help you?',
                          style: AppTextStyles.headingLg.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Browse FAQs or reach out to our team.',
                          style: AppTextStyles.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const _SectionLabel(text: 'Frequently Asked Questions'),
            const SizedBox(height: 12),

            const _FaqTile(
              question: 'What is Ma.Tagpila?',
              answer:
                  'Ma.Tagpila is a price-checking solution that lets store staff ('
                  'tigbantay sa tindhan) look up product prices instantly, without '
                  'having to repeatedly ask the store owner.',
            ),
            const _FaqTile(
              question: 'How do I check a product\'s price?',
              answer:
                  'Navigate to the Products or Transactions section, search for '
                  'the item by name or scan its barcode, and the current price will '
                  'be displayed immediately.',
            ),
            const _FaqTile(
              question: 'Who can use Ma.Tagpila?',
              answer:
                  'Ma.Tagpila is designed for small to medium sari-sari stores and '
                  'community shops. Store owners set up the system while staff use '
                  'it for day-to-day price lookups.',
            ),
            const _FaqTile(
              question: 'How do I update a product price?',
              answer:
                  'Only the store owner or an authorized admin can update prices. '
                  'Go to the product details page, tap Edit, enter the new price, '
                  'and save. Changes take effect immediately.',
            ),
            const _FaqTile(
              question: 'What do I do if I forget my password?',
              answer:
                  'On the login screen, tap "Forgot Password" and enter your '
                  'registered email. You will receive a reset link within a few '
                  'minutes.',
            ),
            const _FaqTile(
              question: 'Is my data stored securely?',
              answer:
                  'Yes. Ma.Tagpila uses Firebase Authentication and Firestore, '
                  'which are backed by Google Cloud security infrastructure. Your '
                  'data is encrypted at rest and in transit.',
            ),

            const SizedBox(height: 32),

            const _SectionLabel(text: 'Contact & Support'),
            const SizedBox(height: 12),

            _ContactTile(
              icon: Icons.email_rounded,
              title: 'Email Support',
              subtitle: 'ferdinandroy.lopez@gmail.com',
              onTap: () {
                // Launch email intent
              },
            ),
            _ContactTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Send Feedback',
              subtitle: 'Help us improve Ma.Tagpila',
              onTap: () {
                _showFeedbackDialog(context);
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Send Feedback', style: AppTextStyles.headingLg),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us what you think…',
            hintStyle: AppTextStyles.bodySm.copyWith(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.orange),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.orange, width: 1.8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: AppTextStyles.bodySm.copyWith(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle submission
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thank you for your feedback!'),
                  backgroundColor: AppColors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.bodySm.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          leading:
              const Icon(Icons.help_outline_rounded, color: AppColors.orange),
          title: Text(widget.question, style: AppTextStyles.headingSm),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.grey),
          ),
          onExpansionChanged: (val) => setState(() => _expanded = val),
          children: [
            Text(
              widget.answer,
              style: AppTextStyles.bodySm
                  .copyWith(color: Colors.grey[700], height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.orangeSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.orange, size: 22),
        ),
        title: Text(title, style: AppTextStyles.headingSm),
        subtitle: Text(subtitle,
            style: AppTextStyles.bodySm.copyWith(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
