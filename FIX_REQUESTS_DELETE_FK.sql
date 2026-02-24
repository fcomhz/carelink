-- =====================================================
-- FIX FOREIGN KEY FOR REQUESTS DELETION
-- Objetivo: Permitir eliminar pedidos (requests) eliminando en cascada sus compromisos (fulfillments)
-- Ejecutar en Supabase SQL Editor
-- =====================================================

BEGIN;

-- 1. Eliminar la constraint actual que no tiene ON DELETE CASCADE
ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_request_id_fkey;

-- 2. Recrear la constraint con ON DELETE CASCADE
ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_request_id_fkey 
FOREIGN KEY (request_id) 
REFERENCES app_carelink.requests(id) 
ON DELETE CASCADE;

COMMIT;

-- Verificación:
-- SELECT
--     tc.constraint_name, 
--     kcu.column_name, 
--     rc.delete_rule
-- FROM information_schema.table_constraints AS tc 
-- JOIN information_schema.key_column_usage AS kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.referential_constraints AS rc
--   ON rc.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY' 
--   AND tc.table_schema = 'app_carelink'
--   AND tc.table_name = 'fulfillments';
