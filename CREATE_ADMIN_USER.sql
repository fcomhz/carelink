-- =====================================================
-- CREAR USUARIO ADMIN PARA CARELINK
-- Email: admin@carelink.com
-- Password: 123456
-- =====================================================

DO $$
DECLARE
    new_user_id UUID;
    target_org_id UUID;
BEGIN
    -- 1. Crear usuario en auth.users
    -- Nota: Supabase requiere usar la API REST para crear usuarios con contraseña
    -- Este script asume que el usuario YA FUE CREADO desde el dashboard
    
    -- Alternativa: Si tienes acceso directo, usa esta query para encontrar el user_id
    SELECT id INTO new_user_id 
    FROM auth.users 
    WHERE email = 'admin@carelink.com';
    
    -- Si el usuario NO existe, debes crearlo desde:
    -- Dashboard de Supabase → Authentication → Users → Add User
    -- Email: admin@carelink.com
    -- Password: 123456
    -- Auto Confirm User: ✅
    
    IF new_user_id IS NULL THEN
        RAISE EXCEPTION 'Usuario admin@carelink.com no encontrado. Por favor créalo primero desde el Dashboard de Supabase.';
    END IF;
    
    -- 2. Obtener organization_id de GabyMartínez
    SELECT id INTO target_org_id 
    FROM app_carelink.organizations 
    WHERE name = 'GabyMartínez';
    
    IF target_org_id IS NULL THEN
        RAISE EXCEPTION 'Organización GabyMartínez no encontrada.';
    END IF;
    
    -- 3. Crear perfil en app_carelink.profiles con rol ADMIN
    INSERT INTO app_carelink.profiles (
        id,
        organization_id,
        email,
        full_name,
        role,
        permissions
    )
    VALUES (
        new_user_id,
        target_org_id,
        'admin@carelink.com',
        'Administrador CareLink',
        'ADMIN',
        '["ALL"]'::jsonb
    )
    ON CONFLICT (id) DO UPDATE SET
        organization_id = EXCLUDED.organization_id,
        role = 'ADMIN',
        permissions = '["ALL"]'::jsonb;
    
    RAISE NOTICE 'Usuario admin@carelink.com configurado exitosamente con rol ADMIN';
    
END $$;
