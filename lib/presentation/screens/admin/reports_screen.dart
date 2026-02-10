import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/admin/admin_cubit.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadReports(_selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التقارير والإحصائيات'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
              context.read<AdminCubit>().loadReports(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('أسبوع')),
              const PopupMenuItem(value: 'month', child: Text('شهر')),
              const PopupMenuItem(value: 'year', child: Text('سنة')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReportsLoaded) {
            final reports = state.reports;

            return RefreshIndicator(
              onRefresh: () async {
                await context.read<AdminCubit>().refreshReports(_selectedPeriod);
              },
              child: ListView(
                padding: const EdgeInsets.all(Dimensions.spaceXXL),
                children: [
                  // Revenue Chart
                  _buildChartCard(
                    'الإيرادات',
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(Dimensions.spaceL),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: reports.revenueData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value);
                              }).toList(),
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Statistics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: Dimensions.spaceL,
                    crossAxisSpacing: Dimensions.spaceL,
                    children: [
                      _buildStatCard('عملاء جدد', reports.newClients.toString(), Icons.person_add, AppColors.success),
                      _buildStatCard('مشاريع جديدة', reports.newProjects.toString(), Icons.business, AppColors.info),
                      _buildStatCard('إجمالي المدفوعات', reports.totalPayments.toString(), Icons.payment, AppColors.warning),
                      _buildStatCard('معدل التحويل', '${reports.conversionRate}%', Icons.trending_up, AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceXL),

                  // Export Button
                  ElevatedButton.icon(
                    onPressed: () => _exportReport(),
                    icon: const Icon(Icons.download),
                    label: const Text('تصدير التقرير (PDF)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceL),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: Dimensions.spaceL),
          chart,
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: Dimensions.spaceM),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: Dimensions.spaceS),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _exportReport() async {
    await context.read<AdminCubit>().exportReport(_selectedPeriod);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تصدير التقرير بنجاح'), backgroundColor: AppColors.success),
      );
    }
  }
}
