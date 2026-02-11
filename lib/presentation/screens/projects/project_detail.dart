import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ Add
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/custom/progress_timeline.dart';
import 'package:mmm/core/utils/kyc_guard.dart'; // ✅ Add
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart'; // ✅ Add

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Project Header
              SliverAppBar(
                expandedHeight: 300,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Project Images
                      PageView.builder(
                        itemCount: 5,
                        onPageChanged: (index) {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            'https://via.placeholder.com/800x600/102289/FFFFFF?text=Project+Image+${index + 1}',
                            fit: BoxFit.cover,
                          );
                        },
                      ),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Project Info Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(Dimensions.spaceL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'برج النخيل السكني الفاخر',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: Dimensions.spaceS),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: Dimensions.spaceXS),
                                  Text(
                                    'حي النخيل، القاهرة الجديدة',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.spaceM),
                              Row(
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.timeline,
                                    value: '75%',
                                    label: 'الإنجاز',
                                  ),
                                  const SizedBox(width: Dimensions.spaceL),
                                  _buildInfoItem(
                                    icon: Icons.apartment,
                                    value: '12',
                                    label: 'المتاحة',
                                  ),
                                  const SizedBox(width: Dimensions.spaceL),
                                  _buildInfoItem(
                                    icon: Icons.attach_money,
                                    value: '1.2M',
                                    label: 'ج.م',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Image Indicator
                      Positioned(
                        bottom: 120,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedImageIndex == index
                                    ? AppColors.accent
                                    : AppColors.white.withOpacity(0.5),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                  ),
                ],
              ),

              // Tab Bar
              SliverPersistentHeader(
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'التقدم'),
                      Tab(text: 'الوسائط'),
                      Tab(text: 'التقارير'),
                      Tab(text: 'المدفوعات'),
                      Tab(text: 'المستندات'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProgressTab(),
              _buildMediaTab(),
              _buildReportsTab(),
              _buildPaymentsTab(),
              _buildDocumentsTab(),
            ],
          ),
        ),

        // Join Project Button - Protected by KYC
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final authState = context.read<AuthCubit>().state;
            if (authState is! Authenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
              );
              return;
            }

            // ✅ KYC Protection - Prevent subscription until verified
            final canProceed = await KycGuard.requireKycApproval(
              context,
              authState.user,
              customMessage: 'للانضمام إلى المشروع، يجب أن يكون حسابك موثّقاً.',
            );

            if (!canProceed) return; // ❌ Blocked if not approved

            // ✅ Proceed only if KYC approved
            Navigator.pushNamed(
              context,
              '/join-project',
              arguments: {'projectId': widget.projectId},
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('انضم للمشروع'),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.black,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.white),
        const SizedBox(height: Dimensions.spaceXS),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.white),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Overview
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نظرة عامة على التقدم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: AppColors.gray200,
                  color: AppColors.primary,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: Dimensions.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '75% مكتمل',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '25% متبقي',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Timeline
          const Text(
            'الجدول الزمني',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),

          ProgressTimeline(
            items: [
              TimelineItem(
                title: 'التخطيط والتصميم',
                date: 'يناير 2024',
                description: 'اكتمال التصاميم الهندسية والإنشائية',
              ),
              TimelineItem(
                title: 'الأساسات',
                date: 'مارس 2024',
                description: 'انتهاء أعمال الحفر والأساسات',
              ),
              TimelineItem(
                title: 'الهيكل الإنشائي',
                date: 'يوليو 2024',
                description: 'اكتمال الهيكل الخرساني',
              ),
              TimelineItem(
                title: 'التشطيبات',
                date: 'ديسمبر 2024',
                description: 'أعمال التشطيبات الداخلية والخارجية',
              ),
              TimelineItem(
                title: 'التسليم',
                date: 'يونيو 2025',
                description: 'تسليم الوحدات للعملاء',
              ),
            ],
            currentStep: 2,
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Recent Updates
          const Text(
            'آخر التحديثات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),

          ...List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusS,
                          ),
                        ),
                        child: Text(
                          'تحديث تقني',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'منذ 3 أيام',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  const Text(
                    'اكتمال أعمال الهيكل الخرساني للدور العاشر',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  const Text(
                    'تم اليوم الانتهاء من صب الخرسانة للدور العاشر بكامل مواصفات الجودة المطلوبة. تم فحص العينات وتحقيق جميع المعايير الهندسية.',
                  ),
                  const SizedBox(height: Dimensions.spaceM),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (context, imgIndex) {
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(
                            left: imgIndex == 0 ? 0 : Dimensions.spaceM,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusM,
                            ),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://via.placeholder.com/200x150/102289/FFFFFF?text=Update',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Dimensions.spaceL,
        mainAxisSpacing: Dimensions.spaceL,
        childAspectRatio: 1,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Open full screen viewer
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusM),
              image: DecorationImage(
                image: NetworkImage(
                  'https://via.placeholder.com/300x300/102289/FFFFFF?text=Image+${index + 1}',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                if (index == 0)
                  const Positioned(
                    top: Dimensions.spaceS,
                    right: Dimensions.spaceS,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تقرير التقدم الشهري - ${index + 1}/2024',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      'تقرير مفصل عن أعمال الشهر مع الصور والقياسات',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      '15 MB • تم الرفع: 2024-03-15',
                      style: TextStyle(color: AppColors.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.download), onPressed: () {}),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isPaid = index % 3 == 0;
        final isOverdue = index == 2;
        final isPending = !isPaid && !isOverdue;

        return Container(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'القسط ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceM,
                      vertical: Dimensions.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? AppColors.success.withOpacity(0.1)
                          : isOverdue
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Text(
                      isPaid
                          ? 'مدفوع'
                          : isOverdue
                          ? 'متأخر'
                          : 'معلق',
                      style: TextStyle(
                        color: isPaid
                            ? AppColors.success
                            : isOverdue
                            ? AppColors.error
                            : AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المبلغ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        '25,000 ج.م',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'تاريخ الاستحقاق',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${15 + index * 30}/03/2024',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isPaid) ...[
                const SizedBox(height: Dimensions.spaceL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // ✅ KYC Protection for payments\r
                      final authState = context.read<AuthCubit>().state;
                      if (authState is! Authenticated) return;

                      final canProceed = await KycGuard.requireKycApproval(
                        context,
                        authState.user,
                        customMessage:
                            'لإتمام الدفع، يجب أن يكون حسابك موثّقاً.',
                      );

                      if (!canProceed) return;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('دفع الآن'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: 5,
      itemBuilder: (context, index) {
        final documentTypes = [
          'عقد الشراكة',
          'مخططات هندسية',
          'دفتر الشروط',
          'تقرير الجودة',
          'شهادة الضمان',
        ];

        final icons = [
          Icons.contact_page,
          Icons.architecture,
          Icons.description,
          Icons.assignment,
          Icons.verified,
        ];

        final colors = [
          AppColors.primary,
          AppColors.info,
          AppColors.warning,
          AppColors.success,
          AppColors.accent,
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
          padding: const EdgeInsets.all(Dimensions.spaceL),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors[index].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Icon(icons[index], color: colors[index], size: 24),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      documentTypes[index],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Dimensions.spaceXS),
                    Text(
                      'تم الرفع: 2024-02-${15 + index} • 2.${index + 1} MB',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {},
                  ),
                  if (index == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.success),
                          SizedBox(width: Dimensions.spaceXS),
                          Text(
                            'موقعة',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
