-- =====================================================
-- LIMPIAR USUARIO FALLIDO RECIENTE
-- Solo borra usuarios creados HOY que no tienen perfil
-- =====================================================

DELETE FROM auth.users
WHERE id IN (
    SELECT u.id
    FROM auth.users u
    WHERE 
        -- Creado en las últimas 24 horas
        u.created_at > NOW() - INTERVAL '1 day'
        -- Y que NO tenga perfil en ninguna tabla conocida (para seguridad)
        AND NOT EXISTS (SELECT 1 FROM app_carelink.profiles p WHERE p.id = u.id)
        -- Ajusta esto si manejas otros schemas en la misma BD
);
