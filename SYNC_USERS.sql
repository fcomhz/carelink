-- SINCRONIZACION DE USUARIOS HUÉRFANOS
-- Este script busca usuarios que existen en Auth (login) pero no en la tabla de perfiles (Admin UI)
-- y los inserta para que puedas verlos y editarlos.

INSERT INTO app_carelink.profiles (id, email, organization_id, full_name, role)
SELECT 
  au.id, 
  au.email, 
  (SELECT id FROM app_carelink.organizations WHERE name = 'Gaby' LIMIT 1), -- Asigna org por defecto
  COALESCE(au.raw_user_meta_data->>'full_name', 'Usuario Sin Nombre'),
  'ASISTENTE' -- Rol por defecto (seguro)
FROM auth.users au
LEFT JOIN app_carelink.profiles ap ON au.id = ap.id
WHERE ap.id IS NULL; -- Solo los que no tienen perfil

-- Verificación
SELECT count(*) as usuarios_recuperados FROM app_carelink.profiles;
