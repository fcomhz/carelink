-- =====================================================
-- FIX PERMISSIONS FOR PROFILES TABLE
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. GRANT access to authenticated users on the schema
GRANT USAGE ON SCHEMA app_carelink TO authenticated;
GRANT USAGE ON SCHEMA app_carelink TO anon;

-- 2. GRANT SELECT on all tables in the schema
GRANT SELECT ON ALL TABLES IN SCHEMA app_carelink TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA app_carelink TO anon;

-- 3. GRANT INSERT, UPDATE, DELETE on specific tables
GRANT INSERT, UPDATE, DELETE ON app_carelink.profiles TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.requests TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.announcements TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.incidents TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.incident_messages TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.finance_records TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.related_links TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.categories TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.collection_centers TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.bank_accounts TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.inventory_items TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.inventory_transactions TO authenticated;
GRANT INSERT, UPDATE, DELETE ON app_carelink.push_subscriptions TO authenticated;

-- 4. Drop problematic RLS policy for profiles and create better one
DROP POLICY IF EXISTS "Users can see profiles from their org" ON app_carelink.profiles;

-- 5. Create policy that allows users to read their OWN profile first (no circular dependency)
CREATE POLICY "Users can read own profile"
ON app_carelink.profiles
FOR SELECT
USING (id = auth.uid());

-- 6. Create policy for admins to see all profiles in their org
CREATE POLICY "Admins can see all profiles in org"
ON app_carelink.profiles
FOR SELECT
USING (
  organization_id IN (
    SELECT organization_id FROM app_carelink.profiles WHERE id = auth.uid()
  )
);

-- 7. Allow users to update their own profile
CREATE POLICY "Users can update own profile"
ON app_carelink.profiles
FOR UPDATE
USING (id = auth.uid());

-- 8. Allow inserts (for new user registration)
CREATE POLICY "Allow profile creation"
ON app_carelink.profiles
FOR INSERT
WITH CHECK (id = auth.uid());

-- 9. Verify policies were created
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'app_carelink' AND tablename = 'profiles';
