-- =====================================================
-- CHAT STORAGE BUCKETS SETUP
-- =====================================================

-- 1. Create chat-images bucket for image attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-images',
  'chat-images',
  false,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create chat-files bucket for file attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-files',
  'chat-files',
  false,
  10485760, -- 10MB
  ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STORAGE RLS POLICIES
-- =====================================================

-- Chat Images Policies

-- Allow authenticated users to upload images
DROP POLICY IF EXISTS "Users can upload chat images" ON storage.objects;
CREATE POLICY "Users can upload chat images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-images' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view images in their chats
DROP POLICY IF EXISTS "Users can view chat images" ON storage.objects;
CREATE POLICY "Users can view chat images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'chat-images' 
  AND (
    -- Owner can view
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Or if they're a member of a chat that uses this image
    EXISTS (
      SELECT 1 FROM messages m
      INNER JOIN chat_members cm ON cm.chat_id = m.chat_id
      WHERE m.media_url LIKE '%' || name || '%'
      AND cm.user_id = auth.uid()
    )
  )
);

-- Allow users to delete their own images
DROP POLICY IF EXISTS "Users can delete own chat images" ON storage.objects;
CREATE POLICY "Users can delete own chat images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat-images'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Chat Files Policies

-- Allow authenticated users to upload files
DROP POLICY IF EXISTS "Users can upload chat files" ON storage.objects;
CREATE POLICY "Users can upload chat files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'chat-files'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to view files in their chats
DROP POLICY IF EXISTS "Users can view chat files" ON storage.objects;
CREATE POLICY "Users can view chat files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'chat-files'
  AND (
    -- Owner can view
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Or if they're a member of a chat that uses this file
    EXISTS (
      SELECT 1 FROM messages m
      INNER JOIN chat_members cm ON cm.chat_id = m.chat_id
      WHERE m.media_url LIKE '%' || name || '%'
      AND cm.user_id = auth.uid()
    )
  )
);

-- Allow users to delete their own files
DROP POLICY IF EXISTS "Users can delete own chat files" ON storage.objects;
CREATE POLICY "Users can delete own chat files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'chat-files'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
