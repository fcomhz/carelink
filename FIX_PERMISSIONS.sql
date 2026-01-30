-- SOLUCION ERROR: permission denied for schema app_carelink
-- El rol 'service_role' (usado por el servidor para crear usuarios) necesita permisos explícitos sobre el esquema personalizado.

GRANT USAGE ON SCHEMA app_carelink TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA app_carelink TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app_carelink TO service_role;

-- También aseguramos que el rol authenticated pueda leer (ya lo tenía, pero por seguridad)
GRANT USAGE ON SCHEMA app_carelink TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA app_carelink TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app_carelink TO authenticated;
