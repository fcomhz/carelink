-- ==============================================================================
-- FIX FULFILLMENTS SCHEMA FOR COMMITMENTS
-- ==============================================================================

-- 1. Añadir columnas faltantes solicitadas por el código de la WebApp
ALTER TABLE app_carelink.fulfillments 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES app_carelink.profiles(id);

ALTER TABLE app_carelink.fulfillments 
ADD COLUMN IF NOT EXISTS delivery_date DATE;

-- 2. Asegurar que organization_id tiene RLS correcto
ALTER TABLE app_carelink.fulfillments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own fulfillments" ON app_carelink.fulfillments;
CREATE POLICY "Users manage own fulfillments" 
ON app_carelink.fulfillments FOR ALL 
TO authenticated 
USING (organization_id = app_carelink.get_user_org())
WITH CHECK (organization_id = app_carelink.get_user_org());

-- 3. Grants
GRANT ALL ON TABLE app_carelink.fulfillments TO authenticated;
