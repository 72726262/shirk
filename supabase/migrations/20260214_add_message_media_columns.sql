-- Add missing columns to messages table for media support

-- Add message_type column
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS message_type text DEFAULT 'text' 
CHECK (message_type IN ('text', 'image', 'file', 'audio', 'video'));

-- Add media-related columns
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS media_url text,
ADD COLUMN IF NOT EXISTS media_type text,
ADD COLUMN IF NOT EXISTS file_name text,
ADD COLUMN IF NOT EXISTS file_size bigint;

-- Add is_edited column
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS is_edited boolean DEFAULT false;

-- Create index on message_type for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);

-- Verify columns
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'messages' 
-- ORDER BY ordinal_position;
