# Sharik Platform - تعليمات إعداد Supabase

## الخطوة 1: إعداد قاعدة البيانات

### 1.1 إنشاء المشروع في Supabase
1. اذهب إلى [Supabase Dashboard](https://supabase.com/dashboard)
2. أنشئ مشروع جديد
3. احفظ الـ Project URL و anon/public key

### 1.2 تشغيل SQL Scripts
في Supabase Dashboard > SQL Editor:

```sql
-- 1. قم بتشغيل schema الرئيسي أولاً (من user request)
-- نسخ والصق كل الـ CREATE TABLE statements

-- 2. ثم قم بتشغيل ملف الإعداد الكامل
-- نسخ من: supabase/migrations/001_complete_setup.sql
```

## الخطوة 2: التحقق من Storage Buckets

بعد تشغيل الـ SQL، تحقق من:
1. اذهب إلى Storage في Supabase Dashboard
2. تأكد من وجود 6 buckets:
   - `project-images` (Public)
   - `construction-media` (Public)
   - `reports` (Private)
   - `documents` (Private)
   - `kyc-documents` (Private)
   - `avatars` (Public)

## الخطوة 3: إعداد Flutter App

### 3.1 تحديث Environment Variables
في `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

### 3.2 تشغيل Dependencies
```bash
flutter pub get
```

### 3.3 Initialize Services في main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Initialize Network Service
  await NetworkService().initialize();
  
  // Initialize Cache Service
  await CacheService().initialize();
  
  runApp(const MyApp());
}
```

## الخطوة 4: RLS Policies

الـ RLS Policies تم تضمينها في السكريبت. تأكد من:
- كل user يمكنه الوصول لبياناته فقط
- Admins يمكنهم الوصول لكل البيانات
- Public buckets يمكن القراءة منها للجميع

## الخطوة 5: Testing

### Test Storage Upload
```dart
// Example: Upload project image
final file = File('path/to/image.jpg');
final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
final path = 'projects/$projectId/$fileName';

await Supabase.instance.client.storage
  .from('project-images')
  .upload(path, file);

final url = Supabase.instance.client.storage
  .from('project-images')
  .getPublicUrl(path);
```

### Test Database Query
```dart
// Example: Get projects
final projects = await Supabase.instance.client
  .from('projects')
  .select()
  .eq('status', 'in_progress');
```

## الخطوة 6: Offline Mode Setup

Offline mode يعمل تلقائياً عند:
1. فقدان الاتصال بالإنترنت
2. عرض البيانات المخزنة مؤقتاً
3. Sync تلقائي عند العودة Online

## الميزات المفعلة

✅ Storage Buckets مع RLS
✅ Auto-create Wallet عند التسجيل
✅ Activity Logging Function
✅ Project Stats Auto-update
✅ Indexes للأداء
✅ Helper Functions
✅ Triggers

## استكشاف الأخطاء

### مشكلة: لا يمكن Upload للملفات
- تحقق من RLS policies في Storage
- تأكد من authentications

### مشكلة: بطء في الاستعلامات
- تحقق من وجود الـ Indexes
- استخدم `.select()` بدلاً من `.select('*')`

### مشكلة: Offline mode لا يعمل
- تأكد من initialize CacheService في main
- تحقق من الـ permissions للـ SharedPreferences

## الخلاصة

المنصة الآن جاهزة بالكامل مع:
- ✅ Database Schema
- ✅ Storage Setup
- ✅ RLS Policies
- ✅ Helper Functions
- ✅ Offline Support
- ✅ Network Detection
- ✅ Error Handling

🎉 **Sharik Platform is ready to use!**
