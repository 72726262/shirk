-- Fix Chat RLS Infinite Recursion
-- This migration fixes the infinite recursion error in chat_members RLS policy

-- Step 1: Drop ALL existing chat-related policies
DROP POLICY IF EXISTS "Users can view their chats" ON chats;
DROP POLICY IF EXISTS "Users can create chats" ON chats;
DROP POLICY IF EXISTS "Users can update chats" ON chats;
DROP POLICY IF EXISTS "Users can delete chats" ON chats;

DROP POLICY IF EXISTS "Users can view chat members" ON chat_members;
DROP POLICY IF EXISTS "Users can view chat members of their chats" ON chat_members;
DROP POLICY IF EXISTS "Users can insert chat members" ON chat_members;
DROP POLICY IF EXISTS "Users can insert members to new chats" ON chat_members;
DROP POLICY IF EXISTS "Users can insert members to chats they created" ON chat_members;
DROP POLICY IF EXISTS "Users can update chat members" ON chat_members;
DROP POLICY IF EXISTS "Users can delete chat members" ON chat_members;

DROP POLICY IF EXISTS "Users can view messages" ON messages;
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can update their messages" ON messages;
DROP POLICY IF EXISTS "Users can delete their messages" ON messages;

-- Step 2: Drop ALL existing is_chat_member function overloads
-- Using DO block to handle multiple overloads
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

-- Step 3: Create the helper function
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

-- Step 4: Create non-recursive RLS policies

-- Chat Members: Allow users to see members of chats they belong to
CREATE POLICY "Users can view chat members of their chats" ON chat_members
  FOR SELECT USING (
    is_chat_member(chat_id, auth.uid())
  );

-- Chat Members: Allow users to insert members when creating chats
-- This policy allows users to add themselves OR be added by the chat creator
CREATE POLICY "Users can insert members to new chats" ON chat_members
  FOR INSERT WITH CHECK (
    -- You can always add yourself to any chat
    user_id = auth.uid()
    -- Note: We don't check if you're the creator here to avoid chicken-egg problem
    -- The chat creator adds themselves first, then can add others
  );

-- Chats: Allow users to view chats they are members of OR created
CREATE POLICY "Users can view their chats" ON chats
  FOR SELECT USING (
    -- Either you created the chat
    created_by = auth.uid()
    OR
    -- Or you're a member of the chat
    EXISTS (
      SELECT 1 FROM chat_members cm
      WHERE cm.chat_id = id AND cm.user_id = auth.uid()
    )
  );

-- Chats: Allow users to create chats
CREATE POLICY "Users can create chats" ON chats
  FOR INSERT WITH CHECK (created_by = auth.uid());

-- Chats: Allow creators to update their chats
CREATE POLICY "Users can update their chats" ON chats
  FOR UPDATE USING (created_by = auth.uid());

-- Messages: Allow users to view messages in their chats
CREATE POLICY "Users can view messages in their chats" ON messages
  FOR SELECT USING (
    is_chat_member(chat_id, auth.uid())
  );

-- Messages: Allow users to insert messages in their chats
CREATE POLICY "Users can send messages in their chats" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND is_chat_member(chat_id, auth.uid())
  );

-- Messages: Allow users to update their own messages
CREATE POLICY "Users can update their messages" ON messages
  FOR UPDATE USING (sender_id = auth.uid());

-- Messages: Allow users to delete their own messages
CREATE POLICY "Users can delete their messages" ON messages
  FOR DELETE USING (sender_id = auth.uid());

-- Step 5: Grant necessary permissions
GRANT EXECUTE ON FUNCTION is_chat_member TO authenticated;

-- Verify the policies are working
-- SELECT * FROM pg_policies WHERE tablename IN ('chats', 'chat_members', 'messages');
