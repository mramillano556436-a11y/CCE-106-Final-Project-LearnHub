import '../utils/format.dart';

class UserRole {
  static const client = 'client';
  static const tutor = 'tutor';
  static const admin = 'admin';
}

class AccountStatus {
  static const active = 'active';
  static const suspended = 'suspended';
  static const deleted = 'deleted';
}

/// A document in the `users` collection.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String role;
  final String status;
  final bool profileComplete;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.photoUrl = '',
    required this.role,
    this.status = AccountStatus.active,
    this.profileComplete = false,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isTutor => role == UserRole.tutor;
  bool get isClient => role == UserRole.client;
  bool get isActive => status == AccountStatus.active;

  factory AppUser.fromMap(String uid, Map<String, dynamic> d) => AppUser(
        uid: uid,
        name: d['name'] as String? ?? '',
        email: d['email'] as String? ?? '',
        phone: d['phone'] as String? ?? '',
        photoUrl: d['photoUrl'] as String? ?? '',
        role: d['role'] as String? ?? UserRole.client,
        status: d['status'] as String? ?? AccountStatus.active,
        profileComplete: d['profileComplete'] as bool? ?? false,
        createdAt: toDate(d['createdAt']),
      );
}
