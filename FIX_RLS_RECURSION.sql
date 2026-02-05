-- =====================================================
-- CORREGIR RECURSIÓN INFINITA EN RLS PROFILES
-- =====================================================

-- 1. Eliminar la política problemática
DROP POLICY IF EXISTS "Users can view profiles in same org" ON app_carelink.profiles;
DROP POLICY IF EXISTS "Users update own or Admin updates org profiles" ON app_carelink.profiles;

-- 2. Crear una función auxiliar para obtener el org_id del usuario actual sin disparar RLS recursivo
-- Usamos 'SECURITY DEFINER' para que se ejecute con permisos de creador (admin) y salte las RLS.
CREATE OR REPLACE FUNCTION app_carelink.get_my_org_id()
RETURNS UUID AS $$
BEGIN
  RETURN (
    SELECT organization_id 
    FROM app_carelink.profiles 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Crear las políticas usando la función segura
-- Política de SELECT: Ver usuarios de mi misma organización
CREATE POLICY "View profiles in same org" 
ON app_carelink.profiles FOR SELECT 
USING (
    organization_id = app_carelink.get_my_org_id()
);

-- Política de UPDATE: Editar mi perfil o si soy ADMIN editar otros de mi org
CREATE POLICY "Update profiles in same org" 
ON app_carelink.profiles FOR UPDATE 
USING (
    id = auth.uid() OR 
    (
        app_carelink.get_my_org_id() = organization_id AND 
        EXISTS (
            SELECT 1 FROM app_carelink.profiles 
            WHERE id = auth.uid() AND role = 'ADMIN'
        )
    )
);

-- Política de INSERT: Cualquiera puede registrarse (o restringir si lo prefieres)
CREATE POLICY "Insert profile" 
ON app_carelink.profiles FOR INSERT 
WITH CHECK (
    id = auth.uid()
);
