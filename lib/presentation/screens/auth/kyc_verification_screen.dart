import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/kyc/kyc_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;
  bool _idFrontUploaded = false;
  bool _idBackUploaded = false;
  bool _selfieUploaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('التحقق من الهوية'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'البطاقة'),
            Tab(text: 'الصورة'),
            Tab(text: 'المعلومات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIdCardTab(), _buildSelfieTab(), _buildInfoTab()],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: AppColors.gray200,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: Dimensions.spaceL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentStep > 0
                        ? () {
                            setState(() {
                              _currentStep--;
                              _tabController.animateTo(_currentStep);
                            });
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('رجوع'),
                  ),
                ),
                const SizedBox(width: Dimensions.spaceL),
                Expanded(
                  child: PrimaryButton(
                    onPressed: _currentStep < 2
                        ? () {
                            setState(() {
                              _currentStep++;
                              _tabController.animateTo(_currentStep);
                            });
                          }
                        : () {
                            _submitKYC();
                          },
                    text: _currentStep < 2 ? 'التالي' : 'إرسال للتحقق',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: Dimensions.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات هامة',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      Text(
                        'تأكد من وضوح الصورة وأن جميع البيانات مقروءة',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // ID Front
          _buildUploadSection(
            title: 'وجه البطاقة الشخصية',
            uploaded: _idFrontUploaded,
            onUpload: () {
              setState(() {
                _idFrontUploaded = true;
              });
            },
            onRetake: () {
              setState(() {
                _idFrontUploaded = false;
              });
            },
            requirements: [
              'يجب أن تكون الصورة واضحة',
              'جميع البيانات مقروءة',
              'تتضمن الصورة الشعار الوطني',
              'الخلفية بيضاء أو فاتحة',
            ],
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // ID Back
          _buildUploadSection(
            title: 'ظهر البطاقة الشخصية',
            uploaded: _idBackUploaded,
            onUpload: () {
              setState(() {
                _idBackUploaded = true;
              });
            },
            onRetake: () {
              setState(() {
                _idBackUploaded = false;
              });
            },
            requirements: [
              'يجب أن تكون الصورة واضحة',
              'جميع البيانات مقروءة',
              'تظهر خانة العنوان',
              'تظهر خانة المواليد',
            ],
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Examples
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
                  'أمثلة للصور الصحيحة',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              border: Border.all(color: AppColors.border),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://via.placeholder.com/200/102289/FFFFFF?text=ID+Front',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          const Text(
                            'صحيحة',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceL),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              border: Border.all(color: AppColors.border),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://via.placeholder.com/200/DC3545/FFFFFF?text=Wrong',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          const Text(
                            'غير صحيحة',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildUploadSection({
    required String title,
    required bool uploaded,
    required VoidCallback onUpload,
    required VoidCallback onRetake,
    required List<String> requirements,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(
          color: uploaded ? AppColors.success : AppColors.border,
          width: uploaded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: uploaded ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (uploaded)
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
                      Icon(Icons.check, size: 12, color: AppColors.success),
                      SizedBox(width: Dimensions.spaceXS),
                      Text(
                        'مرفوعة',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: Dimensions.spaceL),

          // Upload Area
          GestureDetector(
            onTap: uploaded ? null : onUpload,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppColors.success.withOpacity(0.05)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(Dimensions.radiusL),
                border: Border.all(
                  color: uploaded
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.border,
                  style: uploaded ? BorderStyle.solid : BorderStyle.solid,
                ),
              ),
              child: uploaded
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 64,
                            color: AppColors.success,
                          ),
                          const SizedBox(height: Dimensions.spaceL),
                          const Text(
                            'تم الرفع بنجاح',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Dimensions.spaceM),
                          OutlinedButton.icon(
                            onPressed: onRetake,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('إعادة الرفع'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: Dimensions.spaceL),
                          const Text(
                            'انقر لالتقاط صورة',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          Text(
                            'أو اختر من المعرض',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: Dimensions.spaceL),

          // Requirements
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'متطلبات الصورة:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: Dimensions.spaceS),
              ...requirements.map((requirement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.spaceXS),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      Text(
                        requirement,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.face_retouching_natural,
                  color: AppColors.info,
                ),
                const SizedBox(width: Dimensions.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نصائح للصورة الشخصية',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      Text(
                        'تأكد من أن وجهك واضح والإضاءة جيدة',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Selfie Upload
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(
                color: _selfieUploaded ? AppColors.success : AppColors.border,
                width: _selfieUploaded ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: _selfieUploaded ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الصورة الشخصية (سيلفي)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // Camera Preview
                Stack(
                  children: [
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                        border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _selfieUploaded
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 3,
                                      ),
                                      image: const DecorationImage(
                                        image: NetworkImage(
                                          'https://via.placeholder.com/150/102289/FFFFFF?text=Selfie',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.spaceL),
                                  const Text(
                                    'تم التحقق من الوجه بنجاح',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.face,
                                      size: 60,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: Dimensions.spaceL),
                                  const Text(
                                    'وجه الكاميرا نحو وجهك',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (!_selfieUploaded)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              setState(() {
                                _selfieUploaded = true;
                              });
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('التقاط صورة'),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Face Guidelines
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusM),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إرشادات التقاط الصورة:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      _buildGuideline('وجه واضح في الإطار', true),
                      _buildGuideline('إضاءة جيدة بدون ظلال', true),
                      _buildGuideline('لا نظارات شمسية', false),
                      _buildGuideline('لا قبعات أو أغطية رأس', false),
                      _buildGuideline('خلفية محايدة', true),
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Face Match Info
                if (_selfieUploaded)
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: Dimensions.spaceL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تمت مطابقة الوجه',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'تمت مطابقة صورتك مع صورة البطاقة بنسبة 98%',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
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
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Live Verification Option
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
                  'التحقق المباشر',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Dimensions.spaceS),
                Text(
                  'يمكنك إجراء تحقق مباشر عبر الفيديو مع أحد موظفينا',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Dimensions.spaceL),
                OutlinedButton.icon(
                  onPressed: () {
                    _scheduleVideoVerification();
                  },
                  icon: const Icon(Icons.video_call),
                  label: const Text('جدولة تحقق عبر الفيديو'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text, bool allowed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spaceXS),
      child: Row(
        children: [
          Icon(
            allowed ? Icons.check_circle : Icons.remove_circle,
            size: 16,
            color: allowed ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: Dimensions.spaceS),
          Text(
            text,
            style: TextStyle(
              color: allowed ? AppColors.success : AppColors.error,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المعلومات الشخصية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),

                // National ID
                _buildInfoField(
                  label: 'الرقم القومي',
                  value: '29901010101010',
                  icon: Icons.badge,
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Birth Date
                _buildInfoField(
                  label: 'تاريخ الميلاد',
                  value: '01/01/1990',
                  icon: Icons.cake,
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Nationality
                _buildInfoField(
                  label: 'الجنسية',
                  value: 'مصري',
                  icon: Icons.flag,
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Address
                _buildInfoField(
                  label: 'العنوان',
                  value: 'القاهرة، مصر',
                  icon: Icons.location_on,
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // KYC Status
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حالة التحقق',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الهوية الشخصية',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _idFrontUploaded && _idBackUploaded
                                ? 'مكتمل'
                                : 'ناقص',
                            style: TextStyle(
                              color: _idFrontUploaded && _idBackUploaded
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _idFrontUploaded && _idBackUploaded
                            ? AppColors.success
                            : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _idFrontUploaded && _idBackUploaded
                            ? Icons.check
                            : Icons.warning,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),

                const Divider(height: Dimensions.spaceXL),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الصورة الشخصية',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _selfieUploaded ? 'مكتمل' : 'ناقص',
                            style: TextStyle(
                              color: _selfieUploaded
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _selfieUploaded
                            ? AppColors.success
                            : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selfieUploaded ? Icons.check : Icons.warning,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),

                const Divider(height: Dimensions.spaceXL),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المعلومات الشخصية',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Text(
                            'مكتمل',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Processing Info
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: AppColors.info),
                const SizedBox(width: Dimensions.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مدة المعالجة',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'تستغرق عملية التحقق من ٢٤ إلى ٤٨ ساعة عمل',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: Dimensions.spaceXL),

          // Consent
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
                  'الموافقة على التحقق',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: Dimensions.spaceS),
                Text(
                  'أوافق على استخدام صورتي ومعلوماتي الشخصية لأغراض التحقق من الهوية وفقاً لسياسة الخصوصية',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: null,
                      activeColor: AppColors.primary,
                    ),
                    const Text('أوافق على استخدام البيانات'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimensions.radiusS),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: Dimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit info
            },
          ),
        ],
      ),
    );
  }

  void _submitKYC() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;

    context.read<KYCCubit>().submitKYC(
      userId: authState.user.id,
      nationalId: '29901010101010', // Should be from input
      dateOfBirth: DateTime(1990, 1, 1), // Should be from input
      idFrontPath: 'dummy_path_front', // Should be actual path
      idBackPath: 'dummy_path_back',
      selfiePath: 'dummy_path_selfie',
    );

    showDialog(
      context: context,
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
                const Icon(
                  Icons.verified_user,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: Dimensions.spaceL),
                const Text(
                  'تم إرسال طلب التحقق',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                const Text(
                  'سيتم مراجعة بياناتك خلال ٢٤-٤٨ ساعة عمل',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'رقم المرجع: KYC${DateTime.now().millisecondsSinceEpoch}',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('العودة للرئيسية'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleVideoVerification() {
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
                'جدولة تحقق عبر الفيديو',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Expanded(
                child: ListView(
                  children: [
                    // Calendar
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      ),
                      child: const Center(child: Text('تقويم مواعيد')),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    // Time Slots
                    const Text(
                      'اختر وقتاً مناسباً:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    Wrap(
                      spacing: Dimensions.spaceM,
                      runSpacing: Dimensions.spaceM,
                      children:
                          [
                            '09:00 ص',
                            '10:00 ص',
                            '11:00 ص',
                            '01:00 م',
                            '02:00 م',
                            '03:00 م',
                            '04:00 م',
                          ].map((time) {
                            return ChoiceChip(
                              label: Text(time),
                              selected: false,
                              onSelected: (selected) {},
                              selectedColor: AppColors.primary,
                              labelStyle: const TextStyle(
                                color: AppColors.white,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم جدولة التحقق عبر الفيديو'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('تأكيد الموعد'),
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
}
