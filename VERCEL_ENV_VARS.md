# Variables de Entorno Requeridas en Vercel

## Supabase (CRÍTICAS)

### 1. SUPABASE_URL
- **Valor:** `https://xxxxxxxxxxxxx.supabase.co`
- **Dónde:** Supabase Dashboard → Project Settings → API

### 2. SUPABASE_ANON_KEY
- **Valor:** La clave pública (anon/public key)
- **Dónde:** Supabase Dashboard → Project Settings → API → anon public

### 3. SUPABASE_SECRET_KEY ⚠️ REQUERIDA PARA ADMIN
- **Valor:** La clave secreta (service_role key)
- **Dónde:** Supabase Dashboard → Project Settings → API → service_role
- **⚠️ CRÍTICA:** Necesaria para crear/editar/eliminar usuarios desde Admin
- **Seguridad:** NUNCA expongas esta clave en el frontend

### 4. SUPABASE_DB_SCHEMA (Recomendado)
- **Valor:** `app_carelink`
- **Propósito:** Forzar el uso del schema correcto

---

## PWA Push Notifications

### 5. NUXT_PUBLIC_VAPID_PUBLIC_KEY
- **Generar con:** `npx web-push generate-vapid-keys`

### 6. NUXT_VAPID_PRIVATE_KEY
- **Generar con:** `npx web-push generate-vapid-keys`

### 7. NUXT_VAPID_EMAIL
- **Valor:** Email de contacto (ej: `admin@carelink.com`)

---

## Configuración en Vercel

1. Ve a: **Vercel Dashboard → Tu Proyecto → Settings → Environment Variables**
2. Agrega cada variable
3. Aplica a: **Production, Preview, Development**
4. **Redeploy** para aplicar cambios

---

## Solución al Error Actual

Si ves: `Missing server key. Set either SUPABASE_SECRET_KEY...`

**Acción inmediata:**
1. Ve a Supabase Dashboard
2. Project Settings → API
3. Copia el valor de **service_role** (secret)
4. Agrégalo en Vercel como `SUPABASE_SECRET_KEY`
5. Redeploy
