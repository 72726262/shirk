import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/custom/project_card.dart';
import 'package:mmm/presentation/widgets/skeleton/skeleton_grid.dart';
import 'package:mmm/presentation/widgets/common/error_widget.dart'
    as error_widgets;
import 'package:mmm/data/models/project_model.dart';
import 'package:mmm/presentation/cubits/projects/projects_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  bool _isGridView = true;
  ProjectStatus? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProjectsCubit>().loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المشاريع المتاحة'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() => _isGridView = !_isGridView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            color: AppColors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                context.read<ProjectsCubit>().searchProjects(value);
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن مشروع...',
                prefixIcon: const Icon(Icons.search, color: AppColors.gray500),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.gray500),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          context.read<ProjectsCubit>().searchProjects('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceL,
                  vertical: Dimensions.spaceM,
                ),
              ),
            ),
          ),

          // Active Filters
          if (_selectedStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceL,
                vertical: Dimensions.spaceM,
              ),
              color: AppColors.white,
              child: Row(
                children: [
                  Chip(
                    label: Text(_getStatusText(_selectedStatus!)),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _selectedStatus = null);
                      context.read<ProjectsCubit>().filterProjects(null);
                    },
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                      context.read<ProjectsCubit>().loadProjects();
                    },
                    child: const Text('مسح الكل'),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: BlocConsumer<ProjectsCubit, ProjectsState>(
              listener: (context, state) {
                if (state is ProjectsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      action: SnackBarAction(
                        label: 'إعادة المحاولة',
                        textColor: Colors.white,
                        onPressed: () {
                          context.read<ProjectsCubit>().loadProjects();
                        },
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ProjectsLoading) {
                  return _isGridView
                      ? const SkeletonGrid(itemCount: 6)
                      : const SkeletonGrid(
                          itemCount: 4,
                          crossAxisCount: 1,
                          childAspectRatio: 2,
                        );
                }

                if (state is ProjectsError) {
                  return Center(
                    child: error_widgets.CustomErrorWidget(
                      message: state.message,
                      onRetry: () {
                        context.read<ProjectsCubit>().loadProjects();
                      },
                    ),
                  );
                }

                if (state is ProjectsLoaded) {
                  if (state.projects.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<ProjectsCubit>().refreshProjects();
                    },
                    child: _isGridView
                        ? GridView.builder(
                            padding: Dimensions.screenPadding,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: Dimensions.spaceL,
                                  mainAxisSpacing: Dimensions.spaceL,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: state.projects.length,
                            itemBuilder: (context, index) {
                              final project = state.projects[index];
                              return ProjectCard.fromProject(
                                project: project,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.projectDetail,
                                    arguments: project.id,
                                  );
                                },
                              );
                            },
                          )
                        : ListView.separated(
                            padding: Dimensions.screenPadding,
                            itemCount: state.projects.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: Dimensions.spaceL),
                            itemBuilder: (context, index) {
                              final project = state.projects[index];
                              return ProjectCard.fromProject(
                                project: project,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.projectDetail,
                                    arguments: project.id,
                                  );
                                },
                              );
                            },
                          ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: Dimensions.spaceL),
          Text(
            _searchQuery.isNotEmpty
                ? 'لا توجد نتائج للبحث'
                : 'لا توجد مشاريع متاحة حالياً',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusXL),
            ),
          ),
          padding: const EdgeInsets.all(Dimensions.spaceXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spaceXL),

              // Title
              Text(
                'تصفية حسب',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: Dimensions.spaceXL),

              // Status Filters
              Text(
                'حالة المشروع',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: Dimensions.spaceM),

              Wrap(
                spacing: Dimensions.spaceM,
                runSpacing: Dimensions.spaceM,
                children: ProjectStatus.values.map((status) {
                  final isSelected = _selectedStatus == status;
                  return FilterChip(
                    label: Text(_getStatusText(status)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                      context.read<ProjectsCubit>().filterProjects(
                        _selectedStatus,
                      );
                      Navigator.pop(context);
                    },
                    backgroundColor: AppColors.gray100,
                    selectedColor: AppColors.primary.withOpacity(0.1),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: Dimensions.spaceXXL),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.upcoming:
        return 'قيد الإعداد';
      case ProjectStatus.inProgress:
        return 'قيد التنفيذ';
      case ProjectStatus.completed:
        return 'مكتمل';
      case ProjectStatus.onHold:
        return 'متوقف';
      case ProjectStatus.soldOut: // Added missing case
        return 'مباع بالكامل';
      case ProjectStatus.cancelled: // Added missing case
        return 'ملغي';
      default: // Added default
        return 'غير محدد'; // Or 'نشط' if appropriate
    }
  }
}
