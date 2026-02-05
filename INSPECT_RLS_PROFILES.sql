-- =====================================================
-- INSPECCIONAR RLS POLICIES EN PROFILES
-- =====================================================

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'app_carelink' AND tablename = 'profiles';
