-- EXPLICIT REPAIR OF FOREIGN KEYS
-- The PostgREST error says "Could not find a relationship", so we will drop and recreate them with explicit names.

BEGIN;

-- 1. Remove potentially broken or auto-named constraints
ALTER TABLE app_carelink.requests DROP CONSTRAINT IF EXISTS requests_category_id_fkey;
ALTER TABLE app_carelink.requests DROP CONSTRAINT IF EXISTS requests_requester_id_fkey;

-- 2. Add Category Constraint
ALTER TABLE app_carelink.requests
  ADD CONSTRAINT requests_category_id_fkey 
  FOREIGN KEY (category_id) 
  REFERENCES app_carelink.categories(id);

-- 3. Add Requester Constraint
ALTER TABLE app_carelink.requests
  ADD CONSTRAINT requests_requester_id_fkey 
  FOREIGN KEY (requester_id) 
  REFERENCES app_carelink.profiles(id);

-- 4. Reload Schema Cache (Often this command helps notify PostgREST)
NOTIFY pgrst, 'reload schema';

COMMIT;

-- Verify columns exist properly just in case
ALTER TABLE app_carelink.requests 
  ALTER COLUMN category_id TYPE uuid USING category_id::uuid,
  ALTER COLUMN requester_id TYPE uuid USING requester_id::uuid;
