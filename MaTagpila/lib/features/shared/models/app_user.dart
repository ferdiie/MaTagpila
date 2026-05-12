// lib/features/shared/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { admin, cashier, disabled }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.admin => 'admin',
        UserRole.cashier => 'cashier',
        UserRole.disabled => 'disabled',
      };

  static UserRole fromString(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      'cashier' => UserRole.cashier,
      _ => UserRole.disabled,
    };
  }
}

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String storeName;
  final String storeId; // for cashiers: owner's uid; for owners: their own uid

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.storeName,
    required this.storeId,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier;

  factory AppUser.fromMap(Map<String, dynamic> data) {
    final uid = (data['uid'] ?? '') as String;
    return AppUser(
      uid: uid,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      role: UserRoleX.fromString(data['role'] as String?),
      storeName: (data['storeName'] ?? '') as String,
      // owners don't have a storeId field — fall back to their own uid
      storeId: (data['storeId'] ?? uid) as String,
    );
  }

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap({
      ...?doc.data(),
      'uid': doc.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'storeName': storeName,
      'storeId': storeId,
    };
  }

  @override
  List<Object?> get props => [uid, name, email, role, storeName, storeId];
}
