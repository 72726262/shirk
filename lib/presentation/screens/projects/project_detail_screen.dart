import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:intl/intl.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    context.read<ProjectsCubit>().loadProjectDetail(widget.projectId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ProjectsCubit, ProjectsState>(
        builder: (context, state) {
          if (state is ProjectsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProjectDetailLoaded) {
            final project = state.project;

            return CustomScrollView(
              slivers: [
                // App Bar with Image
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(project.name),
                    background: project.imageUrl != null
                        ? Image.network(project.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                            child: const Icon(Icons.business, size: 80, color: AppColors.white),
                          ),
                  ),
                ),

                // Tabs
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'نظرة عامة'),
                        Tab(text: 'التقدم'),
                        Tab(text: 'الوحدات'),
                        Tab(text: 'المدفوعات'),
                      ],
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                    ),
                  ),
                ),

                // Tab Content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Overview Tab
                      _buildOverviewTab(project, currency),

                      // Progress Tab
                      _buildProgressTab(project),

                      // Units Tab
                      _buildUnitsTab(project),

                      // Payments Tab
                      _buildPaymentsTab(project, currency),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOverviewTab(dynamic project, NumberFormat currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الوصف', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: Dimensions.spaceM),
          Text(project.description, style: const TextStyle(height: 1.6)),
          const SizedBox(height: Dimensions.spaceXL),

          _buildInfoCard('معلومات المشروع', [
            _buildInfoRow('الموقع', project.location),
            _buildInfoRow('المطور', project.developer),
            _buildInfoRow('القيمة الإجمالية', currency.format(project.totalValue)),
            _buildInfoRow('تاريخ البدء', DateFormat('dd/MM/yyyy').format(project.startDate)),
            _buildInfoRow('تاريخ الانتهاء المتوقع', DateFormat('dd/MM/yyyy').format(project.expectedEndDate)),
          ]),
        ],
      ),
    );
  }

  Widget _buildProgressTab(dynamic project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceXXL),
      child: Column(
        children: [
          CircularProgressIndicator(value: project.progress / 100, strokeWidth: 8, backgroundColor: AppColors.gray200),
          const SizedBox(height: Dimensions.spaceL),
          Text('${project.progress}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: Dimensions.spaceXXL),

          // Progress milestones would go here
          Text('سيتم إضافة المزيد من تفاصيل التقدم قريباً'),
        ],
      ),
    );
  }

  Widget _buildUnitsTab(dynamic project) {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 5, // Placeholder
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
          child: ListTile(
            title: Text('وحدة ${index + 1}'),
            subtitle: const Text('متاح'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab(dynamic project, NumberFormat currency) {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 3, // Placeholder
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
          child: ListTile(
            title: Text('دفعة ${index + 1}'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
            trailing: Text(currency.format(50000), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceXL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: Dimensions.spaceL),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
