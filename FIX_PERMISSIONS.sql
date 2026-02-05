-- =====================================================
-- CORREGIR PERMISOS Y GRANTS (PERMISSION DENIED FIX)
-- =====================================================

-- 1. Asegurar permisos de uso sobre el esquema app_carelink
GRANT USAGE ON SCHEMA app_carelink TO postgres, anon, authenticated, service_role;

-- 2. Dar permisos totales sobre todas las tablas actuales y futuras
GRANT ALL ON ALL TABLES IN SCHEMA app_carelink TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app_carelink TO postgres, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA app_carelink TO postgres, service_role;

-- 3. Asegurar permisos normales para usuarios autenticados
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app_carelink TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA app_carelink TO authenticated;

-- 4. Ajustar política de INSERT para permitir que Admins creen otros perfiles
-- (Esto sirve de respaldo si la conexión por service_role falla)
DROP POLICY IF EXISTS "Insert profile" ON app_carelink.profiles;

CREATE POLICY "Insert profile" 
ON app_carelink.profiles FOR INSERT 
WITH CHECK (
    -- Permite insertar si es mi propio perfil (registro)
    id = auth.uid() 
    OR 
    -- O si soy un ADMIN de la misma organización
    EXISTS (
        SELECT 1 FROM app_carelink.profiles 
        WHERE id = auth.uid() 
        AND role = 'ADMIN' 
        AND organization_id = app_carelink.get_my_org_id()
    )
    OR
    -- O si soy un usuario de servicio (service_role) - aunque service_role salta RLS, esto no estorba
    (SELECT current_setting('request.jwt.claim.role', true)) = 'service_role'
);
