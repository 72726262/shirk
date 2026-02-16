import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/join_flow/join_flow_cubit.dart';
import 'package:mmm/presentation/widgets/custom/progress_timeline.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final GlobalKey _globalKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<JoinFlowCubit, JoinFlowState>(
        builder: (context, state) {
          // Try to get real data from the completed state
          final subscription = state is JoinFlowCompleteState ? state.subscription : null;
          final investmentAmount = subscription?.investmentAmount ?? 1200000.0;
          final downPayment = subscription?.downPayment ?? 120000.0;
          final unitNumber = widget.unitId; // Or from subscription if available
          
          return Stack(
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
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container( // Wrap in container to ensure background color in screenshot
                    color: _isExporting ? AppColors.white : Colors.transparent, // White bg for receipt
                    child: Column(
                      children: [
                        const SizedBox(height: Dimensions.space7XL),
      
                        // Success Animation
                        if (!_isExporting)
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.spaceXL),
                          child: Text(
                            _isExporting ? 'إيصال حجز' : 'مبروك! لقد أصبحت شريكاً',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isExporting ? AppColors.primary : AppColors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
      
                        const SizedBox(height: Dimensions.spaceL),
      
                        if (!_isExporting)
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
                            boxShadow: _isExporting ? [] : [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                            border: _isExporting ? Border.all(color: AppColors.border) : null,
                          ),
                          child: Column(
                            key: const ValueKey('receipt_content'),
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'الوحدة المملوكة',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          'Unit $unitNumber', // Dynamic Unit Number
                                          style: const TextStyle(
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
                                value: '${investmentAmount.toStringAsFixed(0)} ج.م',
                                color: AppColors.primary,
                              ),
                              _buildDetailItem(
                                icon: Icons.payment,
                                title: 'الدفعة الأولى / المدفوع',
                                value: '${downPayment.toStringAsFixed(0)} ج.م',
                                color: AppColors.success,
                              ),
                              _buildDetailItem(
                                icon: Icons.calendar_today,
                                title: 'تاريخ الاستثمار',
                                value: '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                                color: AppColors.info,
                              ),
                              if (subscription != null)
                              _buildDetailItem(
                                icon: Icons.receipt_long,
                                title: 'رقم العملية',
                                value: subscription.id.substring(0, 8).toUpperCase(),
                                color: AppColors.accent,
                              ),
      
                              const SizedBox(height: Dimensions.spaceXL),
      
                              // Next Steps or Receipt Footer
                              if (!_isExporting) ...[
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
                                      title: 'تأكيد الدفع',
                                      subtitle: 'تم بنجاح',
                                      isCompleted: true,
                                    ),
                                    TimelineItem(
                                      title: 'متابعة التنفيذ',
                                      subtitle: 'من خلال التطبيق',
                                      isCompleted: false,
                                    ),
                                  ],
                                  currentStep: 1,
                                ),
        
                                const SizedBox(height: Dimensions.spaceXL),
        
                                // Share/Extract Button
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _extractReceipt,
                                        icon: const Icon(Icons.print),
                                        label: const Text('استخراج إيصال'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                          side: const BorderSide(color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.spaceM),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _shareInvestment,
                                        icon: const Icon(Icons.share),
                                        label: const Text('مشاركة'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                          side: const BorderSide(color: AppColors.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const Divider(),
                                const Text('شكراً لثقتكم في منصة شريك', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
      
                        const SizedBox(height: Dimensions.space7XL),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
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
        color: _isExporting ? AppColors.white : AppColors.surface, // Clean look for receipt
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
                  style: const TextStyle(
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
                      child: const Text(
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

  Future<void> _extractReceipt() async {
    setState(() => _isExporting = true); // Change UI for screenshot
    await Future.delayed(const Duration(milliseconds: 100)); // Wait for rebuild

    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/sharik_receipt_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);
        
        // Share/Save functionality
        await Share.shareXFiles([XFile(file.path)], text: 'إيصال دفع - منصة شريك');
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل استخراج الإيصال: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false); // Revert UI
      }
    }
  }
}
