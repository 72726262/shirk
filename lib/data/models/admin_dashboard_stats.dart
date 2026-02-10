import 'package:equatable/equatable.dart';

class AdminDashboardStats extends Equatable {
  final int totalClients;
  final int activeProjects;
  final double totalRevenue;
  final int pendingPayments;

  const AdminDashboardStats({
    required this.totalClients,
    required this.activeProjects,
    required this.totalRevenue,
    required this.pendingPayments,
  });

  @override
  List<Object?> get props => [totalClients, activeProjects, totalRevenue, pendingPayments];
}
