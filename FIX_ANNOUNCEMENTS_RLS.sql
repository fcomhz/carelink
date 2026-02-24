-- =====================================================
-- FIX RLS FOR ANNOUNCEMENTS TABLE
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. Habilitar RLS (por si acaso no está)
ALTER TABLE app_carelink.announcements ENABLE ROW LEVEL SECURITY;

-- 2. Limpiar políticas existentes
DROP POLICY IF EXISTS "Public announcements are viewable by everyone" ON app_carelink.announcements;
DROP POLICY IF EXISTS "Users can view announcements from their org" ON app_carelink.announcements;
DROP POLICY IF EXISTS "Admins can manage announcements" ON app_carelink.announcements;

-- 3. Crear políticas robustas

-- SELECT: Todos los usuarios autenticados pueden ver anuncios de su organización
CREATE POLICY "Users can view announcements from their org" 
ON app_carelink.announcements FOR SELECT 
TO authenticated
USING (organization_id = app_carelink.get_user_org());

-- ALL: Solo los administradores pueden crear/editar/borrar anuncios de su organización
CREATE POLICY "Admins can manage announcements" 
ON app_carelink.announcements FOR ALL 
TO authenticated
USING (
  organization_id = app_carelink.get_user_org() 
  AND 
  EXISTS (
    SELECT 1 FROM app_carelink.profiles 
    WHERE id = auth.uid() AND role = 'ADMIN'
  )
)
WITH CHECK (
  organization_id = app_carelink.get_user_org() 
  AND 
  EXISTS (
    SELECT 1 FROM app_carelink.profiles 
    WHERE id = auth.uid() AND role = 'ADMIN'
  )
);

-- 4. Asegurar permisos de acceso (Grant)
GRANT ALL ON TABLE app_carelink.announcements TO authenticated;
GRANT ALL ON TABLE app_carelink.announcements TO service_role;
