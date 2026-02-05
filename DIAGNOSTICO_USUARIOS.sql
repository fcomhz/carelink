-- =====================================================
-- DIAGNÓSTICO DE USUARIOS ADMIN
-- Verificar estado de fcomhz@gmail.com y admin@carelink.com
-- =====================================================

-- 1. Ver usuarios en auth.users
SELECT 
    id,
    email,
    confirmed_at,
    created_at
FROM auth.users
WHERE email IN ('fcomhz@gmail.com', 'admin@carelink.com')
ORDER BY email;

-- 2. Ver perfiles en app_carelink.profiles
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.role,
    p.organization_id,
    o.name as organization_name
FROM app_carelink.profiles p
LEFT JOIN app_carelink.organizations o ON p.organization_id = o.id
WHERE p.email IN ('fcomhz@gmail.com', 'admin@carelink.com')
ORDER BY p.email;

-- 3. Ver todas las organizaciones disponibles
SELECT id, name, created_at
FROM app_carelink.organizations
ORDER BY name;
