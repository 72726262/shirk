// lib/presentation/cubits/kyc/kyc_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart'; // ✅ XFile
import 'package:mmm/data/repositories/kyc_repository.dart';

part 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  final KycRepository kycRepository;

  KycCubit({required this.kycRepository}) : super(KycInitial());

  // إرسال طلب التحقق من الهوية - الإصدار المصحح للويب
  Future<void> submitKyc({
    required String userId,
    required String nationalId,
    required DateTime dateOfBirth,
    required XFile idFrontFile, // ✅ XFile للويب والموبايل
    required XFile idBackFile,
    required XFile selfieFile,
    XFile? incomeProofFile,
  }) async {
    try {
      emit(KycSubmitting());

      await kycRepository.submitKyc(
        userId: userId,
        nationalId: nationalId,
        dateOfBirth: dateOfBirth,
        idFrontFile: idFrontFile,
        idBackFile: idBackFile,
        selfieFile: selfieFile,
        incomeProofFile: incomeProofFile,
      );

      emit(KycSubmittedSuccessfully());
    } catch (e) {
      emit(KycError(message: e.toString()));
    }
  }

  // الحصول على حالة التحقق
  Future<void> getKycStatus(String userId) async {
    try {
      emit(KycLoading());

      final status = await kycRepository.getKycStatus(userId);

      emit(
        KycStatusLoaded(
          status: status['status'] as String,
          submittedAt: status['submittedAt'] as String?,
          reviewedAt: status['reviewedAt'] as String?,
          rejectionReason: status['rejectionReason'] as String?,
        ),
      );
    } catch (e) {
      emit(KycError(message: 'فشل الحصول على حالة التحقق'));
    }
  }
}
