-- =====================================================
-- DIAGNÓSTICO COMPLETO DE ACCESO
-- Verificar permisos RLS y función get_user_org
-- =====================================================

-- 1. Verificar que la función get_user_org existe y funciona
SELECT app_carelink.get_user_org();

-- 2. Ver políticas RLS activas en profiles
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
WHERE schemaname = 'app_carelink' 
  AND tablename = 'profiles';

-- 3. Verificar si RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'app_carelink' 
  AND tablename = 'profiles';

-- 4. Probar acceso directo a profiles (esto debería funcionar si estás autenticado)
SELECT 
    id,
    email,
    role,
    organization_id
FROM app_carelink.profiles
WHERE id = auth.uid();
