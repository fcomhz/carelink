-- ==============================================================================
-- FIX FOR FULFILLMENTS: Add missing columns required by surtir.vue and entradas.vue
-- Corrígelo en la base de datos para solucionar el "Schema cache error" y recargar
-- ==============================================================================

-- 1. Añadir columnas de recepción y entrega a la tabla fulfillments
ALTER TABLE app_carelink.fulfillments 
ADD COLUMN IF NOT EXISTS received_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS received_by UUID REFERENCES app_carelink.profiles(id),
ADD COLUMN IF NOT EXISTS financial_value NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES app_carelink.profiles(id),
ADD COLUMN IF NOT EXISTS delivery_date DATE;

-- 2. Asegurar que las políticas RLS cubran la organización
ALTER TABLE app_carelink.fulfillments ENABLE ROW LEVEL SECURITY;

-- Esta política asegura que todos los elementos de fulfillments son manejables por usuarios de la misma Org.
DROP POLICY IF EXISTS "Users can view fulfillments in org" ON app_carelink.fulfillments;
CREATE POLICY "Users can view fulfillments in org" 
ON app_carelink.fulfillments FOR SELECT 
USING (organization_id = app_carelink.get_user_org());

DROP POLICY IF EXISTS "Users can manage fulfillments" ON app_carelink.fulfillments;
CREATE POLICY "Users can manage fulfillments" 
ON app_carelink.fulfillments FOR ALL 
USING (organization_id = app_carelink.get_user_org());

-- 3. Notificar a Supabase/PostgREST para que recargue el caché de esquemas inmediatamente.
-- ESTO ES CLAVE PARA QUITAR EL ERROR DE "SCHEMA CACHE ERROR".
NOTIFY pgrst, 'reload schema';
