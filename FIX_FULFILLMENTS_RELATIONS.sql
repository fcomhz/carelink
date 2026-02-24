-- ==============================================================================
-- FIX FULFILLMENTS RELATIONSHIPS
-- ==============================================================================

-- Asegurar que request_id es una clave foránea formal
ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_request_id_fkey;

ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_request_id_fkey 
FOREIGN KEY (request_id) REFERENCES app_carelink.requests(id);

-- Asegurar que collection_center_id es una clave foránea formal
ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_collection_center_id_fkey;

ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_collection_center_id_fkey 
FOREIGN KEY (collection_center_id) REFERENCES app_carelink.collection_centers(id);

-- El de user_id ya lo agregamos pero por si acaso lo reforzamos
ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_user_id_fkey;

ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES app_carelink.profiles(id);
