// lib/screens/add_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';

const _categories = [
  'General',
  'Food & Grocery',
  'Beverages',
  'Household',
  'Personal Care',
  'Medicine',
  'School Supplies',
  'Other',
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

  String _selectedCategory = 'General';
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
        _selectedCategory = 'General';
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text('Add Price Info', style: AppTextStyles.displayMd),
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
            Text('Help your community find the best prices.',
                style: AppTextStyles.bodyMd),
            const SizedBox(height: 24),

            // Name
            _Field(
              label: 'Item Name',
              hint: 'e.g. Camia, Special Puto Calasiao',
              controller: _nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Item name is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // Price + Unit row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _Field(
                    label: 'Price (₱)',
                    hint: '0.00',
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter price';
                      }
                      final d = double.tryParse(v.trim());
                      if (d == null || d <= 0) return 'Invalid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit', style: AppTextStyles.labelMd),
                      const SizedBox(height: 6),
                      _DropdownField<String>(
                        value: _selectedUnit,
                        items: _units,
                        onChanged: (v) => setState(() => _selectedUnit = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: AppTextStyles.labelMd),
                const SizedBox(height: 6),
                _DropdownField<String>(
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Price'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMd,
          ),
        ),
      ],
    );
  }
}

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
      initialValue: value,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
          .toList(),
      onChanged: onChanged,
    );
  }
}
