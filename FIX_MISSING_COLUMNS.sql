-- CORRECCIÓN DEFINITIVA DE LA TABLA SOLICITUDES
-- Agrega las columnas faltantes y luego las relaciones.

BEGIN;

-- 1. Agregar columnas si no existen (category_id es la que falló)
ALTER TABLE app_carelink.requests 
  ADD COLUMN IF NOT EXISTS category_id UUID;

ALTER TABLE app_carelink.requests 
  ADD COLUMN IF NOT EXISTS requester_id UUID;

-- 2. Eliminar constraint viejos (por si acaso)
ALTER TABLE app_carelink.requests DROP CONSTRAINT IF EXISTS requests_category_id_fkey;
ALTER TABLE app_carelink.requests DROP CONSTRAINT IF EXISTS requests_requester_id_fkey;

-- 3. Crear relaciones (Foreign Keys)
ALTER TABLE app_carelink.requests
  ADD CONSTRAINT requests_category_id_fkey 
  FOREIGN KEY (category_id) 
  REFERENCES app_carelink.categories(id);

ALTER TABLE app_carelink.requests
  ADD CONSTRAINT requests_requester_id_fkey 
  FOREIGN KEY (requester_id) 
  REFERENCES app_carelink.profiles(id);

-- 4. Notificar a PostgREST para recargar esquema
NOTIFY pgrst, 'reload schema';

COMMIT;
