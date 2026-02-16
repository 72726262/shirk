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
    String role = 'client', // Default role is client
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
            role: role,
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
        data: {
          'full_name': fullName.trim(),
          'phone': phone?.trim(),
          'role': role,
        },
      );

      print('✅ استجابة إنشاء الحساب: ${response.user?.id}');

      if (response.user != null) {
        // 3. انتظار إنشاء الملف الشخصي من الـ trigger
        print('⏳ انتظار إنشاء الملف الشخصي التلقائي...');

        final profile = await _getOrCreateProfile(
          userId: response.user!.id,
          email: email.trim(),
          fullName: fullName.trim(),
          phone: phone?.trim(),
          role: role,
        );

        print('🎉 تم إنشاء الحساب بنجاح! الرجاء تسجيل الدخول.');
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

  // دالة مساعدة: احصل على الملف الشخصي (ينشئه الـ trigger تلقائياً)
  Future<UserModel> _getOrCreateProfile({
    required String userId,
    required String email,
    required String fullName,
    String? phone,
    String role = 'client',
  }) async {
    try {
      print('🔍 البحث عن الملف الشخصي للمستخدم: $userId');

      // الـ trigger يقوم بإنشاء Profile تلقائياً بعد signup
      // لكن قد يحتاج وقت بسيط، لذا نحاول عدة مرات

      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          final profile = await getUserProfile(userId);
          if (profile != null) {
            print('✅ تم العثور على الملف الشخصي بنجاح');
            return profile;
          }
        } catch (e) {
          print('⚠️ المحاولة $attempt: لم يتم العثور على الملف بعد...');
        }

        // انتظر قبل المحاولة التالية (exponential backoff)
        if (attempt < 5) {
          await Future.delayed(Duration(milliseconds: 200 * attempt));
        }
      }

      // إذا فشلت جميع المحاولات
      throw Exception(
        'لم يتم العثور على الملف الشخصي.\n\n'
        '⚠️ تأكد من تطبيق SQL Trigger في Supabase Dashboard:\n'
        '1. افتح Supabase Dashboard\n'
        '2. اذهب لـ SQL Editor\n'
        '3. طبّق ملف 002_fix_profile_creation.sql\n\n'
        'بعد ذلك جرب التسجيل مرة أخرى.',
      );
    } catch (e) {
      print('❌ خطأ في _getOrCreateProfile: $e');
      rethrow;
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

  // إنشاء مستخدم جديد بواسطة الـ Admin
  Future<UserModel> createUserByAdmin({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'client',
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

      print('👤 Admin: إنشاء مستخدم جديد: ${email.trim()}');

      // إنشاء حساب جديد في auth
      final response = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: email.trim(),
          password: password,
          emailConfirm: true, // تأكيد البريد تلقائياً
          userMetadata: {
            'full_name': fullName.trim(),
            'phone': phone.trim(),
            'role': role,
          },
        ),
      );

      if (response.user != null) {
        print('✅ تم إنشاء الحساب في Auth');

        // الانتظار قليلاً لـ trigger
        await Future.delayed(const Duration(milliseconds: 500));

        // التأكد من إنشاء الملف الشخصي
        final profile = await _getOrCreateProfile(
          userId: response.user!.id,
          email: email.trim(),
          fullName: fullName.trim(),
          phone: phone.trim(),
          role: role,
        );

        // إنشاء محفظة للمستخدم الجديد
        try {
          await _client.from('wallets').insert({
            'user_id': response.user!.id,
            'balance': 0.0,
            'reserved_amount': 0.0,
          });
          print('✅ تم إنشاء المحفظة');
        } catch (e) {
          print('⚠️ خطأ في إنشاء المحفظة (قد تكون موجودة): $e');
        }

        print('🎉 تم إنشاء المستخدم بنجاح (Admin)');
        return profile;
      }

      throw Exception('حدث خطأ أثناء إنشاء ملف المستخدم');
    } on AuthException catch (e) {
      print('❌ خطأ مصادقة في إنشاء المستخدم: ${e.message}');

      if (e.message.contains('already registered') ||
          e.message.contains('User already registered')) {
        throw Exception('البريد الإلكتروني مسجل مسبقاً');
      }

      throw Exception('فشل إنشاء المستخدم: ${e.message}');
    } catch (e) {
      print('❌ خطأ غير متوقع في إنشاء المستخدم: $e');
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }
}
