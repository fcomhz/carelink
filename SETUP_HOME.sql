-- CONFIGURACION DE INICIO (DASHBOARD) - VERSION 2.0 (Enlaces en Posts)

-- 1. Modificar tabla de Anuncios para soportar Enlaces
-- Usamos JSONB para guardar arrays de links: [{ "title": "Google", "url": "..." }, ...]
alter table app_carelink.announcements 
add column if not exists related_links jsonb default '[]'::jsonb;

-- 2. Eliminar la tabla global de enlaces (Ya no se usa)
drop table if exists app_carelink.related_links;

-- 3. Configuración de STORAGE (Imágenes de Posts) - Se mantiene igual
insert into storage.buckets (id, name, public)
values ('posts', 'posts', true)
on conflict (id) do nothing;

-- 4. Políticas de Storage
drop policy if exists "Public Access to Posts Images" on storage.objects;
create policy "Public Access to Posts Images"
on storage.objects for select
using ( bucket_id = 'posts' );

drop policy if exists "Authenticated Users can upload Post Images" on storage.objects;
create policy "Authenticated Users can upload Post Images"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'posts' );
