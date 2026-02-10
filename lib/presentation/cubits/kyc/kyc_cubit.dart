// lib/presentation/cubits/kyc/kyc_cubit.dart
import 'dart:io'; // أضف هذا
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/kyc_repository.dart';

part 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  final KycRepository kycRepository;

  KycCubit({required this.kycRepository}) : super(KycInitial());

  // إرسال طلب التحقق من الهوية - الإصدار المصحح
  Future<void> submitKyc({
    required String userId,
    required String nationalId,
    required DateTime dateOfBirth,
    required File idFrontFile, // تغيير من String إلى File
    required File idBackFile, // تغيير من String إلى File
    required File selfieFile, // تغيير من String إلى File
    File? incomeProofFile, // تغيير من String? إلى File?
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
