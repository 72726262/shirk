import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_dashboard_cubit.dart';
import 'package:mmm/presentation/widgets/skeleton_loader.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  @override
  void initState() {
    super.initState();
    context.read<AdminDashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading) {
          return const CardSkeletonLoader(count: 4);
        }

        if (state is AdminDashboardError) {
          return Center(child: Text(state.message));
        }

        if (state is AdminDashboardLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: Dimensions.spaceL),
                
                // Revenue Chart
                _buildRevenueChart(state),
                const SizedBox(height: Dimensions.spaceXL),
                
                // Client Growth Chart
                _buildClientGrowthChart(state),
                const SizedBox(height: Dimensions.spaceXL),
                
                // Project Status Distribution
                _buildProjectStatusChart(state),
                const SizedBox(height: Dimensions.spaceXL),
                
                // Units Sales Chart
                _buildUnitsSalesChart(state),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'تحليلات المنصة',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        DropdownButton<String>(
          value: 'last_6_months',
          items: const [
            DropdownMenuItem(value: 'last_month', child: Text('آخر شهر')),
            DropdownMenuItem(value: 'last_3_months', child: Text('آخر 3 أشهر')),
            DropdownMenuItem(value: 'last_6_months', child: Text('آخر 6 أشهر')),
            DropdownMenuItem(value: 'last_year', child: Text('آخر سنة')),
          ],
          onChanged: (value) {
            // TODO: Implement filtering
          },
        ),
      ],
    );
  }

  Widget _buildRevenueChart(AdminDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإيرادات الشهرية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceM),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 50000),
                        const FlSpot(1, 75000),
                        const FlSpot(2, 60000),
                        const FlSpot(3, 90000),
                        const FlSpot(4, 85000),
                        const FlSpot(5, 100000),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientGrowthChart(AdminDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نمو العملاء',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceM),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
                          if (value.toInt() < months.length) {
                            return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 10),
                        const FlSpot(1, 25),
                        const FlSpot(2, 45),
                        const FlSpot(3, 70),
                        const FlSpot(4, 95),
                        const FlSpot(5, 120),
                      ],
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectStatusChart(AdminDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع حالة المشاريع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceM),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      title: 'قريباً',
                      color: AppColors.info,
                      radius: 100,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: 'قيد التنفيذ',
                      color: AppColors.primary,
                      radius: 100,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: 'مكتمل',
                      color: AppColors.success,
                      radius: 100,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      value: 10,
                      title: 'متوقف',
                      color: Colors.orange,
                      radius: 100,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsSalesChart(AdminDashboardLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'مبيعات الوحدات حسب المشروع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceM),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const projects = ['A', 'B', 'C', 'D'];
                          if (value.toInt() < projects.length) {
                            return Text(projects[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: 80, color: AppColors.success, width: 20),
                        BarChartRodData(toY: 100, color: AppColors.info, width: 20),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: 60, color: AppColors.success, width: 20),
                        BarChartRodData(toY: 80, color: AppColors.info, width: 20),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(toY: 45, color: AppColors.success, width: 20),
                        BarChartRodData(toY: 60, color: AppColors.info, width: 20),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(toY: 90, color: AppColors.success, width: 20),
                        BarChartRodData(toY: 120, color: AppColors.info, width: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Dimensions.spaceM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(AppColors.success, 'مباع'),
                const SizedBox(width: Dimensions.spaceL),
                _buildLegendItem(AppColors.info, 'إجمالي'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
