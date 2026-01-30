-- MODIFICAR TABLA SOLICITUDES (Visibilidad)

alter table app_carelink.requests 
add column if not exists visibility text default 'PUBLICA'; -- Valores: 'PUBLICA', 'PRIVADA'

-- Asegurar valor por defecto
update app_carelink.requests set visibility = 'PUBLICA' where visibility is null;

-- Ajustar políticas para Patrocinadores (Sólo ver PUBLICAS y APROBADAS)
drop policy if exists "Sponsors view approved requests" on app_carelink.requests;

create policy "Sponsors view public approved requests" on app_carelink.requests
  for select using (
    organization_id = app_carelink.get_user_org()
    AND
    status = 'APROBADO'
    AND
    visibility = 'PUBLICA'
    AND
    exists (
      select 1 from app_carelink.profiles 
      where id = auth.uid() and role = 'APORTADOR'
    )
  );
