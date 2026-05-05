import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { admin, cashier }

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.admin => 'admin',
        UserRole.cashier => 'cashier',
      };

  static UserRole fromString(String? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      _ => UserRole.cashier,
    };
  }
}

class AppUser extends Equatable {
  final String uid;
  final String name;
  final UserRole role;
  final String storeName;

  const AppUser({
    required this.uid,
    required this.name,
    required this.role,
    required this.storeName,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: (data['uid'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      role: UserRoleX.fromString(data['role'] as String?),
      storeName: (data['storeName'] ?? '') as String,
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
      'role': role.value,
      'storeName': storeName,
    };
  }

  @override
  List<Object?> get props => [uid, name, role, storeName];
}
