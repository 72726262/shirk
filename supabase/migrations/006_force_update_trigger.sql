-- ============================================
-- DEBUG & FIX: Force Update Role Assignment Trigger
-- ============================================

-- 1. Drop existing trigger and function to ensure clean state
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. Re-create the function with explicit logging and role handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role text;
  v_full_name text;
BEGIN
  -- Extract values with defaults
  v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'client');
  v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', '');
  
  -- Log the values for debugging (check Postgres logs if needed)
  RAISE NOTICE 'Creating profile for user % with role: %', NEW.id, v_role;

  -- Validate role just in case (optional, but good for safety)
  IF v_role NOT IN ('client', 'admin', 'super_admin') THEN
    v_role := 'client';
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    full_name,
    role,
    kyc_status,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    v_full_name,
    v_role,
    'pending',
    NOW(),
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 4. Verify the function exists
SELECT proname, prosrc FROM pg_proc WHERE proname = 'handle_new_user';
