-- ============================================
-- CHECK & FIX: Verify Trigger + RLS Policies
-- ============================================

-- 1. First, check if profile was actually created
SELECT id, email, full_name, role, kyc_status, created_at
FROM public.profiles
WHERE id = '9c9cbb31-2441-4981-b0d2-3e1dca23f67d';

-- If you see a row, the trigger worked! The issue is RLS blocking reads.
-- If no rows, the trigger didn't fire or failed silently.

-- ============================================
-- 2. Check RLS policies on profiles table
-- ============================================
SELECT tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'profiles';

-- ============================================
-- 3. CRITICAL FIX: Ensure RLS allows authenticated users to read their own profile
-- ============================================

-- Drop old policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;

-- Create simple policy: users can read their own profile
CREATE POLICY "Users can read their own profile"
ON public.profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Admins can read all profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
CREATE POLICY "Admins can view all profiles"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
    AND role IN ('admin', 'super_admin')
  )
);

-- ============================================
-- 4. Enable RLS on profiles (if not already enabled)
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. Check if trigger is actually firing
-- ============================================
-- Let's check auth.users to see if the user exists
SELECT id, email, created_at
FROM auth.users
WHERE id = '9c9cbb31-2441-4981-b0d2-3e1dca23f67d';

-- ============================================
-- SUMMARY OF WHAT TO RUN:
-- ============================================
-- Run sections 3, 4 first (the policies)
-- Then try signup again with a NEW email
-- If still fails, run section 1 to check if profile exists
