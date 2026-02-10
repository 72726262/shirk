import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized error handling utility
/// Converts technical exceptions to user-friendly Arabic messages
class ErrorHandler {
  /// Get user-friendly error message in Arabic
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') || 
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'خطأ في الاتصال بالإنترنت. تحقق من اتصالك وحاول مرة أخرى.';
    }

    // Supabase Auth errors
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          if (errorString.contains('email')) {
            return 'البريد الإلكتروني غير صحيح';
          }
          if (errorString.contains('password')) {
            return 'كلمة المرور غير صحيحة';
          }
          return 'بيانات غير صحيحة';
        case '401':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        case '422':
          return 'البريد الإلكتروني مستخدم بالفعل';
        case '429':
          return 'عدد كبير من المحاولات. حاول مرة أخرى بعد قليل.';
        default:
          return 'خطأ في المصادقة: ${error.message}';
      }
    }

    // Supabase Postgrest errors
    if (error is PostgrestException) {
      if (errorString.contains('duplicate')) {
        return 'البيانات موجودة بالفعل';
      }
      if (errorString.contains('foreign key')) {
        return 'لا يمكن حذف هذا العنصر لأنه مرتبط ببيانات أخرى';
      }
      if (errorString.contains('not found')) {
        return 'العنصر المطلوب غير موجود';
      }
      return 'خطأ في قاعدة البيانات: ${error.message}';
    }

    // Storage errors
    if (errorString.contains('storage')) {
      if (errorString.contains('size') || errorString.contains('large')) {
        return 'حجم الملف كبير جداً. الحد الأقصى 10MB';
      }
      if (errorString.contains('type') || errorString.contains('format')) {
        return 'نوع الملف غير مدعوم';
      }
      return 'خطأ في رفع الملف';
    }

    // Permission errors
    if (errorString.contains('permission') || 
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      return 'ليس لديك صلاحية للقيام بهذا الإجراء';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
    }

    // File/Data errors
    if (errorString.contains('file not found')) {
      return 'الملف المطلوب غير موجود';
    }

    if (errorString.contains('invalid') || errorString.contains('malformed')) {
      return 'البيانات المدخلة غير صحيحة';
    }

    // Generic exception message
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '');
      // If message is already in Arabic, return it
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(message)) {
        return message;
      }
      return 'حدث خطأ: $message';
    }

    // Fallback
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  /// Log error for debugging
  static void logError(dynamic error, StackTrace? stackTrace) {
    print('━━━━━━━ ERROR ━━━━━━━');
    print('Error: $error');
    if (stackTrace != null) {
      print('Stack Trace:\n$stackTrace');
    }
    print('━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Show error as Snackbar (requires BuildContext)
  static void showError(dynamic error, {StackTrace? stackTrace}) {
    logError(error, stackTrace);
    // Message will be shown via Cubit error states
  }
}
