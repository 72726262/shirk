import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/custom/project_card.dart';
import 'package:mmm/presentation/widgets/custom/project_card_simple.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المشاريع'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'جميع المشاريع'),
            Tab(text: 'قيد التنفيذ'),
            Tab(text: 'قيد الإعداد'),
            Tab(text: 'مكتملة'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'ابحث عن مشروع...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceL,
                        vertical: Dimensions.spaceM,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('سكني', 'residential'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('تجاري', 'commercial'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('مختلط', 'mixed'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('أعلى سعر', 'price_high'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('أقل سعر', 'price_low'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Projects List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProjectsList(),
                _buildOngoingProjects(),
                _buildUpcomingProjects(),
                _buildCompletedProjects(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildProjectsList() {
    // Dummy data for demonstration
    final projects = [
      {
        'image':
            'https://via.placeholder.com/300x200/102289/FFFFFF?text=Project+1',
        'title': 'برج النخيل السكني',
        'location': 'حي النخيل، القاهرة الجديدة',
        'progress': 75.0,
        'status': 'قيد التنفيذ',
        'price': '1,200,000 ج.م',
        'availableUnits': 12,
      },
      {
        'image':
            'https://via.placeholder.com/300x200/FFB400/000000?text=Project+2',
        'title': 'مول التجارة العالمي',
        'location': 'وسط البلد، القاهرة',
        'progress': 30.0,
        'status': 'قيد التنفيذ',
        'price': '3,500,000 ج.م',
        'availableUnits': 8,
      },
      {
        'image':
            'https://via.placeholder.com/300x200/28A745/FFFFFF?text=Project+3',
        'title': 'فيلات الريف الساحلي',
        'location': 'الساحل الشمالي',
        'progress': 100.0,
        'status': 'مكتمل',
        'price': '5,000,000 ج.م',
        'availableUnits': 3,
      },
      {
        'image':
            'https://via.placeholder.com/300x200/17A2B8/FFFFFF?text=Project+4',
        'title': 'أبراج الأعمال',
        'location': 'المعادي، القاهرة',
        'progress': 15.0,
        'status': 'قيد الإعداد',
        'price': '2,800,000 ج.م',
        'availableUnits': 20,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
          child: ProjectCardSimple(
            imageUrl: project['image'].toString(),
            title: project['title'].toString(),
            location: project['location'].toString(),
            progress: project['progress'] as double,
            status: project['status'].toString(),
            price: project['price'].toString(),
            availableUnits: project['availableUnits'] as int,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/project-detail',
                arguments: {'projectId': 'project_$index'},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOngoingProjects() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: AppColors.primary),
          SizedBox(height: Dimensions.spaceL),
          Text(
            'المشاريع قيد التنفيذ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: Dimensions.spaceM),
          Text(
            'يتم حالياً تحميل المشاريع الجارية',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingProjects() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.update, size: 64, color: AppColors.warning),
          SizedBox(height: Dimensions.spaceL),
          Text(
            'المشاريع القادمة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: Dimensions.spaceM),
          Text(
            'يتم تجهيز المشاريع القادمة',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedProjects() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: AppColors.success),
          SizedBox(height: Dimensions.spaceL),
          Text(
            'المشاريع المكتملة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: Dimensions.spaceM),
          Text(
            'يتم تحميل المشاريع المنتهية',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
