// lib/core/utils/dashboard_router.dart
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/core/enums/user_role.dart';

class DashboardRouter {
  /// Get the appropriate dashboard route based on user role
  static String getDashboardRoute(String role) {
    final userRole = UserRole.fromString(role);
    
    switch (userRole) {
      case UserRole.admin:
      case UserRole.superAdmin:
        return RouteNames.adminDashboard;
      case UserRole.client:
      default:
        return RouteNames.clientDashboard;
    }
  }

  /// Check if user has admin privileges
  static bool isAdmin(String role) {
    final userRole = UserRole.fromString(role);
    return userRole == UserRole.admin || userRole == UserRole.superAdmin;
  }

  /// Check if user is super admin
  static bool isSuperAdmin(String role) {
    final userRole = UserRole.fromString(role);
    return userRole == UserRole.superAdmin;
  }
}
