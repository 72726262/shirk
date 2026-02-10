import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/auth_repository.dart'; // تم التعديل هنا

// States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserModel user;

  const ProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class ProfileUpdating extends ProfileState {
  final String message;

  const ProfileUpdating(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdated extends ProfileState {
  final UserModel user;

  const ProfileUpdated({required this.user});

  @override
  List<Object?> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepository; // تم التعديل هنا

  ProfileCubit({required AuthRepository authRepository}) // تم التعديل هنا
    : _authRepository = authRepository,
      super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      // تم التعديل هنا: استخدام _authRepository مباشرة
      final user = await _authRepository.getCurrentUser();

      if (user == null) {
        emit(const ProfileError('المستخدم غير موجود'));
        return;
      }

      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarPath,
  }) async {
    if (state is! ProfileLoaded) {
      emit(const ProfileError('يجب تحميل الملف الشخصي أولاً'));
      return;
    }

    final currentUser =
        (state as ProfileLoaded).user; // ← يحصل على userId من state

    await _authRepository.updateProfile(
      userId: currentUser.id, // ← هنا يستخدم userId من currentUser
      fullName: fullName,
      phone: phone,
      avatarPath: avatarPath,
    );
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  // دالة إضافية لتحديث الصورة فقط
  Future<void> updateAvatar(String avatarPath) async {
    if (state is! ProfileLoaded) {
      emit(const ProfileError('يجب تحميل الملف الشخصي أولاً'));
      return;
    }

    final currentUser = (state as ProfileLoaded).user;
    emit(const ProfileUpdating('جاري تحديث الصورة...'));

    try {
      final updatedUser = await _authRepository.updateProfile(
        userId: currentUser.id,
        avatarPath: avatarPath,
      );

      emit(ProfileUpdated(user: updatedUser));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // دالة إضافية لتغيير كلمة المرور
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state is! ProfileLoaded) {
      emit(const ProfileError('يجب تحميل الملف الشخصي أولاً'));
      return;
    }

    final currentUser = (state as ProfileLoaded).user;
    emit(const ProfileUpdating('جاري تغيير كلمة المرور...'));

    try {
      await _authRepository.changePassword(
        userId: currentUser.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // إعادة تحميل البيانات بعد التحديث
      await loadProfile();
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // دالة للحصول على بيانات المستخدم الحالي
  UserModel? getCurrentUserData() {
    if (state is ProfileLoaded) {
      return (state as ProfileLoaded).user;
    }
    return null;
  }

  // دالة للتحقق مما إذا كان المستخدم محمل
  bool get isProfileLoaded => state is ProfileLoaded;

  // دالة للتحقق مما إذا كان هناك تحديث
  bool get isUpdating => state is ProfileUpdating;
}
