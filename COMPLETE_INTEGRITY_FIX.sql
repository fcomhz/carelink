-- =====================================================
-- COMPLETE INTEGRITY FIX FOR CARELINK (FIXED)
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- ============================================
-- PART 1: ENSURE ALL REQUIRED COLUMNS EXIST
-- ============================================

-- Requests table - add missing columns if they don't exist
ALTER TABLE app_carelink.requests 
ADD COLUMN IF NOT EXISTS category_id UUID,
ADD COLUMN IF NOT EXISTS estimated_unit_cost NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS suggested_provider TEXT,
ADD COLUMN IF NOT EXISTS related_link TEXT,
ADD COLUMN IF NOT EXISTS comments TEXT,
ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'PUBLICA',
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS approved_by UUID,
ADD COLUMN IF NOT EXISTS approval_date TIMESTAMPTZ;

-- Announcements table - add missing columns
ALTER TABLE app_carelink.announcements 
ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'REGULAR',
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'ACTIVO',
ADD COLUMN IF NOT EXISTS related_links JSONB DEFAULT '[]'::jsonb;

-- ============================================
-- PART 2: CREATE MISSING TABLES
-- ============================================

-- Fulfillments table (for surtir.vue and entradas.vue)
CREATE TABLE IF NOT EXISTS app_carelink.fulfillments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id UUID REFERENCES app_carelink.organizations(id) NOT NULL,
  request_id UUID,
  donor_name TEXT,
  donor_contact TEXT,
  quantity INTEGER DEFAULT 1,
  unit_cost NUMERIC DEFAULT 0,
  collection_center_id UUID,
  status TEXT DEFAULT 'COMPROMETIDO',
  fulfilled_at TIMESTAMPTZ,
  fulfilled_by UUID,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_carelink.fulfillments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view fulfillments in org" ON app_carelink.fulfillments;
CREATE POLICY "Users can view fulfillments in org" 
ON app_carelink.fulfillments FOR SELECT 
USING (organization_id = (SELECT organization_id FROM app_carelink.profiles WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Users can manage fulfillments" ON app_carelink.fulfillments;
CREATE POLICY "Users can manage fulfillments" 
ON app_carelink.fulfillments FOR ALL 
USING (organization_id = (SELECT organization_id FROM app_carelink.profiles WHERE id = auth.uid()));

-- ============================================
-- PART 3: FIX FOREIGN KEYS
-- ============================================

-- Drop and recreate foreign keys for requests
ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_requester_id_fkey;
ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_committed_by_fkey;
ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_category_id_fkey;
ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_approved_by_fkey;

ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_requester_id_fkey 
FOREIGN KEY (requester_id) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_committed_by_fkey 
FOREIGN KEY (committed_by) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_category_id_fkey 
FOREIGN KEY (category_id) REFERENCES app_carelink.categories(id) ON DELETE SET NULL;

ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_approved_by_fkey 
FOREIGN KEY (approved_by) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

-- Foreign keys for fulfillments
ALTER TABLE app_carelink.fulfillments
DROP CONSTRAINT IF EXISTS fulfillments_request_id_fkey;
ALTER TABLE app_carelink.fulfillments
DROP CONSTRAINT IF EXISTS fulfillments_collection_center_id_fkey;
ALTER TABLE app_carelink.fulfillments
DROP CONSTRAINT IF EXISTS fulfillments_fulfilled_by_fkey;

ALTER TABLE app_carelink.fulfillments
ADD CONSTRAINT fulfillments_request_id_fkey 
FOREIGN KEY (request_id) REFERENCES app_carelink.requests(id) ON DELETE CASCADE;

ALTER TABLE app_carelink.fulfillments
ADD CONSTRAINT fulfillments_collection_center_id_fkey 
FOREIGN KEY (collection_center_id) REFERENCES app_carelink.collection_centers(id) ON DELETE SET NULL;

ALTER TABLE app_carelink.fulfillments
ADD CONSTRAINT fulfillments_fulfilled_by_fkey 
FOREIGN KEY (fulfilled_by) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

-- Foreign keys for incidents
ALTER TABLE app_carelink.incidents
DROP CONSTRAINT IF EXISTS incidents_creator_id_fkey;

ALTER TABLE app_carelink.incidents
ADD CONSTRAINT incidents_creator_id_fkey 
FOREIGN KEY (creator_id) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

-- Foreign keys for incident_messages
ALTER TABLE app_carelink.incident_messages
DROP CONSTRAINT IF EXISTS incident_messages_sender_id_fkey;

ALTER TABLE app_carelink.incident_messages
ADD CONSTRAINT incident_messages_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

-- Foreign keys for finance_records
ALTER TABLE app_carelink.finance_records
DROP CONSTRAINT IF EXISTS finance_records_recorded_by_fkey;

ALTER TABLE app_carelink.finance_records
ADD CONSTRAINT finance_records_recorded_by_fkey 
FOREIGN KEY (recorded_by) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

-- Foreign keys for announcements
ALTER TABLE app_carelink.announcements
DROP CONSTRAINT IF EXISTS announcements_author_id_fkey;

ALTER TABLE app_carelink.announcements
ADD CONSTRAINT announcements_author_id_fkey 
FOREIGN KEY (author_id) REFERENCES app_carelink.profiles(id) ON DELETE SET NULL;

-- Foreign keys for inventory_transactions
ALTER TABLE app_carelink.inventory_transactions
DROP CONSTRAINT IF EXISTS inventory_transactions_item_id_fkey;

ALTER TABLE app_carelink.inventory_transactions
ADD CONSTRAINT inventory_transactions_item_id_fkey 
FOREIGN KEY (item_id) REFERENCES app_carelink.inventory_items(id) ON DELETE CASCADE;

-- ============================================
-- PART 4: GRANT PERMISSIONS
-- ============================================

GRANT USAGE ON SCHEMA app_carelink TO authenticated;
GRANT USAGE ON SCHEMA app_carelink TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA app_carelink TO authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app_carelink TO authenticated;
