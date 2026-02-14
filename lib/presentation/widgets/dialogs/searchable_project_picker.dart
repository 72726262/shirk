import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';

class SearchableProjectPicker extends StatefulWidget {
  final List<ProjectModel> projects;
  final Function(ProjectModel) onProjectSelected;
  final String? selectedProjectId;

  const SearchableProjectPicker({
    super.key,
    required this.projects,
    required this.onProjectSelected,
    this.selectedProjectId,
  });

  @override
  State<SearchableProjectPicker> createState() =>
      _SearchableProjectPickerState();
}

class _SearchableProjectPickerState extends State<SearchableProjectPicker> {
  late List<ProjectModel> _filteredProjects;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredProjects = widget.projects;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProjects(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = widget.projects;
      } else {
        _filteredProjects = widget.projects.where((project) {
          final nameLower = project.name.toLowerCase();
          final locationLower = project.location?.toLowerCase() ?? '';
          final queryLower = query.toLowerCase();
          return nameLower.contains(queryLower) ||
              locationLower.contains(queryLower);
        }).toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'نشط':
        return AppColors.success;
      case 'pending':
      case 'قيد الإنشاء':
        return AppColors.warning;
      case 'completed':
      case 'مكتمل':
        return AppColors.info;
      default:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.radiusXL),
                  topRight: Radius.circular(Dimensions.radiusXL),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'اختر مشروع',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: TextField(
                controller: _searchController,
                onChanged: _filterProjects,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مشروع...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterProjects('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    borderSide: const BorderSide(color: AppColors.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.gray50,
                ),
              ),
            ),

            // Results Count
            if (_filteredProjects.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceL,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_filteredProjects.length} مشروع',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: Dimensions.spaceM),

            // Projects Grid
            Expanded(
              child: _filteredProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(height: Dimensions.spaceM),
                          Text(
                            'لا توجد مشاريع مطابقة',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceL,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: Dimensions.spaceM,
                            mainAxisSpacing: Dimensions.spaceM,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _filteredProjects.length,
                      itemBuilder: (context, index) {
                        final project = _filteredProjects[index];
                        final isSelected =
                            project.id == widget.selectedProjectId;

                        return InkWell(
                          onTap: () {
                            widget.onProjectSelected(project);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.gray300,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusL,
                              ),
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.05)
                                  : Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Project Image
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(
                                          Dimensions.radiusL,
                                        ),
                                        topRight: Radius.circular(
                                          Dimensions.radiusL,
                                        ),
                                      ),
                                      color: AppColors.gray200,
                                      image:
                                          project.imageUrl != null &&
                                              project.imageUrl!.isNotEmpty &&
                                              project.imageUrl != 'file:///' &&
                                              project.imageUrl!.startsWith('http')
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                project.imageUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                              onError: (_, __) {},
                                            )
                                          : null,
                                    ),
                                    child:
                                        project.imageUrl == null ||
                                            project.imageUrl!.isEmpty ||
                                            project.imageUrl == 'file:///'
                                        ? const Center(
                                            child: Icon(
                                              Icons.business,
                                              size: 40,
                                              color: AppColors.gray400,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),

                                // Project Details
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            Dimensions.spaceM,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Project Name
                                              Text(
                                                project.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),

                                              // Location & Status
                                              const SizedBox(height: 8),
                                              if (project.location != null)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 12,
                                                      color:
                                                          AppColors.textSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        project.location!,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    project.status.toString() ??
                                                        '',
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Dimensions.radiusS,
                                                      ),
                                                ),
                                                child: Text(
                                                  project.status.toString() ??
                                                      'نشط',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getStatusColor(
                                                      project.status.toString() ??
                                                          '',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: Dimensions.spaceL),
          ],
        ),
      ),
    );
  }
}
