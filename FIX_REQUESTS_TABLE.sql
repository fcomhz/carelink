-- CORRECCIÓN FINAL TABLA REQUESTS

-- 1. Quitar restricción NOT NULL de la columna 'category' antigua (texto)
-- Ya que ahora usamos 'category_id' (relacional)
alter table app_carelink.requests alter column category drop not null;

-- 2. Asegurar que existe la columna visibility
alter table app_carelink.requests add column if not exists visibility text default 'PUBLICA';

-- 3. Asegurar que existe la columna comments (ya debería estar pero por si acaso)
alter table app_carelink.requests add column if not exists comments text;

-- 4. Permisos
grant all on table app_carelink.requests to authenticated;
grant all on table app_carelink.categories to authenticated;
