-- ============================================
-- FINAL FIX: Create profiles for ALL existing users without profiles
-- ============================================

-- This will create profiles for any auth.users that don't have a profile yet
INSERT INTO public.profiles (id, email, full_name, role, kyc_status, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', 'User'),
  'client',
  'pending',
  NOW(),
  NOW()
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Check how many profiles were created
SELECT 'Profiles created successfully!' AS status, COUNT(*) AS count
FROM public.profiles;
