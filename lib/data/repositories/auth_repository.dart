// lib/data/repositories/auth_repository.dart
import 'package:mmm/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // التحقق من صحة البريد الإلكتروني
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  // الحصول على المستخدم الحالي
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _client.auth.currentUser;

      if (currentUser != null) {
        final data = await _client
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();

        return data != null ? UserModel.fromJson(data) : null;
      }
      return null;
    } catch (e) {
      print('❌ خطأ في getCurrentUser: $e');
      return null;
    }
  }

  // تسجيل الدخول
  Future<UserModel> signIn(String email, String password) async {
    try {
      // التحقق من البيانات
      if (!_isValidEmail(email)) {
        throw Exception('البريد الإلكتروني غير صالح');
      }

      if (password.isEmpty || password.length < 6) {
        throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      }

      print('🔐 محاولة تسجيل الدخول: ${email.trim()}');

      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ تسجيل الدخول ناجح للمستخدم: ${response.user?.id}');

      if (response.user != null) {
        // احصل على الملف الشخصي أو أنشئه
        var profile = await getUserProfile(response.user!.id);

        if (profile == null) {
          profile = await createUserProfile(
            userId: response.user!.id,
            email: email.trim(),
            fullName: response.user!.userMetadata?['full_name'] ?? 'مستخدم',
            phone: response.user!.phone,
          );
        }

        return profile;
      }

      throw Exception('فشل تسجيل الدخول');
    } on AuthException catch (e) {
      print('❌ خطأ مصادقة في تسجيل الدخول: ${e.message}');

      if (e.message.contains('Invalid login credentials')) {
        throw Exception('البريد الإلكتروني أو كلمة المرور غير صحيحة');
      }

      throw Exception('فشل تسجيل الدخول: ${e.message}');
    } catch (e) {
      print('❌ خطأ غير متوقع في تسجيل الدخول: $e');
      throw Exception('حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى');
    }
  }

  // إنشاء حساب جديد - الإصدار المصحح
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // التحقق من البيانات
      if (!_isValidEmail(email)) {
        throw Exception('البريد الإلكتروني غير صالح');
      }

      if (password.length < 6) {
        throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      }

      if (fullName.trim().isEmpty) {
        throw Exception('الاسم الكامل مطلوب');
      }

      print('👤 محاولة إنشاء حساب ل: ${email.trim()}');

      // 1. أولاً تحقق إذا كان المستخدم موجوداً في auth
      try {
        final existingResponse = await _client.auth.signInWithPassword(
          email: email.trim(),
          password: password,
        );

        if (existingResponse.user != null) {
          print('⚠️ المستخدم موجود بالفعل في النظام');
          final profile = await _getOrCreateProfile(
            userId: existingResponse.user!.id,
            email: email.trim(),
            fullName: fullName.trim(),
            phone: phone?.trim(),
          );
          return profile;
        }
      } catch (e) {
        // إذا فشل تسجيل الدخول، تابع لإنشاء حساب جديد
        print('ℹ️ المستخدم غير موجود، سيتم إنشاء حساب جديد');
      }

      // 2. إنشاء حساب جديد في auth
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim(), 'phone': phone?.trim()},
      );

      print('✅ استجابة إنشاء الحساب: ${response.user?.id}');

      if (response.user != null) {
        // 3. إنشاء أو الحصول على الملف الشخصي
        final profile = await _getOrCreateProfile(
          userId: response.user!.id,
          email: email.trim(),
          fullName: fullName.trim(),
          phone: phone?.trim(),
        );

        print('✅ تم إنشاء/الحصول على الملف الشخصي: ${profile.id}');
        return profile;
      }

      throw Exception('فشل إنشاء الحساب');
    } on AuthException catch (e) {
      print('❌ خطأ مصادقة في إنشاء الحساب: ${e.message}');

      if (e.message.contains('already registered')) {
        throw Exception('البريد الإلكتروني مسجل مسبقًا');
      }

      throw Exception('فشل إنشاء الحساب: ${e.message}');
    } catch (e) {
      print('❌ خطأ غير متوقع في إنشاء الحساب: $e');
      throw Exception('حدث خطأ غير متوقع. الرجاء المحاولة مرة أخرى');
    }
  }

  // دالة مساعدة: احصل على الملف الشخصي أو أنشئه
  Future<UserModel> _getOrCreateProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phone,
  }) async {
    try {
      // أولاً: حاول الحصول على الملف الشخصي الموجود
      final existingProfile = await getUserProfile(userId);
      if (existingProfile != null) {
        print('✅ الملف الشخصي موجود بالفعل: $userId');
        return existingProfile;
      }

      print('📝 جاري إنشاء ملف شخصي جديد للمستخدم: $userId');

      // حاول إنشاء الملف الشخصي
      try {
        final data = await _client
            .from('profiles')
            .insert({
              'id': userId,
              'email': email,
              'full_name': fullName,
              'phone': phone,
              'role': 'client',
              'kyc_status': 'pending',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        print('✅ تم إنشاء الملف الشخصي بنجاح');
        return UserModel.fromJson(data);
      } on PostgrestException catch (e) {
        // إذا كان الملف موجوداً بالفعل (مفتاح مكرر)
        if (e.code == '23505') {
          print(
            '⚠️ الملف الشخصي موجود ولكن فشل الوصول، جاري المحاولة مرة أخرى...',
          );

          // انتظر قليلاً ثم حاول مرة أخرى
          await Future.delayed(const Duration(seconds: 1));

          final retryProfile = await getUserProfile(userId);
          if (retryProfile != null) {
            return retryProfile;
          }

          // إذا فشل، أنشئ ملفاً جديداً بمعرف مختلف
          return await _createProfileWithNewId(
            originalUserId: userId,
            email: email,
            fullName: fullName,
            phone: phone,
          );
        }
        rethrow;
      }
    } catch (e) {
      print('❌ خطأ في _getOrCreateProfile: $e');
      throw Exception('فشل إنشاء الملف الشخصي: ${e.toString()}');
    }
  }

  // إنشاء ملف شخصي بمعرف جديد
  Future<UserModel> _createProfileWithNewId({
    required String originalUserId,
    required String email,
    required String fullName,
    String? phone,
  }) async {
    try {
      final newUserId =
          '${originalUserId}_${DateTime.now().millisecondsSinceEpoch}';

      print('🔄 إنشاء ملف شخصي جديد بالمعرف: $newUserId');

      final data = await _client
          .from('profiles')
          .insert({
            'id': newUserId,
            'email': email,
            'full_name': fullName,
            'phone': phone,
            'role': 'client',
            'kyc_status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return UserModel.fromJson(data);
    } catch (e) {
      print('❌ فشل إنشاء ملف شخصي جديد: $e');
      throw Exception('فشل إنشاء الملف الشخصي');
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('فشل تسجيل الخروج: ${e.toString()}');
    }
  }

  // تحديث الملف الشخصي
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? avatarPath,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (phone != null) updateData['phone'] = phone;
      if (avatarPath != null) updateData['avatar_url'] = avatarPath;

      final data = await _client
          .from('profiles')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(data);
    } catch (e) {
      throw Exception('فشل تحديث الملف الشخصي: ${e.toString()}');
    }
  }

  // الحصول على الملف الشخصي
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return data != null ? UserModel.fromJson(data) : null;
    } catch (e) {
      print('❌ خطأ في getUserProfile: $e');
      return null;
    }
  }

  // إنشاء ملف شخصي (النسخة الأصلية - للتوافق)
  Future<UserModel> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phone,
  }) async {
    return await _getOrCreateProfile(
      userId: userId,
      email: email,
      fullName: fullName,
      phone: phone,
    );
  }

  // إرسال طلب التحقق (KYC)
  Future<void> submitKyc({
    required String userId,
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
    String? incomeProofPath,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({
            'kyc_status': 'under_review',
            'kyc_submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw Exception('فشل إرسال طلب التحقق: ${e.toString()}');
    }
  }

  // التحقق من رقم الهاتف
  Future<void> verifyPhone(String code) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // إعادة إرسال رمز التحقق
  Future<void> resendPhoneVerificationCode() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // الحصول على حالة المصادقة
  bool get isAuthenticated => _client.auth.currentSession != null;
  String? get currentUserId => _client.auth.currentUser?.id;
}
