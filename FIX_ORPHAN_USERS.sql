-- =====================================================
-- ADOPTAR USUARIOS HUÉRFANOS (FIX EMAIL ALREADY REGISTERED)
-- =====================================================

DO $$
DECLARE
    org_id UUID;
    orphan_rec RECORD;
    count_fixed INT := 0;
BEGIN
    -- 1. Obtener ID de la organización GabyMartínez
    SELECT id INTO org_id FROM app_carelink.organizations 
    WHERE name ILIKE '%GabyMartínez%' LIMIT 1;

    IF org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró la organización GabyMartínez';
    END IF;

    -- 2. Recorrer usuarios que están en auth.users pero NO en app_carelink.profiles
    FOR orphan_rec IN 
        SELECT u.id, u.email, u.raw_user_meta_data
        FROM auth.users u
        WHERE NOT EXISTS (
            SELECT 1 FROM app_carelink.profiles p WHERE p.id = u.id
        )
    LOOP
        -- 3. Crear el perfil para el usuario huérfano
        INSERT INTO app_carelink.profiles (
            id,
            organization_id,
            email,
            full_name,
            role,
            created_at
        ) VALUES (
            orphan_rec.id,
            org_id,
            orphan_rec.email,
            COALESCE(orphan_rec.raw_user_meta_data->>'full_name', 'Usuario Recuperado'),
            'ASISTENTE', -- Rol por defecto al recuperar
            NOW()
        );
        
        count_fixed := count_fixed + 1;
        RAISE NOTICE 'Usuario recuperado: %', orphan_rec.email;
    END LOOP;

    RAISE NOTICE 'Total usuarios recuperados: %', count_fixed;
END $$;
