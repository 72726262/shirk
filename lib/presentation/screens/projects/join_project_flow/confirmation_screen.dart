import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/custom/progress_timeline.dart';

class ConfirmationScreen extends StatefulWidget {
  final String projectId;
  final String unitId;

  const ConfirmationScreen({
    super.key,
    required this.projectId,
    required this.unitId,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Confirmation Content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: Dimensions.space7XL),

                // Success Animation
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 80,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: Dimensions.spaceXL),

                // Success Message
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.spaceXL),
                  child: Text(
                    'مبروك! لقد أصبحت شريكاً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.spaceL),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.spaceXL,
                  ),
                  child: Text(
                    'تم تأكيد اشتراكك في المشروع بنجاح',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.space7XL),

                // Details Card
                Container(
                  margin: const EdgeInsets.all(Dimensions.spaceL),
                  padding: const EdgeInsets.all(Dimensions.spaceXL),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Unit Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceXL,
                          vertical: Dimensions.spaceM,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.apartment,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: Dimensions.spaceL),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الوحدة المملوكة',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'A101 - برج النخيل',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Dimensions.spaceXL),

                      // Investment Details
                      const Text(
                        'تفاصيل الاستثمار',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceL),

                      _buildDetailItem(
                        icon: Icons.attach_money,
                        title: 'قيمة الاستثمار',
                        value: '1,200,000 ج.م',
                        color: AppColors.primary,
                      ),
                      _buildDetailItem(
                        icon: Icons.payment,
                        title: 'الدفعة الأولى',
                        value: '120,000 ج.م',
                        color: AppColors.success,
                      ),
                      _buildDetailItem(
                        icon: Icons.calendar_today,
                        title: 'مدة الاستثمار',
                        value: '48 شهراً',
                        color: AppColors.info,
                      ),
                      _buildDetailItem(
                        icon: Icons.trending_up,
                        title: 'العائد المتوقع',
                        value: '18% سنوياً',
                        color: AppColors.accent,
                      ),

                      const SizedBox(height: Dimensions.spaceXL),

                      // Next Steps
                      const Text(
                        'الخطوات التالية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceL),

                      ProgressTimeline(
                        items: [
                          TimelineItem(
                            title: 'التوقيع الإلكتروني',
                            subtitle: 'تم بنجاح',
                            isCompleted: true,
                          ),
                          TimelineItem(
                            title: 'دفع القسط الأول',
                            subtitle: '15 يونيو 2024',
                            isCompleted: false,
                          ),
                          TimelineItem(
                            title: 'متابعة التنفيذ',
                            subtitle: 'من خلال التطبيق',
                            isCompleted: false,
                          ),
                          TimelineItem(
                            title: 'تسليم الوحدة',
                            subtitle: 'يونيو 2025',
                            isCompleted: false,
                          ),
                        ],
                        currentStep: 0,
                      ),

                      const SizedBox(height: Dimensions.spaceXL),

                      // Share Button
                      OutlinedButton.icon(
                        onPressed: () {
                          _shareInvestment();
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('مشاركة إنجازك'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.space7XL),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                ),
                child: const Text('العودة للرئيسية'),
              ),
            ),
            const SizedBox(width: Dimensions.spaceL),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/project-detail',
                    arguments: {'projectId': widget.projectId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('متابعة المشروع'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXS),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareInvestment() {
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
                'مشاركة إنجازك',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: Dimensions.spaceL,
                crossAxisSpacing: Dimensions.spaceL,
                children: [
                  _buildShareOption(
                    icon: Icons.facebook,
                    label: 'فيسبوك',
                    color: const Color(0xFF1877F2),
                  ),
                  _buildShareOption(
                    icon: Icons.camera_alt,
                    label: 'انستجرام',
                    color: const Color(0xFFE4405F),
                  ),
                  _buildShareOption(
                    icon: Icons.chat,
                    label: 'واتساب',
                    color: const Color(0xFF25D366),
                  ),
                  _buildShareOption(
                    icon: Icons.more_horiz,
                    label: 'أخرى',
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceXL),
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'أصبحت شريكاً في مشروع برج النخيل باستثمار 1.2 مليون جنيه! #شريك_العقاري',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم نسخ النص'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
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
        const SizedBox(height: Dimensions.spaceS),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
