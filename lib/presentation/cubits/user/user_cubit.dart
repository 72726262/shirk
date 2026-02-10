// lib/presentation/cubits/user/user_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mmm/data/repositories/user_repository.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository userRepository;

  UserCubit({required this.userRepository}) : super(UserInitial());

  // الحصول على جميع المستخدمين
  Future<void> getAllUsers() async {
    try {
      emit(UserLoading());

      final users = await userRepository.getAllUsers();

      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  // تحديث دور المستخدم
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      emit(UserLoading());

      await userRepository.updateUserRole(userId: userId, newRole: newRole);

      // إعادة تحميل المستخدمين
      await getAllUsers();
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }
}
