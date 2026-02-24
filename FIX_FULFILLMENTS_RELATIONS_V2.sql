-- ==============================================================================
-- FIX FULFILLMENTS RELATIONSHIPS (VERSION 2 - ROBUST)
-- ==============================================================================

-- 1. Asegurar que las columnas ID sean únicas (necesario para ser referenciadas)
-- Postgres exige que la columna referenciada tenga un índice UNIQUE o sea PK.
ALTER TABLE app_carelink.requests ADD CONSTRAINT requests_id_unique UNIQUE (id);
ALTER TABLE app_carelink.collection_centers ADD CONSTRAINT collection_centers_id_unique UNIQUE (id);
ALTER TABLE app_carelink.profiles ADD CONSTRAINT profiles_id_unique UNIQUE (id);

-- 2. Ahora sí, crear las relaciones
ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_request_id_fkey;

ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_request_id_fkey 
FOREIGN KEY (request_id) REFERENCES app_carelink.requests(id);

ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_collection_center_id_fkey;

ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_collection_center_id_fkey 
FOREIGN KEY (collection_center_id) REFERENCES app_carelink.collection_centers(id);

ALTER TABLE app_carelink.fulfillments 
DROP CONSTRAINT IF EXISTS fulfillments_user_id_fkey;

ALTER TABLE app_carelink.fulfillments 
ADD CONSTRAINT fulfillments_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES app_carelink.profiles(id);
