-- =====================================================
-- FIX FOREIGN KEYS FOR REQUESTS TABLE
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. Ver las foreign keys actuales de requests
SELECT
    tc.table_schema, 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'app_carelink'
  AND tc.table_name = 'requests';

-- 2. Drop existing foreign keys if they exist (to recreate them properly)
ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_requester_id_fkey;

ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_committed_by_fkey;

ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_category_id_fkey;

-- 3. Recreate foreign keys with proper naming
ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_requester_id_fkey 
FOREIGN KEY (requester_id) 
REFERENCES app_carelink.profiles(id) 
ON DELETE SET NULL;

ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_committed_by_fkey 
FOREIGN KEY (committed_by) 
REFERENCES app_carelink.profiles(id) 
ON DELETE SET NULL;

ALTER TABLE app_carelink.requests
ADD CONSTRAINT requests_category_id_fkey 
FOREIGN KEY (category_id) 
REFERENCES app_carelink.categories(id) 
ON DELETE SET NULL;

-- 4. Verify foreign keys were created
SELECT
    tc.constraint_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_schema = 'app_carelink'
  AND tc.table_name = 'requests';
