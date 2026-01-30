-- ACTUALIZACION DE TABLERO (Prioridad y Estado)

-- 1. Agregar columnas a Anuncios
alter table app_carelink.announcements 
add column if not exists priority text default 'REGULAR', -- Valores: 'URGENTE', 'REGULAR'
add column if not exists status text default 'ACTIVO';   -- Valores: 'ACTIVO', 'INACTIVO'

-- 2. Asegurar que los datos existentes tengan valores por defecto
update app_carelink.announcements 
set priority = 'REGULAR' where priority is null;

update app_carelink.announcements 
set status = 'ACTIVO' where status is null;
