// lib/core/enums/user_role.dart
enum UserRole {
  client,
  admin,
  superAdmin;

  String get displayName {
    switch (this) {
      case UserRole.client:
        return 'عميل';
      case UserRole.admin:
        return 'مدير';
      case UserRole.superAdmin:
        return 'مدير متقدم';
    }
  }

  String get value {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'super_admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'client':
        return UserRole.client;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.client;
    }
  }
}
