-- REPARACION INTEGRAL DE TABLA REQUESTS
-- Este script asegura que TODAS las columnas necesarias existan.

BEGIN;

-- 1. Asegurar esquema y extensiones
CREATE SCHEMA IF NOT EXISTS app_carelink;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Asegurar tabla de categorías (para la relación)
CREATE TABLE IF NOT EXISTS app_carelink.categories (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) NOT NULL,
  created_at timestamptz DEFAULT now(),
  name text NOT NULL,
  description text
);

-- 3. Agregar TODAS las columnas faltantes a requests
ALTER TABLE app_carelink.requests 
  ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES app_carelink.categories(id),
  ADD COLUMN IF NOT EXISTS image_url TEXT,
  ADD COLUMN IF NOT EXISTS related_link TEXT,
  ADD COLUMN IF NOT EXISTS estimated_unit_cost NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS suggested_provider TEXT,
  ADD COLUMN IF NOT EXISTS comments TEXT,
  ADD COLUMN IF NOT EXISTS visibility TEXT DEFAULT 'PUBLICA',
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES app_carelink.profiles(id),
  ADD COLUMN IF NOT EXISTS approval_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 4. Hacer que la antigua columna 'category' (texto) sea opcional
ALTER TABLE app_carelink.requests ALTER COLUMN category DROP NOT NULL;

-- 5. Asegurar permisos
GRANT USAGE ON SCHEMA app_carelink TO authenticated;
GRANT ALL ON TABLE app_carelink.requests TO authenticated;
GRANT ALL ON TABLE app_carelink.categories TO authenticated;
GRANT ALL ON TABLE app_carelink.profiles TO authenticated;

-- 6. Forzar recarga de PostgREST
NOTIFY pgrst, 'reload schema';

COMMIT;
