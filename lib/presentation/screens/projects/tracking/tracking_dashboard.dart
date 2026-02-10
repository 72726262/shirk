import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class ConstructionTrackingScreen extends StatefulWidget {
  final String projectId;

  const ConstructionTrackingScreen({super.key, required this.projectId});

  @override
  State<ConstructionTrackingScreen> createState() =>
      _ConstructionTrackingScreenState();
}

class _ConstructionTrackingScreenState
    extends State<ConstructionTrackingScreen> {
  int _currentImageIndex = 0;
  final CarouselController _carouselController = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // // Project Image Carousel
                  // CarouselSlider(
                  //   carouselController: _carouselController,
                  //   options: CarouselOptions(
                  //     height: 300,
                  //     viewportFraction: 1.0,
                  //     autoPlay: true,
                  //     autoPlayInterval: const Duration(seconds: 5),
                  //     onPageChanged: (index, reason) {
                  //       setState(() {
                  //         _currentImageIndex = index;
                  //       });
                  //     },
                  //   ),
                  //   items: List.generate(5, (index) {
                  //     return Container(
                  //       decoration: BoxDecoration(
                  //         image: DecorationImage(
                  //           image: NetworkImage(
                  //             'https://via.placeholder.com/800x600/102289/FFFFFF?text=Progress+${index + 1}',
                  //           ),
                  //           fit: BoxFit.cover,
                  //         ),
                  //       ),
                  //       child: Container(
                  //         decoration: BoxDecoration(
                  //           gradient: LinearGradient(
                  //             colors: [
                  //               Colors.black.withOpacity(0.6),
                  //               Colors.transparent,
                  //               Colors.transparent,
                  //               Colors.black.withOpacity(0.6),
                  //             ],
                  //             begin: Alignment.topCenter,
                  //             end: Alignment.bottomCenter,
                  //           ),
                  //         ),
                  //       ),
                  //     );
                  //   }),
                  // ),

                  // Progress Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(Dimensions.spaceL),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'برج النخيل السكني',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          const Text(
                            'تقدم البناء: المرحلة الثالثة',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceL),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '75% مكتمل',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: Dimensions.spaceXS),
                                    LinearProgressIndicator(
                                      value: 0.75,
                                      backgroundColor: AppColors.white
                                          .withOpacity(0.3),
                                      color: AppColors.accent,
                                      minHeight: 8,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Dimensions.spaceL),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.spaceL,
                                  vertical: Dimensions.spaceS,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusL,
                                  ),
                                ),
                                child: const Text(
                                  'قيد التنفيذ',
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Image Indicators
                  Positioned(
                    bottom: 140,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            //_carouselController.animateToPage(index);
                          },
                          child: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppColors.accent
                                  : AppColors.white.withOpacity(0.5),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {
                  _showCalendar();
                },
              ),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              // Timeline Section
              _buildTimelineSection(),

              // Media Gallery
              _buildMediaGallery(),

              // Reports Section
              _buildReportsSection(),

              // Updates Section
              _buildUpdatesSection(),

              // Engineering Notes
              _buildEngineeringNotes(),
            ]),
          ),
        ],
      ),

      // Live Camera Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showLiveCamera();
        },
        icon: const Icon(Icons.videocam),
        label: const Text('الكاميرا المباشرة'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.black,
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'الجدول الزمني',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // View full timeline
                },
                child: const Text('عرض التفاصيل'),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceL),

          // Timeline
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Timeline Header
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusL),
                      topRight: Radius.circular(Dimensions.radiusL),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline, color: AppColors.primary),
                      const SizedBox(width: Dimensions.spaceL),
                      const Text(
                        'التقدم الأسبوعي',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusS,
                          ),
                        ),
                        child: const Text(
                          'وفق الجدول',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Timeline Items
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  child: Column(
                    children: [
                      _buildTimelineItem(
                        week: 'الأسبوع الحالي',
                        date: '١٠ - ١٦ مارس',
                        progress: 4,
                        status: 'جاري التنفيذ',
                        statusColor: AppColors.info,
                      ),
                      _buildTimelineItem(
                        week: 'الأسبوع الماضي',
                        date: '٣ - ٩ مارس',
                        progress: 5,
                        status: 'مكتمل',
                        statusColor: AppColors.success,
                      ),
                      _buildTimelineItem(
                        week: 'قبل أسبوعين',
                        date: '٢٥ فبراير - ٢ مارس',
                        progress: 4,
                        status: 'مكتمل',
                        statusColor: AppColors.success,
                      ),
                      _buildTimelineItem(
                        week: 'قبل ثلاثة أسابيع',
                        date: '١٨ - ٢٤ فبراير',
                        progress: 3,
                        status: 'مكتمل',
                        statusColor: AppColors.success,
                      ),
                    ],
                  ),
                ),

                // Progress Chart
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(Dimensions.radiusL),
                      bottomRight: Radius.circular(Dimensions.radiusL),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مقارنة الفعلي مقابل المخطط',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'التقدم الفعلي',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: Dimensions.spaceXS),
                                const Text(
                                  '75%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'المخطط',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: Dimensions.spaceXS),
                                const Text(
                                  '78%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceL),
                      Stack(
                        children: [
                          // Planned Progress
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.gray300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Actual Progress
                          Container(
                            height: 8,
                            width: MediaQuery.of(context).size.width * 0.75,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'متقدم 3 أيام',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '3% فوق المتوقع',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String week,
    required String date,
    required int progress,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      child: Row(
        children: [
          // Week Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                week.contains('الحالي') ? '🔥' : '✓',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      week,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceXS),
                Text(
                  date,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceS),
                LinearProgressIndicator(
                  value: progress / 5,
                  backgroundColor: AppColors.gray200,
                  color: AppColors.primary,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGallery() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'معرض الوسائط',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      _showMediaFilter();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.grid_view),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceL),

          // Media Tabs
          DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: const [
                      Tab(text: 'الصور'),
                      Tab(text: 'الفيديوهات'),
                      Tab(text: 'المسح الجوي'),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),
                SizedBox(
                  height: 200,
                  child: TabBarView(
                    children: [
                      // Photos
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: Dimensions.spaceM,
                              mainAxisSpacing: Dimensions.spaceM,
                            ),
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _showFullScreenImage(index);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusM,
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://via.placeholder.com/150/102289/FFFFFF?text=Photo+${index + 1}',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: index == 0
                                  ? const Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          Dimensions.spaceS,
                                        ),
                                        child: Icon(
                                          Icons.star,
                                          color: AppColors.accent,
                                          size: 16,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),

                      // Videos
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: Dimensions.spaceM,
                              mainAxisSpacing: Dimensions.spaceM,
                            ),
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),

                      // Drone Shots
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: Dimensions.spaceM,
                              mainAxisSpacing: Dimensions.spaceM,
                            ),
                        itemCount: 2,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              color: AppColors.info.withOpacity(0.1),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://via.placeholder.com/300/17A2B8/FFFFFF?text=Drone',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: EdgeInsets.all(Dimensions.spaceS),
                                child: Icon(
                                  Icons.airplanemode_active,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التقارير والوثائق',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: Dimensions.spaceL,
            mainAxisSpacing: Dimensions.spaceL,
            childAspectRatio: 1.2,
            children: [
              _buildReportCard(
                icon: Icons.engineering,
                title: 'تقرير هندسي',
                subtitle: 'آخر تحديث: اليوم',
                color: AppColors.primary,
              ),
              _buildReportCard(
                icon: Icons.attach_money,
                title: 'تقرير مالي',
                subtitle: 'آخر تحديث: أمس',
                color: AppColors.success,
              ),
              _buildReportCard(
                icon: Icons.assignment,
                title: 'تقرير الجودة',
                subtitle: 'آخر تحديث: ٢ مارس',
                color: AppColors.warning,
              ),
              _buildReportCard(
                icon: Icons.security,
                title: 'تقرير السلامة',
                subtitle: 'آخر تحديث: ١ مارس',
                color: AppColors.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: Dimensions.spaceL),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: Dimensions.spaceXS),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: Dimensions.spaceM),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: AppColors.white,
              minimumSize: const Size(120, 36),
            ),
            child: const Text('عرض التقرير'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'آخر التحديثات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active),
                onPressed: () {
                  // Notification settings
                },
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceL),

          ...List.generate(3, (index) {
            final updates = [
              {
                'title': 'اكتمال الهيكل الخرساني',
                'time': 'منذ ٣ ساعات',
                'type': 'progress',
              },
              {
                'title': 'وصول شحنة الأسمنت',
                'time': 'منذ يوم',
                'type': 'material',
              },
              {
                'title': 'تأخير بسبب الأحوال الجوية',
                'time': 'منذ يومين',
                'type': 'delay',
              },
            ];

            final update = updates[index];
            final icon = update['type'] == 'progress'
                ? Icons.trending_up
                : update['type'] == 'material'
                ? Icons.local_shipping
                : Icons.cloud;

            final color = update['type'] == 'progress'
                ? AppColors.success
                : update['type'] == 'material'
                ? AppColors.info
                : AppColors.warning;

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
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update['title']!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: Dimensions.spaceXS),
                        Text(
                          update['time']!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {},
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEngineeringNotes() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملاحظات المهندس المشرف',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.spaceL),

          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        'https://via.placeholder.com/100/102289/FFFFFF?text=ENG',
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'م. أحمد محمد',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'المهندس المشرف',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                      ),
                      child: const Text(
                        'متصل الآن',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceL),
                const Text(
                  '"تم اليوم الانتهاء من أعمال الهيكل الخرساني للدور العاشر بكامل مواصفات الجودة. تم فحص العينات وتحقيق جميع المعايير الهندسية. سيبدأ العمل في التشطيبات الخارجية الأسبوع القادم."',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: Dimensions.spaceS),
                    Text(
                      'آخر تحديث: ${DateTime.now().toString().substring(0, 10)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.spaceL),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _contactEngineer();
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('مراسلة المهندس'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceL),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _scheduleVisit();
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('زيارة الموقع'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'جدول الزيارات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              // Calendar widget would go here
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMediaFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'تصفية الوسائط',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              // Filter options would go here
              const SizedBox(height: Dimensions.spaceXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenImage(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.network(
                  'https://via.placeholder.com/800/102289/FFFFFF?text=Full+Image+${index + 1}',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.download),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLiveCamera() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusXL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(Dimensions.radiusXL),
                    topRight: Radius.circular(Dimensions.radiusXL),
                  ),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://via.placeholder.com/400/000000/FFFFFF?text=LIVE',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusS,
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusS,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.white,
                            ),
                            SizedBox(width: Dimensions.spaceXS),
                            Text(
                              'الكاميرا الشمالية',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                child: Column(
                  children: [
                    const Text(
                      'البث المباشر للموقع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    const Text(
                      'مشاهدة حية لموقع البناء عبر الكاميرات عالية الجودة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: Dimensions.spaceXL),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('إغلاق'),
                          ),
                        ),
                        const SizedBox(width: Dimensions.spaceL),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.switch_camera),
                            label: const Text('تغيير الكاميرا'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _contactEngineer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'مراسلة المهندس',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              // Chat interface would go here
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        filled: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {},
                        ),
                      ),
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

  void _scheduleVisit() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('جدولة زيارة موقع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر تاريخ ووقت الزيارة:'),
              const SizedBox(height: Dimensions.spaceL),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () {
                  // Show date picker
                },
              ),
              const SizedBox(height: Dimensions.spaceL),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'الوقت',
                  prefixIcon: Icon(Icons.access_time),
                ),
                onTap: () {
                  // Show time picker
                },
              ),
              const SizedBox(height: Dimensions.spaceL),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'عدد الأشخاص',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم جدولة الزيارة بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }
}
