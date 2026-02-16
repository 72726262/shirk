import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:mmm/data/models/unit_model.dart';
import 'package:mmm/data/repositories/project_repository.dart'; // Added import

import 'package:mmm/presentation/screens/projects/tabs/project_units_tab.dart';
import 'package:mmm/presentation/screens/admin/dialogs/add_edit_unit_dialog.dart';
import 'package:mmm/presentation/screens/admin/dialogs/edit_project_dialog.dart';
import 'package:mmm/presentation/cubits/admin/units_management_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/presentation/widgets/common/location_button.dart';
import 'package:mmm/presentation/cubits/projects/payments_cubit.dart';
import 'package:mmm/data/repositories/payments_repository.dart';
import 'package:mmm/data/models/installment_model.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ProjectsCubit _localProjectsCubit; // Local cubit instance

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Initialize local cubit to avoid polluting global projects list state
    _localProjectsCubit = ProjectsCubit(
      projectRepository: context.read<ProjectRepository>(),
    );
    _localProjectsCubit.loadProjectDetail(widget.projectId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _localProjectsCubit.close(); // Dispose local cubit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ر.س', decimalDigits: 0);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PaymentsCubit(context.read<PaymentsRepository>())
            ..loadProjectPayments(widget.projectId),
        ),
        BlocProvider.value(
          value: _localProjectsCubit,
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<ProjectsCubit, ProjectsState>(
          builder: (context, state) {
            if (state is ProjectsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProjectDetailLoaded) {
              final project = state.project;

              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // App Bar with Image
                        SliverAppBar(
                          expandedHeight: 250,
                          pinned: true,
                          backgroundColor: AppColors.primary,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(project.name),
                            background: (project.imageUrl != null &&
                                    project.imageUrl!.isNotEmpty &&
                                    project.imageUrl != 'file:///')
                                ? Image.network(
                                    project.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primaryDark,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.business,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.business,
                                      size: 80,
                                      color: Colors.white,
                                    ),
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
                              _buildUnitsTab(state.units, project),

                              // Payments Tab
                              _buildPaymentsTab(project, currency),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom Action for Subscription
                  _buildBottomAction(context, project),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAddUnitDialog(ProjectModel project) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<UnitsManagementCubit>(),
        child: AddEditUnitDialog(project: project),
      ),
    ).then((_) {
      // Refresh project to get updated stats (triggered by DB)
      if (mounted) {
        _localProjectsCubit.loadProjectDetail(widget.projectId); // Use local cubit
      }
    });
  }

  void _showDeleteConfirmation(
      BuildContext context, String projectId, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف مشروع "$projectName"؟\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(context);

              // Perform delete using local cubit (updates repo -> stream)
              await _localProjectsCubit.deleteProject(projectId);

              if (context.mounted) {
                // Return to previous screen
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, dynamic project) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
      child: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isAdmin = state is Authenticated &&
                (state.user.role == 'admin' ||
                    state.user.role == 'super_admin');

            return Row(
              children: [
                if (!isAdmin)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          RouteNames.selectUnit,
                          arguments: project,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.spaceM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusL),
                        ),
                      ),
                      child: const Text(
                        'استثمر الآن',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (isAdmin) ...[
                  if (!isAdmin) const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (project is ProjectModel) {
                          _showAddUnitDialog(project);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.spaceM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusL),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 24),
                      label: const Text(
                        'إضافة وحدة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildOverviewTab(dynamic project, NumberFormat currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الوصف',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceM),
          Text(
            project.description ?? 'لا يوجد وصف متاح',
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: Dimensions.spaceXL),
          _buildInfoCard('معلومات المشروع', [
            _buildInfoRow('الموقع', project.location ?? '-'),
            _buildInfoRow('المطور', project.developer ?? '-'),
            _buildInfoRow(
              'القيمة الإجمالية',
              currency.format(project.totalValue ?? 0),
            ),
            _buildInfoRow(
              'تاريخ البدء',
              project.startDate != null
                  ? DateFormat('dd/MM/yyyy').format(project.startDate!)
                  : '-',
            ),
            _buildInfoRow(
              'تاريخ الانتهاء المتوقع',
              project.expectedCompletionDate != null
                  ? DateFormat(
                      'dd/MM/yyyy',
                    ).format(project.expectedCompletionDate!)
                  : '-',
            ),
          ]),
          const SizedBox(height: Dimensions.spaceXL),
          // Location Button - Updated: Use lat/lng if available
          if (project.locationLat != null && project.locationLng != null)
            LocationButton(
              locationName: project.locationName ?? project.location ?? 'موقع المشروع',
              latitude: project.locationLat,
              longitude: project.locationLng,
              projectName: project.name,
            ),
            
          const SizedBox(height: Dimensions.spaceL),
          
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated &&
                  (state.user.role == 'admin' ||
                      state.user.role == 'super_admin')) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => EditProjectDialog(project: project),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('تعديل المشروع'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.spaceM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusM),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceM),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                           _showDeleteConfirmation(context, project.id, project.name);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('حذف المشروع'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.spaceM,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusM),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(dynamic project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceXXL),
      child: Column(
        children: [
          CircularProgressIndicator(
            value: (project.completionPercentage) / 100,
            strokeWidth: 8,
            backgroundColor: AppColors.gray200,
          ),
          const SizedBox(height: Dimensions.spaceL),
          Text(
            '${project.completionPercentage}%',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceXXL),
          const Text('سيتم إضافة المزيد من تفاصيل التقدم قريباً'),
        ],
      ),
    );
  }

  Widget _buildUnitsTab(List<UnitModel> units, dynamic project) {
    if (project is ProjectModel) {
      return ProjectUnitsTab(project: project);
    }
    return const Center(child: Text('جاري تحميل الوحدات...'));
  }
}

Widget _buildPaymentsTab(dynamic project, NumberFormat currency) {
  return BlocBuilder<PaymentsCubit, PaymentsState>(
    builder: (context, state) {
      if (state is PaymentsLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state is PaymentsError) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('خطأ في تحميل المدفوعات'), // Or state.message
              TextButton(
                onPressed: () => context
                    .read<PaymentsCubit>()
                    .loadProjectPayments(project.id),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      }
      if (state is PaymentsLoaded) {
        if (state.payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد مدفوعات مسجلة لهذا المشروع', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          itemCount: state.payments.length,
          itemBuilder: (context, index) {
            final payment = state.payments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: payment.isPaid 
                      ? AppColors.success.withOpacity(0.1) 
                      : AppColors.warning.withOpacity(0.1),
                  child: Icon(
                    payment.isPaid ? Icons.check : Icons.timer,
                    color: payment.isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
                title: Text('دفعة رقم ${payment.installmentNumber}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(payment.dueDate)),
                    if (payment.clientName != null)
                      Text('العميل: ${payment.clientName}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                trailing: Text(
                  currency.format(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          },
        );
      }
      return const SizedBox.shrink();
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
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
