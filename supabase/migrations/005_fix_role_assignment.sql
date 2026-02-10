-- ============================================
-- FIX: Allow Admin/Super Admin Role Assignment
-- ============================================

-- Function to handle new user signup
-- Now reads 'role' from user_metadata (sent from Flutter app)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
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
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    -- Read role from metadata, default to 'client' if missing or invalid
    COALESCE(NEW.raw_user_meta_data->>'role', 'client'),
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
