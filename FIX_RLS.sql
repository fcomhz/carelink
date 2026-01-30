-- SOLUCION ERROR 403 (Permisos y Recursión)

-- 1. Corregir función para evitar recursión infinita (SECURITY DEFINER)
-- Esto permite que la función lea 'profiles' saltándose las políticas RLS restringidas.
create or replace function app_carelink.get_user_org() 
returns uuid 
language sql 
stable 
security definer 
set search_path = public -- Buena práctica
as $$
  select organization_id from app_carelink.profiles where id = auth.uid();
$$;

-- 2. Asegurar permisos en el esquema y tablas nuevas
grant usage on schema app_carelink to postgres, anon, authenticated, service_role;

grant all on table app_carelink.categories to authenticated;
grant all on table app_carelink.announcements to authenticated;
-- (Aseguramos acceso a las tablas recientes)

-- 3. Refrescar políticas de Categorías (por si acaso)
drop policy if exists "Users can see categories from their org" on app_carelink.categories;
drop policy if exists "Admins can manage categories" on app_carelink.categories;

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
