-- ============================================
-- Enable Realtime for Chat System (Safe Version)
-- ============================================

-- 1. Ensure tables are in the publication safely
DO $$
BEGIN
  -- Add messages if not present
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'messages') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE messages;
  END IF;

  -- Add chats if not present
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'chats') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE chats;
  END IF;

  -- Add chat_members if not present
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'chat_members') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_members;
  END IF;

  -- Add profiles if not present
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'profiles') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
  END IF;
END $$;

-- 2. Set Replica Identity to FULL to ensure all columns are available in updates/deletes
-- This helps with listener returning full records
ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE chats REPLICA IDENTITY FULL;
ALTER TABLE chat_members REPLICA IDENTITY FULL;
ALTER TABLE profiles REPLICA IDENTITY FULL;

-- 3. Optimization: Add index for message sorting if missing
CREATE INDEX IF NOT EXISTS idx_messages_chat_created_at ON messages(chat_id, created_at);

-- 4. Verify RLS for messages again (ensure policy exists)
-- Just to be safe, we re-assert the select policy for messages
DROP POLICY IF EXISTS "messages_select_policy" ON messages;
CREATE POLICY "messages_select_policy" ON messages
  FOR SELECT 
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_members
      WHERE chat_members.chat_id = messages.chat_id
      AND chat_members.user_id = auth.uid()
    )
  );
