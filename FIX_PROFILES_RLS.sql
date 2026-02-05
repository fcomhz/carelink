-- =====================================================
-- CORREGIR RLS POLICIES EN PROFILES
-- Permitir visibilidad dentro de la misma organización
-- =====================================================

-- 1. Eliminar la política restrictiva actual
DROP POLICY IF EXISTS "Users can select own profile" ON app_carelink.profiles;

-- 2. Crear nueva política: Ver perfiles de la misma organización
-- Esta política permite ver cualquier perfil que tenga el mismo organization_id que el usuario actual
CREATE POLICY "Users can view profiles in same org" 
ON app_carelink.profiles FOR SELECT 
USING (
    organization_id IN (
        SELECT organization_id 
        FROM app_carelink.profiles 
        WHERE id = auth.uid()
    )
);

-- 3. (Opcional pero recomendado) Permitir a los ADMIN actualizar cualquier perfil de su organización
DROP POLICY IF EXISTS "Users can update own profile" ON app_carelink.profiles;

CREATE POLICY "Users update own or Admin updates org profiles" 
ON app_carelink.profiles FOR UPDATE 
USING (
    id = auth.uid() OR 
    EXISTS (
        SELECT 1 FROM app_carelink.profiles 
        WHERE id = auth.uid() AND role = 'ADMIN' AND organization_id = profiles.organization_id
    )
);
