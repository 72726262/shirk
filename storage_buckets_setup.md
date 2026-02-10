# Supabase Storage Buckets Setup

بعد تشغيل ملف `supabase_schema.sql`، اتبع الخطوات التالية لإنشاء Storage Buckets:

## خطوات الإعداد

### 1. افتح Supabase Dashboard
اذهب إلى: **Storage** → **Create a new bucket**

### 2. أنشئ البكتات التالية:

#### Bucket 1: `kyc-documents`
- **Name**: `kyc-documents`
- **Public**: ❌ (Private)
- **File size limit**: 10 MB
- **Allowed MIME types**: `image/jpeg`, `image/png`, `application/pdf`

#### Bucket 2: `project-media`
- **Name**: `project-media`
- **Public**: ✅ (Public) - للصور الرئيسية للمشاريع
- **File size limit**: 20 MB
- **Allowed MIME types**: `image/*`, `video/*`

#### Bucket 3: `construction-updates`
- **Name**: `construction-updates`
- **Public**: ✅ (Public)
- **File size limit**: 50 MB
- **Allowed MIME types**: `image/*`, `video/*`

#### Bucket 4: `documents`
- **Name**: `documents`
- **Public**: ❌ (Private)
- **File size limit**: 10 MB
- **Allowed MIME types**: `application/pdf`

#### Bucket 5: `signatures`
- **Name**: `signatures`
- **Public**: ❌ (Private)
- **File size limit**: 2 MB
- **Allowed MIME types**: `image/png`, `image/jpeg`

#### Bucket 6: `handover-photos`
- **Name**: `handover-photos`
- **Public**: ❌ (Private)
- **File size limit**: 10 MB
- **Allowed MIME types**: `image/jpeg`, `image/png`

#### Bucket 7: `avatars`
- **Name**: `avatars`
- **Public**: ✅ (Public)
- **File size limit**: 2 MB
- **Allowed MIME types**: `image/jpeg`, `image/png`

---

## RLS Policies للـ Storage

### For `kyc-documents`:
```sql
-- Users can upload their own KYC documents
CREATE POLICY "Users can upload own KYC"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'kyc-documents' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can view their own KYC documents
CREATE POLICY "Users can view own KYC"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc-documents' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Admins can view all KYC documents
CREATE POLICY "Admins can view all KYC"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'kyc-documents'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);
```

### For `avatars`:
```sql
-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Anyone can view avatars (public)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');
```

### For `project-media` (Public):
```sql
-- Admins can upload project media
CREATE POLICY "Admins can upload project media"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'project-media'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- Anyone can view project media
CREATE POLICY "Anyone can view project media"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'project-media');
```

### For `documents`:
```sql
-- Users can view their own documents
CREATE POLICY "Users can view own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  )
);

-- Admins can upload documents
CREATE POLICY "Admins can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);
```

---

## Email Templates (Optional)

في **Authentication** → **Email Templates**، خصص:

1. **Confirm signup**: رسالة تأكيد التسجيل
2. **Magic Link**: لو استخدمنا Magic Link
3. **Change Email Address**: تغيير الإيميل
4. **Reset Password**: إعادة تعيين كلمة المرور

---

## Test Admin Account

بعد الانتهاء، أنشئ حساب admin للاختبار:

```sql
-- في SQL Editor، نفذ:
UPDATE public.profiles
SET role = 'super_admin'
WHERE email = 'your-admin@email.com';
```

---

✅ **Done!** Database جاهز للاستخدام
