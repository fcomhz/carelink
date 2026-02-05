-- =====================================================
-- PUSH NOTIFICATIONS SCHEMA
-- CareLink PWA Push Subscriptions
-- =====================================================

-- Push Notification Subscriptions Table
CREATE TABLE IF NOT EXISTS app_carelink.push_subscriptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES app_carelink.profiles(id) ON DELETE CASCADE NOT NULL,
  organization_id UUID REFERENCES app_carelink.organizations(id) ON DELETE CASCADE NOT NULL,
  endpoint TEXT NOT NULL UNIQUE,
  keys JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE app_carelink.push_subscriptions IS 'Stores Web Push subscription data for each user device';
COMMENT ON COLUMN app_carelink.push_subscriptions.endpoint IS 'Unique push service endpoint URL';
COMMENT ON COLUMN app_carelink.push_subscriptions.keys IS 'Contains p256dh and auth keys for encryption';

-- Enable RLS
ALTER TABLE app_carelink.push_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view and manage their own subscriptions
CREATE POLICY "Users can view their own subscriptions" 
ON app_carelink.push_subscriptions
FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own subscriptions" 
ON app_carelink.push_subscriptions
FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own subscriptions" 
ON app_carelink.push_subscriptions
FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own subscriptions" 
ON app_carelink.push_subscriptions
FOR DELETE USING (user_id = auth.uid());

-- Admins can view all subscriptions in their org (for sending notifications)
CREATE POLICY "Admins can view org subscriptions" 
ON app_carelink.push_subscriptions
FOR SELECT USING (
  organization_id = app_carelink.get_user_org() 
  AND EXISTS (
    SELECT 1 FROM app_carelink.profiles 
    WHERE id = auth.uid() AND role = 'ADMIN'
  )
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_push_subs_org_id ON app_carelink.push_subscriptions(organization_id);
CREATE INDEX IF NOT EXISTS idx_push_subs_user_id ON app_carelink.push_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_push_subs_endpoint ON app_carelink.push_subscriptions(endpoint);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION app_carelink.update_push_subscription_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_push_subscription_timestamp ON app_carelink.push_subscriptions;
CREATE TRIGGER update_push_subscription_timestamp
  BEFORE UPDATE ON app_carelink.push_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION app_carelink.update_push_subscription_timestamp();
