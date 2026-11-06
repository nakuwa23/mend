import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

/// Profile stored at `users/{uid}`. The [role] field is only ever
/// changed by an admin in the Firebase console (enforced by security rules).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  bool get isStaff => role == UserRole.staff;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
        uid: uid,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        role: UserRole.fromName(data['role'] as String?),
      );

  /// Used when creating the profile at sign-up. New accounts are always students.
  Map<String, dynamic> toNewUserMap() => {
        'name': name,
        'email': email,
        'role': UserRole.student.name,
        'createdAt': FieldValue.serverTimestamp(),
      };