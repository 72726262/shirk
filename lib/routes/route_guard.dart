// // lib/routes/route_guard.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
// import 'package:mmm/routes/route_names.dart';

// class RouteGuard {
//   static Future<String?> checkAccess({
//     required BuildContext context,
//     required String routeName,
//     required String requiredRole,
//   }) async {
//     final authState = context.read<AuthCubit>().state;

//     // إذا لم يكن مسجلاً دخول
//     if (authState is! Authenticated) {
//       return RouteNames.login;
//     }

//     // التحقق من الصلاحية
//     if (!_hasRequiredRole(authState.role, requiredRole)) {
//       // إعادة توجيه بناءً على الدور
//       return authState.isAdmin
//           ? RouteNames.adminDashboard
//           : RouteNames.dashboard;
//     }

//     // مسموح بالوصول
//     return null;
//   }

//   static bool _hasRequiredRole(String userRole, String requiredRole) {
//     const roleHierarchy = ['client', 'admin', 'super_admin'];

//     final userIndex = roleHierarchy.indexOf(userRole);
//     final requiredIndex = roleHierarchy.indexOf(requiredRole);

//     return userIndex >= requiredIndex;
//   }
// }
