// lib/screens/add_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';

const _categories = [
  'Food Grocery',
  'Frozen Goods',
  'Canned Goods',
  'Powdered Sachets',
  'Snacks',
  'Alcoholic Drinks',
  'Beverages',
  'School Supplies',
  'Household & Personal Care',
  'Condiments',
  'Cigarettes',
  'Others',
];

const _units = ['pc', 'kg', 'g', 'L', 'mL', 'pack', 'bottle', 'box', 'sachet'];

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _storeCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();

  String _selectedCategory = 'Food Grocery';
  String _selectedUnit = 'pc';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _storeCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = ref.read(authServiceProvider);
    if (auth.currentUserId.isEmpty) {
      _showSnack('Please log in first.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(pricesServiceProvider).addItem(
            name: _nameCtrl.text.trim(),
            price: double.parse(_priceCtrl.text.trim()),
            unit: _selectedUnit,
            category: _selectedCategory,
            store: _storeCtrl.text.trim(),
            addedBy: auth.currentUserEmail,
            barcode: _barcodeCtrl.text.trim().isNotEmpty
                ? _barcodeCtrl.text.trim()
                : null,
          );
      _formKey.currentState?.reset();
      _nameCtrl.clear();
      _priceCtrl.clear();
      _storeCtrl.clear();
      _barcodeCtrl.clear();
      setState(() {
        _selectedCategory = 'Food Grocery';
        _selectedUnit = 'pc';
      });
      _showSnack('Item added successfully!');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header — matches POS style ─────────────────
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.orangeSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: AppColors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add Price Info',
                      style: AppTextStyles.headingLg,
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 42,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.orange,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),

            // ── Subtitle ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 20),
              child: Text(
                'Keep your store inventory accurate and complete.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textGrey),
              ),
            ),

            // ── Item Name ──────────────────────────────────
            _FormSection(
              label: 'Item Name',
              child: _Field(
                hint: 'e.g. Camia, Special Puto Calasiao',
                controller: _nameCtrl,
                prefixIcon: Icons.label_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Item name is required'
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── Price + Unit row ───────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _FormSection(
                    label: 'Price (₱)',
                    child: _Field(
                      hint: '0.00',
                      controller: _priceCtrl,
                      prefixIcon: Icons.payments_outlined,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter price';
                        final d = double.tryParse(v.trim());
                        if (d == null || d <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormSection(
                    label: 'Unit',
                    child: _DropdownField<String>(
                      value: _selectedUnit,
                      items: _units,
                      onChanged: (v) => setState(() => _selectedUnit = v!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Category ───────────────────────────────────
            _FormSection(
              label: 'Category',
              child: _DropdownField<String>(
                value: _selectedCategory,
                items: _categories,
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
            ),
            const SizedBox(height: 16),

            // ── Submit Button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.orange.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Item',
                            style: AppTextStyles.headingSm.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FORM SECTION LABEL WRAPPER
// ─────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  TEXT FIELD
// ─────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMd.copyWith(
          color: AppColors.textGrey.withValues(alpha: 0.6),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.orange, size: 20)
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DROPDOWN FIELD
// ─────────────────────────────────────────────
class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textDark),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.orange),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }
}
