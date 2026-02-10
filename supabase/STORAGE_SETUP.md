# 🗄️ Supabase Storage Buckets Setup

## Overview
Create these 7 storage buckets in your Supabase project for file uploads.

---

## 📦 Buckets to Create

### 1. **avatars**
**Purpose**: User profile pictures

**Settings**:
- Public: ✅ Yes
- File size limit: 5 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

**Policies**:
```sql
-- Users can upload their own avatar
CREATE POLICY "Users can upload own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own avatar
CREATE POLICY "Users can update own avatar"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Anyone can view avatars (public)
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

---

### 2. **kyc_documents**
**Purpose**: KYC verification files (ID front/back, selfie, income proof)

**Settings**:
- Public: ❌ No (Private)
- File size limit: 10 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `application/pdf`

**Policies**:
```sql
-- Users can upload their own KYC documents
CREATE POLICY "Users can upload own KYC"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc_documents' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can view their own KYC documents
CREATE POLICY "Users can view own KYC"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'kyc_documents' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Admins can view all KYC documents
CREATE POLICY "Admins can view all KYC"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'kyc_documents' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);
```

---

### 3. **project_images**
**Purpose**: Project photos, hero images, renders

**Settings**:
- Public: ✅ Yes
- File size limit: 15 MB
- Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`

**Policies**:
```sql
-- Admins can upload project images
CREATE POLICY "Admins can upload project images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'project_images' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- Anyone can view project images (public)
CREATE POLICY "Anyone can view project images"
ON storage.objects FOR SELECT
USING (bucket_id = 'project_images');
```

---

### 4. **documents**
**Purpose**: User documents (contracts, invoices, receipts, certificates)

**Settings**:
- Public: ❌ No (Private)
- File size limit: 20 MB
- Allowed MIME types: `application/pdf`, `image/jpeg`, `image/png`

**Policies**:
```sql
-- Users can upload their own documents
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documents' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can view their own documents
CREATE POLICY "Users can view own documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Admins can view all documents
CREATE POLICY "Admins can view all documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- Users/Admins can delete documents
CREATE POLICY "Users can delete own documents"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'documents' 
  AND (
    auth.uid()::text = (storage.foldername(name))[1]
    OR (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
  )
);
```

---

### 5. **signatures**
**Purpose**: E-signatures for contracts, handovers

**Settings**:
- Public: ❌ No (Private)
- File size limit: 2 MB
- Allowed MIME types: `image/png`, `image/jpeg`

**Policies**:
```sql
-- Users can upload their own signatures
CREATE POLICY "Users can upload own signatures"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'signatures' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can view their own signatures
CREATE POLICY "Users can view own signatures"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'signatures' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Admins can view all signatures
CREATE POLICY "Admins can view all signatures"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'signatures' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);
```

---

### 6. **construction_media**
**Purpose**: Construction update photos and videos

**Settings**:
- Public: ✅ Yes (if updates are public)
- File size limit: 50 MB (for videos)
- Allowed MIME types: `image/jpeg`, `image/png`, `video/mp4`, `video/quicktime`

**Policies**:
```sql
-- Admins can upload construction media
CREATE POLICY "Admins can upload construction media"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'construction_media' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- Anyone can view construction media (public)
CREATE POLICY "Anyone can view construction media"
ON storage.objects FOR SELECT
USING (bucket_id = 'construction_media');
```

---

### 7. **construction_reports**
**Purpose**: Engineering, financial, supervision reports

**Settings**:
- Public: ❌ No (Private - only for subscribers)
- File size limit: 30 MB
- Allowed MIME types: `application/pdf`

**Policies**:
```sql
-- Admins can upload construction reports
CREATE POLICY "Admins can upload construction reports"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'construction_reports' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- Admins can view all construction reports
CREATE POLICY "Admins can view all construction reports"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'construction_reports' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- TODO: Add policy for project subscribers to view reports
```

---

### 8. **defect_photos**
**Purpose**: Handover defect photos

**Settings**:
- Public: ❌ No (Private)
- File size limit: 10 MB
- Allowed MIME types: `image/jpeg`, `image/png`

**Policies**:
```sql
-- Users can upload defect photos for their handovers
CREATE POLICY "Users can upload defect photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'defect_photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can view their own defect photos
CREATE POLICY "Users can view own defect photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'defect_photos' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Admins can view all defect photos
CREATE POLICY "Admins can view all defect photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'defect_photos' 
  AND (SELECT role FROM profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);
```

---

## 📝 How to Create Buckets

### Via Supabase Dashboard:
1. Go to **Storage** in Supabase Dashboard
2. Click **"New bucket"**
3. Enter bucket name (e.g., `avatars`)
4. Set public/private setting
5. Click **"Create bucket"**
6. Go to bucket **Policies** tab
7. Click **"New policy"**
8. Paste SQL policy code
9. Repeat for all 7 buckets

### Via SQL:
```sql
-- Run this in SQL Editor
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

Then add policies for each bucket as shown above.

---

## ✅ Verification

After creating all buckets, verify:
- [ ] All 7 buckets exist
- [ ] Public/private settings correct
- [ ] Policies configured for each bucket
- [ ] Test file upload from app

---

**Status**: Ready to configure! 🚀
