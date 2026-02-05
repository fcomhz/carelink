-- =====================================================
-- FIX INFINITE RECURSION IN PROFILES RLS
-- Ejecutar INMEDIATAMENTE en Supabase SQL Editor
-- =====================================================

-- 1. DROP ALL policies on profiles to start fresh
DROP POLICY IF EXISTS "Users can see profiles from their org" ON app_carelink.profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON app_carelink.profiles;
DROP POLICY IF EXISTS "Admins can see all profiles in org" ON app_carelink.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON app_carelink.profiles;
DROP POLICY IF EXISTS "Allow profile creation" ON app_carelink.profiles;

-- 2. Create SIMPLE policy - each user can only see their OWN profile
-- No subqueries, no recursion
CREATE POLICY "Users can select own profile"
ON app_carelink.profiles
FOR SELECT
USING (id = auth.uid());

-- 3. Allow users to update own profile
CREATE POLICY "Users can update own profile"
ON app_carelink.profiles
FOR UPDATE
USING (id = auth.uid());

-- 4. Allow profile creation during signup
CREATE POLICY "Allow profile insert"
ON app_carelink.profiles
FOR INSERT
WITH CHECK (id = auth.uid());

-- 5. Verify - should show 3 policies
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'app_carelink' AND tablename = 'profiles';
