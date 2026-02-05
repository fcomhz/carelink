-- =====================================================
-- DIAGNÓSTICO COMPLETO DE USUARIOS
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. Ver usuarios en auth.users (tabla de autenticación de Supabase)
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at,
    raw_user_meta_data->>'full_name' as full_name_metadata,
    raw_user_meta_data->>'role' as role_metadata
FROM auth.users
ORDER BY created_at;

-- 2. Ver usuarios en app_carelink.profiles
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.organization_id,
    o.name as organization_name,
    p.created_at
FROM app_carelink.profiles p
LEFT JOIN app_carelink.organizations o ON p.organization_id = o.id
ORDER BY p.created_at;

-- 3. Encontrar usuarios huérfanos (en auth pero no en profiles)
SELECT 
    u.id,
    u.email,
    u.created_at,
    'Usuario existe en Auth pero NO en Profiles' as status
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM app_carelink.profiles p WHERE p.id = u.id
)
ORDER BY u.created_at;

-- 4. Encontrar perfiles huérfanos (en profiles pero no en auth)
SELECT 
    p.id,
    p.email,
    p.full_name,
    'Perfil existe pero NO en Auth' as status
FROM app_carelink.profiles p
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = p.id
)
ORDER BY p.created_at;
