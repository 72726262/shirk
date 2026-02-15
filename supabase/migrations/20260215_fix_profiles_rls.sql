-- ============================================
-- Fix Profiles RLS for Chat
-- Allow clients to see admin profiles to start chats
-- ============================================

-- Drop filtering policy if it conflicts (though we are adding a new OR condition via new policy)
-- Policies are OR'd together, so adding a new one extends access.

DROP POLICY IF EXISTS "Users can view admin profiles" ON profiles;

CREATE POLICY "Users can view admin profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (role IN ('admin', 'super_admin'));

-- Also ensure users can see profiles of people they are in a chat with
-- (This is important for the ChatList to show the other user's name/avatar)
DROP POLICY IF EXISTS "Users can view chat partner profiles" ON profiles;

CREATE POLICY "Users can view chat partner profiles"
  ON profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM chat_members cm1
      JOIN chat_members cm2 ON cm1.chat_id = cm2.chat_id
      WHERE cm1.user_id = auth.uid() -- Current user is in the chat
      AND cm2.user_id = profiles.id -- The profile being queried is also in the same chat
    )
  );
