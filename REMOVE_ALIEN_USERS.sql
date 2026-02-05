-- =====================================================
-- LIMPIAR USUARIOS AJENOS DE LA ORGANIZACIÓN GABYMARTINEZ
-- =====================================================

-- 1. Eliminar de 'profiles' a los usuarios que no deberían estar en esta app
DELETE FROM app_carelink.profiles
WHERE email IN (
    'talina@solu360.net',
    'cliente@opmobility.com'
    -- Agrega otros correos aquí si detectas más intrusos
) AND organization_id IN (
    SELECT id FROM app_carelink.organizations WHERE name ILIKE '%GabyMartínez%'
);

-- NOTA: Esto solo borra su perfil en CareLink.
-- Su cuenta de login (auth.users) sigue existiendo, por lo que podrán
-- seguir entrando a OPMobility/Solu360 si usan la misma instancia de Supabase.
