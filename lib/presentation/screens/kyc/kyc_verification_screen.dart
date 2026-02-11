// lib/presentation/screens/kyc/kyc_verification_screen.dart
import 'dart:io';
import 'dart:typed_data'; // ✅ للويب - Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // ✅ للتحقق من الويب
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/kyc/kyc_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nationalIdController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  DateTime? _selectedDate;

  // ✅ استخدام XFile بدلاً من File للتوافق مع الويب
  XFile? _idFrontFile;
  XFile? _idBackFile;
  XFile? _selfieFile;
  XFile? _incomeProofFile;

  final ImagePicker _picker = ImagePicker();

  String? _currentKycStatus;
  bool _isCheckingStatus = true;

  @override
  void initState() {
    super.initState();
    _checkKycStatus();
  }

  Future<void> _checkKycStatus() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      await context.read<KycCubit>().getKycStatus(authState.user.id);
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? pickedXFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedXFile != null) {
        setState(() {
          switch (type) {
            case 'id_front':
              _idFrontFile = pickedXFile; // ✅ XFile مباشرة
              break;
            case 'id_back':
              _idBackFile = pickedXFile;
              break;
            case 'selfie':
              _selfieFile = pickedXFile;
              break;
            case 'income_proof':
              _incomeProofFile = pickedXFile;
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل اختيار الصورة: ${e.toString()}')),
        );
      }
    }
  }

  void _submitKyc() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthCubit>().state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول أولاً')));
      return;
    }

    if (_idFrontFile == null || _idBackFile == null || _selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب رفع جميع الصور المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ الميلاد')),
      );
      return;
    }

    // ✅ تمرير XFile مباشرة - يعمل على الويب والموبايل
    context.read<KycCubit>().submitKyc(
      userId: authState.user.id,
      nationalId: _nationalIdController.text.trim(),
      dateOfBirth: _selectedDate!,
      idFrontFile: _idFrontFile!,
      idBackFile: _idBackFile!,
      selfieFile: _selfieFile!,
      incomeProofFile: _incomeProofFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التحقق من الهوية (KYC)'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: BlocConsumer<KycCubit, KycState>(
        listener: (context, state) {
          if (state is KycSubmittedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ تم إرسال طلبك بنجاح! سيتم مراجعته قريباً.'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );

            // ✅ Navigate to client dashboard after success
            Future.delayed(const Duration(seconds: 1), () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.clientDashboard,
                (route) => false, // Remove all previous routes
              );
            });
          }

          if (state is KycError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          if (state is KycStatusLoaded) {
            setState(() {
              _currentKycStatus = state.status;
            });
          }
        },
        builder: (context, state) {
          if (_isCheckingStatus) {
            return const Center(child: CircularProgressIndicator());
          }

          // إذا كانت الحالة تحت المراجعة أو موافق عليها
          if (_currentKycStatus == 'under_review') {
            return _buildStatusMessage(
              icon: Icons.pending,
              iconColor: Colors.orange,
              title: 'طلبك قيد المراجعة',
              message: 'تم استلام مستنداتك وسيتم مراجعتها خلال 48 ساعة',
            );
          }

          if (_currentKycStatus == 'approved') {
            return _buildStatusMessage(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: 'تم الموافقة على حسابك',
              message:
                  'تم التحقق من هويتك بنجاح. يمكنك الآن الاستثمار في المشاريع.',
            );
          }

          final isLoading = state is KycSubmitting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رسالة توضيحية
                  _buildInfoCard(),
                  const SizedBox(height: Dimensions.spaceXL),

                  // بيانات الهوية
                  Text(
                    'البيانات الشخصية',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  TextFormField(
                    controller: _nationalIdController,
                    decoration: const InputDecoration(
                      labelText: 'الرقم الوطني *',
                      hintText: 'أدخل رقم بطاقة الهوية',
                      prefixIcon: Icon(Icons.credit_card),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرقم الوطني مطلوب';
                      }
                      if (value.trim().length < 10) {
                        return 'الرقم غير صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  TextFormField(
                    controller: _dateOfBirthController,
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الميلاد *',
                      hintText: 'اختر تاريخ الميلاد',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: _selectDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'تاريخ الميلاد مطلوب';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // صور المستندات
                  Text(
                    'المستندات المطلوبة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  _buildDocumentCard(
                    title: 'صورة أمامية للهوية',
                    description: 'صورة واضحة للوجه الأمامي لبطاقة الهوية',
                    imageFile: _idFrontFile,
                    onTap: () => _pickImage(ImageSource.gallery, 'id_front'),
                    required: true,
                    icon: Icons.badge,
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  _buildDocumentCard(
                    title: 'صورة خلفية للهوية',
                    description: 'صورة واضحة للوجه الخلفي لبطاقة الهوية',
                    imageFile: _idBackFile,
                    onTap: () => _pickImage(ImageSource.gallery, 'id_back'),
                    required: true,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  _buildDocumentCard(
                    title: 'صورة شخصية (سيلفي)',
                    description: 'التقط صورة شخصية واضحة لوجهك',
                    imageFile: _selfieFile,
                    onTap: () => _pickImage(ImageSource.camera, 'selfie'),
                    required: true,
                    icon: Icons.face,
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  _buildDocumentCard(
                    title: 'إثبات الدخل (اختياري)',
                    description: 'كشف حساب بنكي أو إثبات راتب',
                    imageFile: _incomeProofFile,
                    onTap: () =>
                        _pickImage(ImageSource.gallery, 'income_proof'),
                    required: false,
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: Dimensions.spaceXXL),

                  // زر الإرسال
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitKyc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'إرسال طلب التحقق',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: Dimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لماذا نحتاج هذه المعلومات؟',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'للتحقق من هويتك وحماية حسابك والامتثال للأنظمة',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: iconColor),
            const SizedBox(height: Dimensions.spaceXL),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spaceM),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.spaceXXL),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceXL,
                  vertical: Dimensions.spaceM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String description,
    required XFile? imageFile, // ✅ XFile بدلاً من File
    required VoidCallback onTap,
    required bool required,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: Dimensions.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (required)
                              const Text(
                                ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceM),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: imageFile != null
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    width: imageFile != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(Dimensions.radiusS),
                ),
                child: imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                        child: Stack(
                          children: [
                            // ✅ دعم الويب والموبايل
                            kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: imageFile.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        );
                                      }
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  )
                                : Image.file(
                                    File(imageFile.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط لاختيار صورة',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }
}
