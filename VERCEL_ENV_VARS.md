# Variables de Entorno Requeridas en Vercel

## Supabase
- `SUPABASE_URL` = tu_url_de_supabase
- `SUPABASE_ANON_KEY` = tu_anon_key (o `SUPABASE_KEY`)

## IMPORTANTE: Schema Configuration
El módulo @nuxtjs/supabase NO respeta la configuración `db.schema` en producción.

### Solución:
Agregar esta variable en Vercel:
- `SUPABASE_DB_SCHEMA` = `app_carelink`

O alternativamente, usar el header personalizado:
- Agregar header `X-Supabase-Schema: app_carelink` en las requests

## PWA Push Notifications
- `NUXT_PUBLIC_VAPID_PUBLIC_KEY` = (ya configurado)
- `NUXT_VAPID_PRIVATE_KEY` = (ya configurado)
- `NUXT_VAPID_EMAIL` = (ya configurado)
