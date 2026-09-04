import '../core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String zone;
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.zone,
    required this.token,
  });

  bool get isCitizen => role == UserRole.citizen;
  bool get isTechnician => role == UserRole.technician;
  bool get isEngineer => role == UserRole.engineer;
  bool get isAuthority => role == UserRole.authority;
  bool get isAdmin => role == UserRole.admin;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? zone,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      zone: zone ?? this.zone,
      token: token ?? this.token,
    );
  }
}
