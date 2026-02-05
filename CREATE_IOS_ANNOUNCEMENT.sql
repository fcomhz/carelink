-- =====================================================
-- CREAR AVISO PERMANENTE PARA USUARIOS IOS
-- Ejecutar en Supabase SQL Editor
-- =====================================================

WITH admin_user AS (
    -- Buscar un usuario admin para asignarlo como autor (usamos el primero que encuentre)
    SELECT id, organization_id 
    FROM app_carelink.profiles 
    WHERE role = 'ADMIN' 
    LIMIT 1
)
INSERT INTO app_carelink.announcements (
    organization_id,
    title,
    body,
    audience_role,
    priority,
    status,
    author_id,
    created_at
)
SELECT 
    organization_id,
    '📱 Activa las notificaciones en tu iPhone',
    'Para recibir alertas de CareLink en iOS (iPhone/iPad), Apple requiere que instales la app en tu pantalla de inicio:

1. Abre esta web en **Safari**.
2. Toca el botón **Compartir** (icono central inferior ⬆️).
3. Selecciona **"Agregar al inicio"** (Add to Home Screen).
4. Abre la nueva app desde tu inicio e inicia sesión.
5. Acepta el permiso de notificaciones cuando aparezca.

Si solo usas el navegador, ¡no recibirás alertas!',
    'TODOS',      -- Visible para todos los roles
    'REGULAR',    -- Prioridad estándar (usa 'URGENTE' si quieres que salga siempre arriba)
    'ACTIVO',
    id,           -- ID del admin encontrado
    NOW()
FROM admin_user;
