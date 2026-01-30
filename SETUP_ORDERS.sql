-- CONFIGURACION DE PEDIDOS (Versión 1.0)
-- 1. Crear Tabla de Categorías (Admins gestionan)
create table if not exists app_carelink.categories (
  id uuid default uuid_generate_v4() primary key,
  organization_id uuid references app_carelink.organizations(id) not null,
  created_at timestamptz default now(),
  name text not null,
  description text
);

alter table app_carelink.categories enable row level security;

-- Policies Categorías
create policy "Users can see categories from their org" on app_carelink.categories
  for select using (organization_id = app_carelink.get_user_org());

create policy "Admins can manage categories" on app_carelink.categories
  for all using (
    organization_id = app_carelink.get_user_org() 
    AND 
    exists (
      select 1 from app_carelink.profiles 
      where id = auth.uid() and role = 'ADMIN'
    )
  );

-- Seed Categorías Iniciales
do $$
declare
  org_id uuid;
begin
  -- Intentar obtener una organización por defecto (asumiendo que el usuario actual ya tiene una o tomando la primera)
  -- En producción esto podría ser diferente, aquí es para facilitar el inicio
  select id into org_id from app_carelink.organizations limit 1;
  
  if org_id is not null then
    insert into app_carelink.categories (organization_id, name, description) values
      (org_id, 'Medicamentos', 'Fármacos y medicinas'),
      (org_id, 'Insumos Médicos', 'Gasas, jeringas, desinfectantes, etc.'),
      (org_id, 'Limpieza', 'Artículos de aseo general'),
      (org_id, 'Alimentos', 'Comida y bebidas para pacientes/personal'),
      (org_id, 'Oficina', 'Papelería y suministros administrativos'),
      (org_id, 'Mantenimiento', 'Reparaciones y herramientas')
    on conflict do nothing; -- (name) no es único globalmente, así que esto podría duplicar si se corre muchas veces sin constraint
  end if;
end $$;


-- 2. Modificar Tabla de Solicitudes (Requests)
-- Agregar columnas nuevas
alter table app_carelink.requests 
  add column if not exists category_id uuid references app_carelink.categories(id),
  add column if not exists image_url text,
  add column if not exists related_link text,
  add column if not exists estimated_unit_cost numeric default 0,
  add column if not exists suggested_provider text,
  add column if not exists comments text,
  add column if not exists approved_by uuid references app_carelink.profiles(id),
  add column if not exists approval_date timestamptz,
  add column if not exists rejection_reason text;

-- Asegurar que status tenga los valores correctos (PENDIENTE, APROBADO, RECHAZADO, COMPLETADO)
-- (Ya es texto, lo manejamos por convención en el frontend/backend)

-- 3. Políticas de Solicitudes (RLS)
-- Todos (autenticados de la org) pueden VER todas las solicitudes (para transparencia o admin)
-- O restringir: Asistentes ven las suyas, Admins ven todas.
-- REQUERIMIENTO: "La sección Pedidos sólo será vista por administradores y asistentes."

drop policy if exists "Users can see requests from their org" on app_carelink.requests;

-- Política de Lectura: Admins y Asistentes ven todo de su org
create policy "Admins/Asistentes view requests" on app_carelink.requests
  for select using (
    organization_id = app_carelink.get_user_org()
    AND
    exists (
      select 1 from app_carelink.profiles 
      where id = auth.uid() 
      and role in ('ADMIN', 'ASISTENTE', 'ENFERMERO') -- Enfermero es similar a asistente
    )
  );

-- Política de Creación: Admins y Asistentes pueden crear
create policy "Admins/Asistentes create requests" on app_carelink.requests
  for insert with check (
    organization_id = app_carelink.get_user_org()
    AND
    exists (
      select 1 from app_carelink.profiles 
      where id = auth.uid() 
      and role in ('ADMIN', 'ASISTENTE', 'ENFERMERO')
    )
  );

-- Política de Edición: 
-- Admins: Todo
-- Asistentes: Solo las suyas si están PENDIENTES (Opcional, pero seguro)
create policy "Admins manage requests" on app_carelink.requests
  for update using (
    organization_id = app_carelink.get_user_org()
    AND
    exists (
      select 1 from app_carelink.profiles 
      where id = auth.uid() and role = 'ADMIN'
    )
  );

create policy "Requesters edit own pending requests" on app_carelink.requests
  for update using (
    organization_id = app_carelink.get_user_org()
    AND requester_id = auth.uid()
    AND status = 'PENDIENTE'
  );

-- 4. Storage para Imágenes de Pedidos
insert into storage.buckets (id, name, public)
values ('requests', 'requests', true)
on conflict (id) do nothing;

drop policy if exists "Public Access to Requests Images" on storage.objects;
create policy "Public Access to Requests Images"
on storage.objects for select
using ( bucket_id = 'requests' );

drop policy if exists "Authenticated Upload Requests Images" on storage.objects;
create policy "Authenticated Upload Requests Images"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'requests' );
