-- =====================================================
-- ADD MISSING TABLES TO app_carelink
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- PROFILES (Extends Auth, linked to Organization)
CREATE TABLE IF NOT EXISTS app_carelink.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
  organization_id UUID REFERENCES app_carelink.organizations(id) NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  role app_carelink.app_role DEFAULT 'ASISTENTE',
  permissions JSONB DEFAULT '[]'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RELATED LINKS (Enlaces de Interés en Dashboard)
CREATE TABLE IF NOT EXISTS app_carelink.related_links (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id UUID REFERENCES app_carelink.organizations(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  title TEXT NOT NULL,
  url TEXT NOT NULL
);

-- Enable RLS
ALTER TABLE app_carelink.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_carelink.related_links ENABLE ROW LEVEL SECURITY;

-- RLS Policies for PROFILES
CREATE POLICY "Users can see profiles from their org" ON app_carelink.profiles
  FOR SELECT USING (organization_id = app_carelink.get_user_org());

-- RLS Policies for RELATED LINKS
CREATE POLICY "Users can see related links from their org" ON app_carelink.related_links
  FOR SELECT USING (organization_id = app_carelink.get_user_org());

CREATE POLICY "Admins can manage related links" ON app_carelink.related_links
  FOR ALL USING (
    organization_id = app_carelink.get_user_org() 
    AND 
    EXISTS (
      SELECT 1 FROM app_carelink.profiles 
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );
