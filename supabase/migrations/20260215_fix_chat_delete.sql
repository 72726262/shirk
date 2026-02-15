-- Allow users to leave chats (delete their own membership)
CREATE POLICY "Users can leave chats" ON chat_members
  FOR DELETE USING (user_id = auth.uid());
