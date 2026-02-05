-- =====================================================
-- FIX FOREIGN KEYS - EJECUTAR SOLO ESTA PARTE
-- =====================================================

-- Drop existing foreign keys if they exist
ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_requester_id_fkey;

ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_committed_by_fkey;

ALTER TABLE app_carelink.requests 
DROP CONSTRAINT IF EXISTS requests_category_id_fkey;

-- Recreate foreign keys with proper naming
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
