# 🚀 Sharik Platform - Deployment Guide

## 📋 Pre-Deployment Checklist

### ✅ Code Complete
- [x] All 16 models created
- [x] All 9 repositories implemented
- [x] All 9 services created
- [x] All 13 cubits implemented
- [x] All 38 screens designed
- [x] All routes configured
- [x] Main.dart integrated

### ⏳ Supabase Setup
- [ ] Supabase project created
- [ ] Database tables created (run `001_create_tables.sql`)
- [ ] RLS policies configured (run `002_rls_policies.sql`)
- [ ] Storage buckets created (8 buckets - see `STORAGE_SETUP.md`)
- [ ] Storage policies configured
- [ ] Environment variables set

### ⏳ Testing
- [ ] Manual testing completed (see `testing_checklist.md`)
- [ ] All critical bugs fixed
- [ ] UI/UX verification passed
- [ ] Real-time features tested
- [ ] File uploads tested

---

## 🛠️ Step 1: Supabase Project Setup

### 1.1 Create Project
1. Go to [supabase.com](https://supabase.com)
2. Click **"New Project"**
3. Organization: Select or create
4. Name: `sharik-platform`
5. Database Password: Generate strong password (save it!)
6. Region: Select closest to Saudi Arabia (e.g., `ap-south-1`)
7. Click **"Create new project"**
8. Wait ~2 minutes for provisioning

### 1.2 Get API Credentials
1. Go to **Settings** → **API**
2. Copy **Project URL**: `https://xxxxx.supabase.co`
3. Copy **anon/public key**: `eyJhbGc...`

### 1.3 Update Flutter App
Open `lib/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
}
```

---

## 📊 Step 2: Database Setup

### 2.1 Create Tables
1. Go to **SQL Editor** in Supabase Dashboard
2. Create new query
3. Copy entire contents of `supabase/migrations/001_create_tables.sql`
4. Paste and click **"Run"**
5. Should see: `Success. No rows returned`
6. Verify in **Table Editor** → 15 tables created

### 2.2 Enable RLS Policies
1. Go to **SQL Editor**
2. Create new query
3. Copy contents of `supabase/migrations/002_rls_policies.sql`
4. Paste and click **"Run"**
5. Verify in **Authentication** → **Policies** → See policies for each table

### 2.3 Create Admin User
1. Go to **SQL Editor**
2. Run this query:

```sql
-- Create admin user (update email/password)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES (
  gen_random_uuid(),
  'admin@sharik.com',
  crypt('Admin123!', gen_salt('bf')),
  NOW(),
  NOW(),
  NOW()
);

-- Get the user ID (copy from result)
SELECT id, email FROM auth.users WHERE email = 'admin@sharik.com';

-- Create admin profile (replace USER_ID_HERE with actual ID)
INSERT INTO profiles (id, email, full_name, role, kyc_status)
VALUES (
  'USER_ID_HERE',
  'admin@sharik.com',
  'System Admin',
  'super_admin',
  'approved'
);
```

---

## 🗄️ Step 3: Storage Buckets Setup

### 3.1 Create Buckets
Follow instructions in `supabase/STORAGE_SETUP.md`:

1. Go to **Storage** in Supabase Dashboard
2. Create these 8 buckets:
   - `avatars` (public)
   - `kyc_documents` (private)
   - `project_images` (public)
   - `documents` (private)
   - `signatures` (private)
   - `construction_media` (public)
   - `construction_reports` (private)
   - `defect_photos` (private)

### 3.2 Configure Bucket Policies
For each bucket, add policies from `STORAGE_SETUP.md`

**Quick SQL for all buckets**:
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('avatars', 'avatars', true),
  ('kyc_documents', 'kyc_documents', false),
  ('project_images', 'project_images', true),
  ('documents', 'documents', false),
  ('signatures', 'signatures', false),
  ('construction_media', 'construction_media', true),
  ('construction_reports', 'construction_reports', false),
  ('defect_photos', 'defect_photos', false);
```

---

## 📱 Step 4: Flutter App Setup

### 4.1 Install Dependencies
```bash
cd c:\Users\HP\Desktop\Projects\sharik
flutter pub get
```

### 4.2 Run Code Generation (if using freezed/json_serializable)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4.3 Run App
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

### 4.4 Verify Connection
1. Launch app
2. Should see login screen (no errors)
3. Check logs for Supabase connection success
4. Try registering a test user

---

## 🧪 Step 5: Testing Phase

Follow detailed testing checklist in `testing_checklist.md`:

### Critical Flows to Test:
1. ✅ Registration + KYC
2. ✅ Dashboard aggregation
3. ✅ Browse + join project (full flow)
4. ✅ Wallet operations
5. ✅ Construction tracking (real-time)
6. ✅ Documents upload/sign
7. ✅ Handover with defects
8. ✅ Admin panel operations
9. ✅ Notifications (real-time)

### UI/UX to Verify:
1. ✅ Skeleton loaders
2. ✅ Empty states
3. ✅ Error handling
4. ✅ Smooth animations
5. ✅ Responsive design
6. ✅ RTL/Arabic support

---

## 🐛 Step 6: Bug Fixing

### Common Issues & Solutions:

#### Issue: "Failed to connect to Supabase"
**Solution**:
- Check `supabase_config.dart` has correct URL/key
- Verify Supabase project is running (not paused)
- Check internet connection

#### Issue: "Storage upload failed"
**Solution**:
- Verify bucket exists
- Check bucket policies configured
- Ensure file size within limits
- Check file type allowed

#### Issue: "RLS policy prevents access"
**Solution**:
- Run `002_rls_policies.sql` again
- Check user role in `profiles` table
- Verify auth token valid

#### Issue: "Real-time not working"
**Solution**:
- Enable Realtime in Supabase (Database → Replication)
- Check table has Realtime enabled
- Verify subscription code correct

---

## 🚀 Step 7: Production Deployment

### 7.1 Prepare for Production

**Update Environment**:
```dart
// lib/core/config/environment.dart
enum Environment { development, production }

class Config {
  static const Environment current = Environment.production;
  
  static String get supabaseUrl {
    switch (current) {
      case Environment.development:
        return 'https://dev.supabase.co';
      case Environment.production:
        return 'https://prod.supabase.co';
    }
  }
}
```

**Remove Debug Code**:
- Remove print statements
- Remove test data
- Disable debug logging

**Optimize Assets**:
```bash
flutter build apk --release --shrink
flutter build ios --release
flutter build web --release
```

### 7.2 Android Release

**Build APK**:
```bash
flutter build apk --release
```

**Build App Bundle** (for Play Store):
```bash
flutter build appbundle --release
```

**Sign APK** (if not using app bundle):
1. Create keystore:
```bash
keytool -genkey -v -keystore sharik.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sharik
```

2. Update `android/key.properties`:
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=sharik
storeFile=../sharik.jks
```

### 7.3 iOS Release

**Build iOS**:
```bash
flutter build ios --release
```

**Upload to App Store**:
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select **Product** → **Archive**
3. Upload to App Store Connect

### 7.4 Web Release

**Build Web**:
```bash
flutter build web --release
```

**Deploy to Hosting**:

**Option 1: Firebase Hosting**
```bash
firebase init hosting
firebase deploy
```

**Option 2: Vercel**
```bash
vercel --prod
```

**Option 3: Netlify**
- Drag `build/web` folder to Netlify

---

## 📊 Step 8: Monitoring & Analytics

### 8.1 Setup Crashlytics (Firebase)
```bash
flutter pub add firebase_crashlytics
flutterfire configure
```

### 8.2 Setup Analytics
```bash
flutter pub add firebase_analytics
```

### 8.3 Supabase Monitoring
- Go to **Logs** → Monitor errors
- Go to **Database** → Performance → Check query performance
- Go to **Storage** → Monitor upload/download

---

## ✅ Deployment Checklist Complete

### Before Going Live:
- [ ] All features tested thoroughly
- [ ] No critical bugs
- [ ] Performance optimized
- [ ] Security reviewed (RLS policies)
- [ ] Analytics configured
- [ ] Crash reporting setup
- [ ] Admin account created
- [ ] Test data cleared
- [ ] Privacy policy/terms added
- [ ] App store listings ready

---

## 🎉 Launch Day!

1. **Soft Launch** (limited users)
   - Deploy to beta testers
   - Collect feedback
   - Fix issues

2. **Full Launch**
   - Deploy to production
   - Marketing campaign
   - Monitor closely

3. **Post-Launch**
   - Monitor analytics
   - Fix reported bugs
   - Iterate on features

---

**Good Luck! 🚀**

---

## 📞 Support Resources

- **Supabase Docs**: [https://supabase.com/docs](https://supabase.com/docs)
- **Flutter Docs**: [https://flutter.dev](https://flutter.dev)
- **Flutter Bloc**: [https://bloclibrary.dev](https://bloclibrary.dev)

---

## 📝 Next Steps After Launch

1. **User Onboarding**: Create tutorial/walkthrough
2. **Push Notifications**: Setup FCM
3. **In-App Chat**: Add customer support chat
4. **Payment Gateway**: Integrate real payment (Moyasar/Hyperpay)
5. **Advanced Analytics**: Track user behavior
6. **A/B Testing**: Test different UI variations
7. **Internationalization**: Add English language
8. **Performance Optimization**: Analyze and optimize slow queries

---

**Platform Status**: 🟢 **Ready for Deployment!**
