-- Drop existing function first to avoid parameter name conflict
DROP FUNCTION IF EXISTS get_private_chat_id(uuid, uuid);

-- Function to get private chat ID between two users
CREATE OR REPLACE FUNCTION get_private_chat_id(user_a UUID, user_b UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  chat_uuid UUID;
BEGIN
  SELECT c.id INTO chat_uuid
  FROM chats c
  JOIN chat_members cm1 ON c.id = cm1.chat_id
  JOIN chat_members cm2 ON c.id = cm2.chat_id
  WHERE c.chat_type = 'private'
  AND cm1.user_id = user_a
  AND cm2.user_id = user_b;
  
  RETURN chat_uuid;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_private_chat_id TO authenticated;
