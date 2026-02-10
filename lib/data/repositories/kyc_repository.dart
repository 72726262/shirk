// lib/data/repositories/kyc_repository.dart
import 'dart:io'; // أضف هذا
import 'package:supabase_flutter/supabase_flutter.dart';

class KycRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // رفع ملف KYC - الإصدار المصحح
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
      print('📤 بدء رفع ملفات التحقق من الهوية للمستخدم: $userId');

      // 1. رفع الصور إلى التخزين
      final idFrontUrl = await _uploadKycDocument(
        userId: userId,
        file: idFrontFile, // تمرير File بدلاً من String
        documentType: 'id_front',
      );

      final idBackUrl = await _uploadKycDocument(
        userId: userId,
        file: idBackFile, // تمرير File بدلاً من String
        documentType: 'id_back',
      );

      final selfieUrl = await _uploadKycDocument(
        userId: userId,
        file: selfieFile, // تمرير File بدلاً من String
        documentType: 'selfie',
      );

      String? incomeProofUrl;
      if (incomeProofFile != null) {
        incomeProofUrl = await _uploadKycDocument(
          userId: userId,
          file: incomeProofFile, // تمرير File بدلاً من String
          documentType: 'income_proof',
        );
      }

      // 2. تحديث جدول profiles
      await _client
          .from('profiles')
          .update({
            'national_id': nationalId,
            'date_of_birth': dateOfBirth.toIso8601String(),
            'id_front_url': idFrontUrl,
            'id_back_url': idBackUrl,
            'selfie_url': selfieUrl,
            'income_proof_url': incomeProofUrl,
            'kyc_status': 'under_review',
            'kyc_submitted_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('✅ تم رفع ملفات التحقق من الهوية بنجاح');

      // 3. إنشاء إشعار للمستخدم
      await _createNotification(
        userId: userId,
        title: 'تم إرسال طلب التحقق من الهوية',
        body:
            'تم استلام طلب التحقق من الهوية بنجاح وسيتم المراجعة في خلال 48 ساعة.',
        type: 'kyc',
      );

      // 4. إنشاء سجل في activity_logs
      await _logActivity(
        userId: userId,
        action: 'SUBMIT_KYC',
        description: 'تم إرسال طلب التحقق من الهوية',
      );
    } catch (e) {
      print('❌ خطأ في submitKyc: $e');
      throw Exception('فشل إرسال طلب التحقق: ${e.toString()}');
    }
  }

  // رفع ملف KYC إلى التخزين - الإصدار المصحح
  Future<String> _uploadKycDocument({
    required String userId,
    required File file, // تغيير من String إلى File
    required String documentType,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // استخدم امتداد الملف الصحيح بناءً على نوع الملف
      final fileExtension = file.path.split('.').last;
      final fileName = 'kyc/$userId/$documentType/$timestamp.$fileExtension';

      print('📁 رفع ملف $documentType: $fileName');

      // قراءة الملف كـ bytes
      final fileBytes = await file.readAsBytes();

      final response = await _client.storage
          .from('user-files')
          .uploadBinary(fileName, fileBytes);

      final publicUrl = _client.storage
          .from('user-files')
          .getPublicUrl(fileName);

      print('✅ تم رفع الملف بنجاح: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ خطأ في رفع الملف $documentType: $e');
      throw Exception('فشل رفع $documentType: ${e.toString()}');
    }
  }

  // باقي الدوال تبقى كما هي...
  Future<Map<String, dynamic>> getKycStatus(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select(
            'kyc_status, kyc_submitted_at, kyc_reviewed_at, kyc_rejection_reason',
          )
          .eq('id', userId)
          .single();

      return {
        'status': response['kyc_status'],
        'submittedAt': response['kyc_submitted_at'],
        'reviewedAt': response['kyc_reviewed_at'],
        'rejectionReason': response['kyc_rejection_reason'],
      };
    } catch (e) {
      print('❌ خطأ في getKycStatus: $e');
      throw Exception('فشل الحصول على حالة التحقق: ${e.toString()}');
    }
  }

  Future<void> updateKycStatus({
    required String userId,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({
            'kyc_status': status,
            if (status == 'rejected') 'kyc_rejection_reason': rejectionReason,
            'kyc_reviewed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      String notificationTitle;
      String notificationBody;

      if (status == 'approved') {
        notificationTitle = 'تمت الموافقة على التحقق من الهوية';
        notificationBody =
            'تهانينا! تمت الموافقة على طلب التحقق من الهوية الخاص بك. يمكنك الآن الاستثمار في المشاريع.';
      } else {
        notificationTitle = 'تم رفض طلب التحقق من الهوية';
        notificationBody =
            rejectionReason ?? 'يرجى مراجعة المستندات المقدمة وإعادة التقديم.';
      }

      await _createNotification(
        userId: userId,
        title: notificationTitle,
        body: notificationBody,
        type: 'kyc',
      );

      print('✅ تم تحديث حالة KYC للمستخدم $userId إلى: $status');
    } catch (e) {
      print('❌ خطأ في updateKycStatus: $e');
      throw Exception('فشل تحديث حالة التحقق: ${e.toString()}');
    }
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ خطأ في إنشاء الإشعار: $e');
    }
  }

  Future<void> _logActivity({
    required String userId,
    required String action,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('activity_logs').insert({
        'user_id': userId,
        'action': action,
        'description': description,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('⚠️ خطأ في تسجيل النشاط: $e');
    }
  }
}
