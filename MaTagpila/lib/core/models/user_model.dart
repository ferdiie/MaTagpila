// lib/core/models/user_model.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, cashier }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.cashier:
        return 'cashier';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Store Owner';
      case UserRole.cashier:
        return 'Cashier';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'cashier':
        return UserRole.cashier;
      default:
        return UserRole.cashier;
    }
  }
}

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final String storeId;
  final String storeName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.storeId,
    required this.storeName,
    required this.createdAt,
    this.photoUrl,
    this.lastLoginAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isCashier => role == UserRole.cashier;

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRoleExtension.fromString(data['role'] ?? 'cashier'),
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.name,
        'storeId': storeId,
        'storeName': storeName,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      };

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    UserRole? role,
    String? storeName,
    DateTime? lastLoginAt,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        storeId: storeId,
        storeName: storeName ?? this.storeName,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      );

  @override
  List<Object?> get props =>
      [uid, email, displayName, role, storeId, storeName];
}
