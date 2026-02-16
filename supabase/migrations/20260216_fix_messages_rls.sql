-- Enable RLS on messages table
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any to avoid conflicts
DROP POLICY IF EXISTS "Users can view messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages in their chats" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages in their chats" ON public.messages;

-- Policy: Users can view messages in chats they are members of
CREATE POLICY "Users can view messages in their chats" ON public.messages
FOR SELECT USING (
  auth.uid() IN (
    SELECT user_id FROM public.chat_members WHERE chat_id = messages.chat_id
  )
);

-- Policy: Users can insert messages in chats they are members of
CREATE POLICY "Users can insert messages in their chats" ON public.messages
FOR INSERT WITH CHECK (
  auth.uid() IN (
    SELECT user_id FROM public.chat_members WHERE chat_id = messages.chat_id
  )
);

-- Policy: Users can update messages (e.g., mark as read) in chats they are members of
CREATE POLICY "Users can update messages in their chats" ON public.messages
FOR UPDATE USING (
  auth.uid() IN (
    SELECT user_id FROM public.chat_members WHERE chat_id = messages.chat_id
  )
);
