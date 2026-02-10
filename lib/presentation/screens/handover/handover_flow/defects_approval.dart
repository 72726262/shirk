import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';



class DefectsApprovalScreen extends StatefulWidget {
  final String projectId;
  final String unitId;

  const DefectsApprovalScreen({
    super.key,
    required this.projectId,
    required this.unitId,
  });

  @override
  State<DefectsApprovalScreen> createState() => _DefectsApprovalScreenState();
}

class _DefectsApprovalScreenState extends State<DefectsApprovalScreen> {
  final List<DefectItem> _defects = [];
  final List<DefectItem> _approvedDefects = [];

  @override
  void initState() {
    super.initState();
    _loadDefects();
  }

  void _loadDefects() {
    // Mock data
    setState(() {
      _defects.addAll([
        DefectItem(
          id: '1',
          title: 'تشقق في جدار الحمام',
          category: 'جودة التشطيبات',
          location: 'الحمام الرئيسي - الجدار الشمالي',
          description: 'تشقق طولي في جدار الحمام بطول 30 سم',
          priority: 'عالية',
          status: 'قيد الإصلاح',
          reportedDate: '2024-03-01',
          estimatedCompletion: '2024-03-15',
          images: 3,
        ),
        DefectItem(
          id: '2',
          title: 'تسرب مياه من الحنفية',
          category: 'الأعمال الصحية',
          location: 'المطبخ - حوض الغسيل',
          description: 'تسرب مستمر من قاعدة الحنفية',
          priority: 'عالية',
          status: 'مكتمل',
          reportedDate: '2024-02-25',
          completedDate: '2024-03-05',
          images: 2,
        ),
        DefectItem(
          id: '3',
          title: 'خلل في مفتاح الإضاءة',
          category: 'الأعمال الكهربائية',
          location: 'غرفة النوم - المفتاح الرئيسي',
          description: 'المفتاح لا يعمل بشكل صحيح',
          priority: 'متوسطة',
          status: 'قيد المراجعة',
          reportedDate: '2024-03-10',
          estimatedCompletion: '2024-03-20',
          images: 1,
        ),
        DefectItem(
          id: '4',
          title: 'خدش في باب المدخل',
          category: 'الأبواب والنوافذ',
          location: 'المدخل الرئيسي',
          description: 'خدش طوله 15 سم في الباب الخشبي',
          priority: 'منخفضة',
          status: 'مكتمل',
          reportedDate: '2024-02-20',
          completedDate: '2024-02-28',
          images: 4,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متابعة الإصلاحات'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'جميع العيوب'),
              Tab(text: 'قيد الإصلاح'),
              Tab(text: 'مكتملة'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllDefectsTab(),
            _buildInProgressTab(),
            _buildCompletedTab(),
          ],
        ),
        floatingActionButton: _approvedDefects.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () {
                  _finalApproval();
                },
                icon: const Icon(Icons.check),
                label: Text('موافقة نهائية (${_approvedDefects.length})'),
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white,
              )
            : null,
      ),
    );
  }

  Widget _buildAllDefectsTab() {
    return Column(
      children: [
        // Summary Cards
        Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'جميع العيوب',
                  value: '${_defects.length}',
                  color: AppColors.primary,
                  icon: Icons.list_alt,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: _buildSummaryCard(
                  title: 'قيد الإصلاح',
                  value:
                      '${_defects.where((d) => d.status == 'قيد الإصلاح' || d.status == 'قيد المراجعة').length}',
                  color: AppColors.warning,
                  icon: Icons.build,
                ),
              ),
              const SizedBox(width: Dimensions.spaceL),
              Expanded(
                child: _buildSummaryCard(
                  title: 'مكتملة',
                  value: '${_defects.where((d) => d.status == 'مكتمل').length}',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
        ),

        // Defects List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            itemCount: _defects.length,
            itemBuilder: (context, index) {
              final defect = _defects[index];
              final isApproved = _approvedDefects.contains(defect);
              return _buildDefectCard(defect, isApproved);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: Dimensions.spaceS),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDefectCard(DefectItem defect, bool isApproved) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: isApproved ? AppColors.success : AppColors.border,
          width: isApproved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Defect Header
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: _getStatusColor(defect.status).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radiusL),
                topRight: Radius.circular(Dimensions.radiusL),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        defect.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.spaceM,
                              vertical: Dimensions.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                defect.priority,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusS,
                              ),
                            ),
                            child: Text(
                              defect.priority,
                              style: TextStyle(
                                color: _getPriorityColor(defect.priority),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: Dimensions.spaceS),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.spaceM,
                              vertical: Dimensions.spaceXS,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                defect.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusS,
                              ),
                            ),
                            child: Text(
                              defect.status,
                              style: TextStyle(
                                color: _getStatusColor(defect.status),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (defect.status == 'مكتمل')
                  IconButton(
                    icon: Icon(
                      isApproved
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isApproved
                          ? AppColors.success
                          : AppColors.textHint,
                      size: 28,
                    ),
                    onPressed: () {
                      _toggleApproval(defect);
                    },
                  ),
              ],
            ),
          ),

          // Defect Details
          Padding(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  defect.description,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Details Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: Dimensions.spaceL,
                  mainAxisSpacing: Dimensions.spaceL,
                  childAspectRatio: 3,
                  children: [
                    _buildDetailItem(
                      icon: Icons.category,
                      title: 'التصنيف',
                      value: defect.category,
                    ),
                    _buildDetailItem(
                      icon: Icons.location_on,
                      title: 'الموقع',
                      value: defect.location,
                    ),
                    if (defect.reportedDate != null)
                      _buildDetailItem(
                        icon: Icons.date_range,
                        title: 'تاريخ التقرير',
                        value: defect.reportedDate!,
                      ),
                    if (defect.estimatedCompletion != null)
                      _buildDetailItem(
                        icon: Icons.timeline,
                        title: 'التاريخ المتوقع',
                        value: defect.estimatedCompletion!,
                      ),
                    if (defect.completedDate != null)
                      _buildDetailItem(
                        icon: Icons.done_all,
                        title: 'تاريخ الإكمال',
                        value: defect.completedDate!,
                      ),
                    _buildDetailItem(
                      icon: Icons.photo,
                      title: 'الصور',
                      value: '${defect.images} صورة',
                    ),
                  ],
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Actions
                if (defect.status == 'مكتمل')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _viewDefectImages(defect);
                          },
                          icon: const Icon(Icons.visibility),
                          label: const Text('عرض الصور'),
                        ),
                      ),
                      const SizedBox(width: Dimensions.spaceL),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _requestReinspection(defect);
                          },
                          icon: const Icon(Icons.replay),
                          label: const Text('إعادة فحص'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (defect.status == 'قيد الإصلاح')
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceM),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: Dimensions.spaceS),
                        Expanded(
                          child: Text(
                            'جاري الإصلاح بواسطة الفريق الفني',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 12,
                            ),
                          ),
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

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: Dimensions.spaceS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'منخفضة':
        return AppColors.success;
      case 'متوسطة':
        return AppColors.warning;
      case 'عالية':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'قيد الإصلاح':
      case 'قيد المراجعة':
        return AppColors.warning;
      case 'مكتمل':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildInProgressTab() {
    final inProgressDefects = _defects
        .where((d) => d.status == 'قيد الإصلاح' || d.status == 'قيد المراجعة')
        .toList();

    if (inProgressDefects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            const SizedBox(height: Dimensions.spaceL),
            const Text(
              'لا توجد عيوب قيد الإصلاح',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceS),
            Text(
              'جميع العيوب تم إصلاحها',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: inProgressDefects.length,
      itemBuilder: (context, index) {
        final defect = inProgressDefects[index];
        return _buildDefectCard(defect, _approvedDefects.contains(defect));
      },
    );
  }

  Widget _buildCompletedTab() {
    final completedDefects = _defects
        .where((d) => d.status == 'مكتمل')
        .toList();

    if (completedDefects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: Dimensions.spaceL),
            const Text(
              'لا توجد عيوب مكتملة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: Dimensions.spaceS),
            Text(
              'جميع العيوب قيد الإصلاح',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: completedDefects.length,
      itemBuilder: (context, index) {
        final defect = completedDefects[index];
        return _buildDefectCard(defect, _approvedDefects.contains(defect));
      },
    );
  }

  void _toggleApproval(DefectItem defect) {
    setState(() {
      if (_approvedDefects.contains(defect)) {
        _approvedDefects.remove(defect);
      } else {
        _approvedDefects.add(defect);
      }
    });
  }

  void _viewDefectImages(DefectItem defect) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    defect.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: Dimensions.spaceM,
                    mainAxisSpacing: Dimensions.spaceM,
                    childAspectRatio: 1,
                  ),
                  itemCount: defect.images,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusM),
                        color: AppColors.gray200,
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://via.placeholder.com/150',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _requestReinspection(DefectItem defect) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('طلب إعادة فحص'),
          content: const Text('هل تريد طلب إعادة فحص هذا العيب؟'),
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
                _showReinspectionRequested();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
              ),
              child: const Text('تأكيد الطلب'),
            ),
          ],
        );
      },
    );
  }

  void _showReinspectionRequested() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إرسال طلب إعادة الفحص'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _finalApproval() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('الموافقة النهائية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('هل تريد الموافقة النهائية على الإصلاحات؟'),
              const SizedBox(height: Dimensions.spaceL),
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Text(
                  '${_approvedDefects.length} عيب تمت الموافقة عليه',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                _showFinalApprovalSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('موافقة نهائية'),
            ),
          ],
        );
      },
    );
  }

  void _showFinalApprovalSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.spaceXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                const Text(
                  'تمت الموافقة!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'تمت الموافقة على ${_approvedDefects.length} عيب',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/sign-handover',
                        arguments: {
                          'projectId': widget.projectId,
                          'unitId': widget.unitId,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('التالي: توقيع محضر التسليم'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DefectItem {
  final String id;
  final String title;
  final String category;
  final String location;
  final String description;
  final String priority;
  final String status;
  final String? reportedDate;
  final String? estimatedCompletion;
  final String? completedDate;
  final int images;

  DefectItem({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.description,
    required this.priority,
    required this.status,
    this.reportedDate,
    this.estimatedCompletion,
    this.completedDate,
    required this.images,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefectItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
