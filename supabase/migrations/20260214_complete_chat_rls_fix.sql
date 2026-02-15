-- ========================================
-- COMPLETE CHAT RLS FIX - Run this entire script
-- ========================================

-- PART 1: Disable RLS temporarily to clean up
ALTER TABLE chats DISABLE ROW LEVEL SECURITY;
ALTER TABLE chat_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- PART 2: Drop ALL existing policies
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    -- Drop all policies on chats
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'chats') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON chats';
    END LOOP;
    
    -- Drop all policies on chat_members
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'chat_members') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON chat_members';
    END LOOP;
    
    -- Drop all policies on messages
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'messages') 
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON messages';
    END LOOP;
END $$;

-- PART 3: Drop and recreate helper function
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'is_chat_member'
    ) 
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
END $$;

CREATE OR REPLACE FUNCTION is_chat_member(chat_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM chat_members
    WHERE chat_id = chat_uuid AND user_id = user_uuid
  );
END;
$$;

-- PART 4: Re-enable RLS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- PART 5: Create clean policies

-- ============ CHATS TABLE ============

-- Allow users to create chats
CREATE POLICY "chats_insert_policy" ON chats
  FOR INSERT 
  WITH CHECK (created_by = auth.uid());

-- Allow users to view chats they created OR are members of
CREATE POLICY "chats_select_policy" ON chats
  FOR SELECT 
  USING (
    created_by = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.chat_id = id AND cm.user_id = auth.uid()
    )
  );

-- Allow creators to update their chats
CREATE POLICY "chats_update_policy" ON chats
  FOR UPDATE 
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- ============ CHAT_MEMBERS TABLE ============

-- Allow users to add themselves OR creators to add members to their chats
CREATE POLICY "chat_members_insert_policy" ON chat_members
  FOR INSERT 
  WITH CHECK (
    -- You can always add yourself
    user_id = auth.uid()
    OR
    -- OR you're the creator of the chat adding someone else
    EXISTS (
      SELECT 1 FROM chats
      WHERE id = chat_id 
      AND created_by = auth.uid()
    )
  );

-- Allow users to view members of chats they belong to
CREATE POLICY "chat_members_select_policy" ON chat_members
  FOR SELECT 
  USING (is_chat_member(chat_id, auth.uid()));

-- ============ MESSAGES TABLE ============

-- Allow users to send messages in their chats
CREATE POLICY "messages_insert_policy" ON messages
  FOR INSERT 
  WITH CHECK (
    sender_id = auth.uid() 
    AND is_chat_member(chat_id, auth.uid())
  );

-- Allow users to view messages in their chats
CREATE POLICY "messages_select_policy" ON messages
  FOR SELECT 
  USING (is_chat_member(chat_id, auth.uid()));

-- Allow users to update their own messages
CREATE POLICY "messages_update_policy" ON messages
  FOR UPDATE 
  USING (sender_id = auth.uid())
  WITH CHECK (sender_id = auth.uid());

-- Allow users to delete their own messages
CREATE POLICY "messages_delete_policy" ON messages
  FOR DELETE 
  USING (sender_id = auth.uid());

-- PART 6: Grant permissions
GRANT EXECUTE ON FUNCTION is_chat_member TO authenticated;

-- ========================================
-- VERIFICATION QUERIES - Run these after to verify
-- ========================================

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('chats', 'chat_members', 'messages');

-- Check all policies
-- SELECT tablename, policyname, cmd, qual FROM pg_policies WHERE tablename IN ('chats', 'chat_members', 'messages') ORDER BY tablename, policyname;

-- Check function exists
-- SELECT proname, prosrc FROM pg_proc WHERE proname = 'is_chat_member';
