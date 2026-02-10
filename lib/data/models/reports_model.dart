import 'package:equatable/equatable.dart';

class ReportsModel extends Equatable {
  final List<double> revenueData;
  final int newClients;
  final int newProjects;
  final double totalPayments;
  final double conversionRate;
  
  const ReportsModel({
    required this.revenueData,
    required this.newClients,
    required this.newProjects,
    required this.totalPayments,
    required this.conversionRate,
  });
  
  factory ReportsModel.fromJson(Map<String, dynamic> json) {
    return ReportsModel(
      revenueData: (json['revenue_data'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      newClients: json['new_clients'] as int? ?? 0,
      newProjects: json['new_projects'] as int? ?? 0,
      totalPayments: (json['total_payments'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
  
  @override
  List<Object?> get props => [revenueData, newClients, newProjects, totalPayments, conversionRate];
}
