-- FIX RECURSION AND GHOST SESSION ISSUES

BEGIN;

-- 1. Make the helper function SECURITY DEFINER
-- This allows it to read the profile without triggering the exact same RLS check recursively
CREATE OR REPLACE FUNCTION app_carelink.get_user_org() 
RETURNS uuid AS $$
  SELECT organization_id FROM app_carelink.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 2. Add an explicit "View Own Profile" policy that is simple and non-recursive
DROP POLICY IF EXISTS "Users can view own profile" ON app_carelink.profiles;
CREATE POLICY "Users can view own profile" 
ON app_carelink.profiles FOR SELECT 
USING (id = auth.uid());

-- 3. Ensure the general org policy uses the safe function
DROP POLICY IF EXISTS "Users can view profiles in same org" ON app_carelink.profiles;
CREATE POLICY "Users can view profiles in same org" 
ON app_carelink.profiles FOR SELECT 
USING (
    organization_id = app_carelink.get_user_org()
);

COMMIT;
