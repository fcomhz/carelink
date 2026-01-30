-- REPARACION DE PERMISOS Y RLS
-- Este script otorga permisos explícitos y simplifica las políticas.

BEGIN;

-- 1. Permisos de Esquema
GRANT USAGE ON SCHEMA app_carelink TO authenticated;
GRANT USAGE ON SCHEMA app_carelink TO anon;
GRANT USAGE ON SCHEMA app_carelink TO service_role;

-- 2. Permisos de Tablas
GRANT ALL ON ALL TABLES IN SCHEMA app_carelink TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA app_carelink TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app_carelink TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app_carelink TO service_role;

-- 3. Simplificar Políticas de Requests (Para asegurar que funcione)
DROP POLICY IF EXISTS "Admins/Asistentes view requests" ON app_carelink.requests;
DROP POLICY IF EXISTS "Admins/Asistentes create requests" ON app_carelink.requests;
DROP POLICY IF EXISTS "Users can see requests from their org" ON app_carelink.requests;
DROP POLICY IF EXISTS "Admins manage requests" ON app_carelink.requests;

-- Política de Lectura: Todos en la Org ven todo
CREATE POLICY "Enable select for users in same org" ON app_carelink.requests
  FOR SELECT TO authenticated
  USING (organization_id = app_carelink.get_user_org());

-- Política de Inserción: Todos los autenticados pueden insertar si son de la org
-- (Simplificado para descartar fallos de rol por ahora)
CREATE POLICY "Enable insert for authenticated users" ON app_carelink.requests
  FOR INSERT TO authenticated
  WITH CHECK (organization_id = app_carelink.get_user_org());

-- Política de Actualización: Solo Admins
CREATE POLICY "Enable update for admins" ON app_carelink.requests
  FOR UPDATE TO authenticated
  USING (
    organization_id = app_carelink.get_user_org() 
    AND 
    EXISTS (
      SELECT 1 FROM app_carelink.profiles 
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- 4. Asegurar que la función get_user_org sea accesible
GRANT EXECUTE ON FUNCTION app_carelink.get_user_org() TO authenticated;
GRANT EXECUTE ON FUNCTION app_carelink.get_user_org() TO service_role;

COMMIT;
