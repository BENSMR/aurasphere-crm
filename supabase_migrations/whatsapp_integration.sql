-- Create WhatsApp delivery logs table
CREATE TABLE IF NOT EXISTS whatsapp_delivery_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_id TEXT NOT NULL,
  entity_type TEXT NOT NULL, -- 'invoice', 'payment_reminder', 'job_update', 'custom'
  phone_number TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('sent', 'failed', 'delivered', 'read')),
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  delivered_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_entity_idx UNIQUE(user_id, entity_id, phone_number)
);

-- Create WhatsApp configuration table
CREATE TABLE IF NOT EXISTS whatsapp_config (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  business_phone_id TEXT NOT NULL,
  access_token TEXT NOT NULL, -- Encrypted in production
  webhook_verify_token TEXT NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error')),
  last_test_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create WhatsApp message templates table
CREATE TABLE IF NOT EXISTS whatsapp_templates (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  message TEXT NOT NULL,
  category TEXT DEFAULT 'general', -- 'invoice', 'reminder', 'job_update', 'general'
  variables TEXT[], -- Template variables like {client_name}, {amount}
  archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_template_name UNIQUE(user_id, name)
);

-- Create WhatsApp conversations table
CREATE TABLE IF NOT EXISTS whatsapp_conversations (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  client_phone TEXT NOT NULL,
  last_message_text TEXT,
  last_message_at TIMESTAMP WITH TIME ZONE,
  unread_count INTEGER DEFAULT 0,
  archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT user_client_conv UNIQUE(user_id, client_id)
);

-- Create WhatsApp messages table
CREATE TABLE IF NOT EXISTS whatsapp_messages (
  id BIGSERIAL PRIMARY KEY,
  conversation_id BIGINT REFERENCES whatsapp_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
  message_id TEXT UNIQUE, -- WhatsApp message ID
  message_text TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  status TEXT DEFAULT 'sent' CHECK (status IN ('pending', 'sent', 'delivered', 'read', 'failed')),
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'document', 'audio', 'video')),
  media_url TEXT,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  delivered_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX idx_whatsapp_logs_user ON whatsapp_delivery_logs(user_id, sent_at DESC);
CREATE INDEX idx_whatsapp_logs_entity ON whatsapp_delivery_logs(entity_id, entity_type);
CREATE INDEX idx_whatsapp_config_user ON whatsapp_config(user_id);
CREATE INDEX idx_whatsapp_templates_user ON whatsapp_templates(user_id, archived);
CREATE INDEX idx_whatsapp_conversations_user ON whatsapp_conversations(user_id, last_message_at DESC);
CREATE INDEX idx_whatsapp_messages_conversation ON whatsapp_messages(conversation_id);
CREATE INDEX idx_whatsapp_messages_user ON whatsapp_messages(user_id, created_at DESC);
CREATE INDEX idx_whatsapp_messages_status ON whatsapp_messages(status) WHERE status != 'read';

-- Enable RLS
ALTER TABLE whatsapp_delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE whatsapp_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for whatsapp_delivery_logs
CREATE POLICY "Users can view their own delivery logs"
  ON whatsapp_delivery_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert delivery logs"
  ON whatsapp_delivery_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for whatsapp_config
CREATE POLICY "Users can view their own config"
  ON whatsapp_config FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert their own config"
  ON whatsapp_config FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own config"
  ON whatsapp_config FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for whatsapp_templates
CREATE POLICY "Users can view their own templates"
  ON whatsapp_templates FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create templates"
  ON whatsapp_templates FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own templates"
  ON whatsapp_templates FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own templates"
  ON whatsapp_templates FOR DELETE
  USING (auth.uid() = user_id);

-- RLS Policies for whatsapp_conversations
CREATE POLICY "Users can view their own conversations"
  ON whatsapp_conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create conversations"
  ON whatsapp_conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their conversations"
  ON whatsapp_conversations FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for whatsapp_messages
CREATE POLICY "Users can view their own messages"
  ON whatsapp_messages FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert messages"
  ON whatsapp_messages FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own messages"
  ON whatsapp_messages FOR UPDATE
  USING (auth.uid() = user_id);

-- Trigger to update whatsapp_conversations last_message_at
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE whatsapp_conversations
  SET last_message_text = NEW.message_text,
      last_message_at = NEW.created_at,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_conversation_last_message_trigger ON whatsapp_messages;
CREATE TRIGGER update_conversation_last_message_trigger
AFTER INSERT ON whatsapp_messages
FOR EACH ROW
EXECUTE FUNCTION update_conversation_last_message();

-- Trigger to update whatsapp_config updated_at
CREATE OR REPLACE FUNCTION update_whatsapp_config_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_whatsapp_config_timestamp_trigger ON whatsapp_config;
CREATE TRIGGER update_whatsapp_config_timestamp_trigger
BEFORE UPDATE ON whatsapp_config
FOR EACH ROW
EXECUTE FUNCTION update_whatsapp_config_timestamp();

-- Add comments
COMMENT ON TABLE whatsapp_delivery_logs IS 'Track WhatsApp message delivery status and history';
COMMENT ON TABLE whatsapp_config IS 'Store WhatsApp Business API credentials per user';
COMMENT ON TABLE whatsapp_templates IS 'Pre-defined message templates for quick sending';
COMMENT ON TABLE whatsapp_conversations IS 'Track conversations with clients';
COMMENT ON TABLE whatsapp_messages IS 'Store individual messages (inbound and outbound)';
COMMENT ON COLUMN whatsapp_delivery_logs.status IS 'sent: Successfully sent, failed: Failed to send, delivered: Confirmed delivered, read: Confirmed read';
COMMENT ON COLUMN whatsapp_messages.direction IS 'inbound: From client, outbound: From technician';
