-- =====================================================
-- CONSULTAR USUARIOS ACTUALES DE CARELINK
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- Ver todos los usuarios de la app CareLink
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.phone,
    p.role,
    p.created_at,
    o.name as organization_name
FROM app_carelink.profiles p
LEFT JOIN app_carelink.organizations o ON p.organization_id = o.id
ORDER BY o.name, p.role, p.created_at;

-- Resumen por rol
SELECT 
    p.role,
    COUNT(*) as total_usuarios,
    o.name as organization_name
FROM app_carelink.profiles p
LEFT JOIN app_carelink.organizations o ON p.organization_id = o.id
GROUP BY p.role, o.name
ORDER BY o.name, p.role;

-- Ver TODAS las organizaciones disponibles
SELECT 
    id,
    name,
    created_at,
    (SELECT COUNT(*) FROM app_carelink.profiles WHERE organization_id = o.id) as total_users
FROM app_carelink.organizations o
ORDER BY created_at;
