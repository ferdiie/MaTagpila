import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/cashier_account_service.dart';
import '../core/theme/app_theme.dart';
import '../features/shared/services/firestore_services.dart';

class ManageCashiersScreen extends ConsumerStatefulWidget {
  const ManageCashiersScreen({super.key});

  @override
  ConsumerState<ManageCashiersScreen> createState() => _ManageCashiersScreenState();
}

class _ManageCashiersScreenState extends ConsumerState<ManageCashiersScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(String ownerUid, String storeName) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await CashierAccountService(FirebaseFirestore.instance).createCashierAccount(
        ownerUid: ownerUid,
        ownerStoreName: storeName,
        displayName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) {
        _nameCtrl.clear();
        _emailCtrl.clear();
        _passCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cashier account created. They can sign in with that email.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? e.code), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = FirebaseAuth.instance.currentUser;
    if (owner == null) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }

    final storeNameAsync = ref.watch(userStoreNameProvider);
    final storeName = storeNameAsync.valueOrNull ?? 'Your Store';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Store attendants', style: AppTextStyles.headingLg),
        elevation: 0,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textDark,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Create accounts for people who run the counter. They use the same catalog, POS, and sales history as your store.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Text('Your team', style: AppTextStyles.headingSm),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(owner.uid)
                .collection('cashiers')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Text('Could not load list: ${snap.error}',
                    style: const TextStyle(color: AppColors.error));
              }
              if (!snap.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.orange),
                ));
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Text('No attendants yet.', style: AppTextStyles.bodyMd.copyWith(color: Colors.grey));
              }
              return Column(
                children: docs.map((d) {
                  final m = d.data();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(m['name'] as String? ?? '—', style: AppTextStyles.headingSm),
                      subtitle: Text(m['email'] as String? ?? '', style: AppTextStyles.bodySm),
                      leading: const Icon(Icons.badge_outlined, color: AppColors.orange),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          Text('Add attendant', style: AppTextStyles.headingSm),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (login)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Valid email required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Temporary password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _submit(owner.uid, storeName),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
