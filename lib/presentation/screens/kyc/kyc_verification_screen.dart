import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmm/presentation/cubits/kyc/kyc_cubit.dart';
import 'package:mmm/presentation/cubits/auth/auth_cubit.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final _nationalIdController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  File? _idFrontFile;
  File? _idBackFile;
  File? _selfieFile;
  File? _incomeProofFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? pickedXFile = await _picker.pickImage(source: source);

    if (pickedXFile != null) {
      final file = File(pickedXFile.path);
      setState(() {
        switch (type) {
          case 'id_front':
            _idFrontFile = file;
            break;
          case 'id_back':
            _idBackFile = file;
            break;
          case 'selfie':
            _selfieFile = file;
            break;
          case 'income_proof':
            _incomeProofFile = file;
            break;
        }
      });
    }
  }

  void _submitKyc() {
    final authState = context.read<AuthCubit>().state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول أولاً')));
      return;
    }

    if (_nationalIdController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرقم الوطني مطلوب')));
      return;
    }

    if (_dateOfBirthController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تاريخ الميلاد مطلوب')));
      return;
    }

    if (_idFrontFile == null || _idBackFile == null || _selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب رفع جميع الصور المطلوبة')),
      );
      return;
    }

    final dateOfBirth = DateTime.tryParse(_dateOfBirthController.text);
    if (dateOfBirth == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تاريخ الميلاد غير صالح')));
      return;
    }

    context.read<KycCubit>().submitKyc(
      userId: authState.user.id,
      nationalId: _nationalIdController.text,
      dateOfBirth: dateOfBirth,
      idFrontFile: _idFrontFile!, // تمرير File بدلاً من path
      idBackFile: _idBackFile!, // تمرير File بدلاً من path
      selfieFile: _selfieFile!, // تمرير File بدلاً من path
      incomeProofFile: _incomeProofFile, // تمرير File بدلاً من path
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التحقق من الهوية')),
      body: BlocConsumer<KycCubit, KycState>(
        listener: (context, state) {
          if (state is KycSubmittedSuccessfully) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال طلب التحقق بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }

          if (state is KycError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is KycSubmitting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // بيانات الهوية
                TextField(
                  controller: _nationalIdController,
                  decoration: const InputDecoration(
                    labelText: 'الرقم الوطني',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _dateOfBirthController,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الميلاد (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // صور الهوية
                _buildDocumentCard(
                  title: 'صورة أمامية للهوية',
                  imageFile: _idFrontFile,
                  onTap: () => _pickImage(ImageSource.gallery, 'id_front'),
                  required: true,
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'صورة خلفية للهوية',
                  imageFile: _idBackFile,
                  onTap: () => _pickImage(ImageSource.gallery, 'id_back'),
                  required: true,
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'صورة شخصية (سيلفي)',
                  imageFile: _selfieFile,
                  onTap: () => _pickImage(ImageSource.camera, 'selfie'),
                  required: true,
                ),
                const SizedBox(height: 16),

                _buildDocumentCard(
                  title: 'إثبات الدخل (اختياري)',
                  imageFile: _incomeProofFile,
                  onTap: () => _pickImage(ImageSource.gallery, 'income_proof'),
                  required: false,
                ),
                const SizedBox(height: 32),

                // زر الإرسال
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitKyc,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text('إرسال طلب التحقق'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
    required bool required,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title ${required ? '(*)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: onTap,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageFile != null
                    ? Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.add_photo_alternate, size: 50),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
