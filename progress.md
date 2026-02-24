# Progreso del Proyecto CareLink

## 🟢 Sesión: Interactividad, Inventario Físico y Logística Admin (24 Feb 2026)

### 1. 🛠️ Interactividad y UX (Bootstrap Fix)
- **Plugin de Bootstrap JS**: Se integró `bootstrap.client.ts` para habilitar la lógica nativa de Bootstrap 5 en Nuxt. Esto resolvió que los menús de tres puntos (dropdowns) y modales no respondieran al clic.
- **Corrección de Errores Críticos**: Reparados los botones de eliminación en **Inicio**, **Pedidos** y **Surtir** que estaban inoperantes por falta de interactividad/permisos.

### 2. 📦 Gestión de Inventario y Almacén
- **Donación Directa**: Nuevo botón en `/entradas` para registrar ingresos de insumos que no vienen de una solicitud previa. Integra automáticamente inventario y valor financiero.
- **Inventario Físico (Auditoría)**: Nueva funcionalidad en `/almacen` para realizar conteos físicos. El sistema calcula la diferencia contra el stock digital y genera ajustes automáticos.

### 3. 🤝 Logística de Surtido (Admin)
- **Historial de Entregas**: Nueva pestaña **"Historial (Admin)"** en `/surtir` para consultar todas las donaciones ya recibidas (quién entregó, qué, cuánto y quién recibió).
- **Plantillas de WhatsApp**: Menú desplegable con 3 mensajes predefinidos (Amable, Urgente, Directo) para agilizar el seguimiento de compromisos pendientes.
- **Integridad de Borrado**: Corregida restricción de base de datos (`ON DELETE CASCADE`) que impedía borrar solicitudes con compromisos asociados.

### 4. 🚀 Despliegue y Verificación
- **Localhost 100%**: Verificación completa de flujo de administrador en entorno local.
- **Vercel Sync**: Sincronización exitosa de todos los cambios con el entorno de producción en Vercel.

---

## 🟢 Sesión: Surtir, Notificaciones y Avisos (20 Feb 2026 - Tarde)

### 1. 📦 Módulo Surtir (Transparencia)
- **Detalle de Necesidad**: Las tarjetas de compromisos (tanto en vista usuario como admin) ahora muestran el **Proveedor Sugerido** y los **Comentarios** de la solicitud original.
- **Contexto**: Facilita a los donantes saber exactamente qué comprar y dónde, sin tener que navegar hacia atrás.

### 2. 📢 Gestión de Tablero (Avisos)
- **Control Total**: Implementada la capacidad de **Editar** avisos existentes.
- **Ciclo de Vida**: Añadido selector de estado **Activo / Inactivo** para ocultar avisos sin borrarlos.
- **Limpieza**: Opción de eliminación funcional con confirmación.

### 3. 🔔 Notificaciones Inteligentes
- **Automatización**: Al publicar un nuevo aviso activo, el sistema dispara automáticamente una **Notificación Push** a todos los usuarios de la organización.
- **Estabilidad**: Corregido bug que impedía el registro de nuevas suscripciones en dispositivos móviles.

---

## 🟢 Sesión: Unificación de Proyectos y Estabilización (20 Feb 2026)

### 1. 🚀 Unificación de Vercel
- **Migración Exitosa**: Se consolidó la versión final de la WebApp en el proyecto `carelink` ([gabymartinez.vercel.app](https://gabymartinez.vercel.app)).
- **Limpieza de Infraestructura**: El proyecto redundante `carelink-web` fue eliminado para evitar confusiones de versiones.
- **Sincronización Git**: Repositorio local y remoto (GitHub) alineados en el commit `a22b28f`.

### 2. 🛠️ Estabilización Local (Localhost)
- **Reparación de Acceso**: Resuelto problema de login en `localhost:3000`.
- **Limpieza Técnica**: Purga de caché de Nuxt (`.nuxt`, `.output`) y corrección de variables de entorno en `.env`.

### 3. 🔔 Notificaciones Push (VAPID & DB Fix)
- **Restauración de Servicio**: Regeneración de llaves VAPID perdidas durante el cambio de proyecto.
- **Configuración Cloud**: Llaves configuradas en el entorno seguro de Vercel e integración recuperada en producción.
- **Integridad de BD**: Corregido error "ON CONFLICT" mediante la adición de una restricción `UNIQUE` en la tabla `push_subscriptions`.

---

## 🟢 Sesión: Finanzas Pro y Seguimiento de Compromisos (19 Feb 2026)

### 1. 🛡️ Estabilidad y Sesiones (Ghost Sessions)
Se resolvió el problema de "sesiones fantasma" y datos incorrectos tras el login.
- **Fix RLS Recursion**: Eliminada la recursividad en las políticas de seguridad que bloqueaba el acceso.
- **Login Robusto**: Sincronización corregida entre Supabase Auth y el perfil de la organización.

### 2. 💰 Finanzas Avanzadas
Potenciación del módulo de Finanzas para gastos operativos.
- **Gastos Recurrentes**: Capacidad de programar gastos (mensual, quincenal, etc.) con pre-generación automática de registros.
- **Filtros Flexibles**: Reemplazado el selector de mes por un rango de fechas (Desde/Hasta) para reportes personalizados.
- **RLS Finance**: Blindaje de registros financieros por organización y rol.

### 3. 🤝 Control de Compromisos (Surtir)
Mejoras críticas en la logística de donaciones en especie.
- **Seguimiento Admin**: Nueva pestaña "Compromisos Pendientes" para administradores.
- **Alertas de Vencimiento**: Resaltado visual (Rojo/VENCIDO) para entregas que han superado su fecha prometida.
- **Herramientas de Contacto**: 
  - Botón de **WhatsApp** con mensaje pre-llenado para el donante.
  - Botón de **Aviso App** (Push notification) para recordatorios internos.
- **Integridad de Datos**: Reestructuración de relaciones (FKs) en la BD para asegurar que todos los compromisos sean visibles en las listas.

---

## 🟢 Sesión: Gestión de Usuarios, Donaciones y Balance (05 Feb 2026)

### 1. 👥 Gestión de Usuarios y Seguridad (Multi-tenant)
Se ha blindado la seguridad y la correcta separación de organizaciones.
- **Corrección RLS**: Implementadas políticas recursivas seguras (`FIX_RLS_RECURSION.sql`) para evitar errores 500.
- **Visibilidad**: Los usuarios ahora solo ven perfiles de su propia organización ("GabyMartínez").
- **Limpieza**: Eliminados usuarios fantasma de otras organizaciones (OPMobility, Solu360) que aparecían por error.
- **Admin**: Corregido filtro en `admin.vue` para gestionar usuarios correctamente.

### 2. 💖 Vista de Patrocinador (Donaciones)
Mejoras en la experiencia para el rol `APORTADOR` (Patrocinador).
- **Botón "Donar Dinero"**: Agregado en la sección `/surtir`.
- **Datos Bancarios**: Modal que muestra cuentas (CLABE, Banco, Beneficiario) de la organización.
- **Composable**: Creado `useBankInfo.ts` para reutilizar lógica de datos bancarios.

### 3. 📦 Mejoras en Sección "Surtir"
- **Información Detallada**: Ahora las tarjetas muestran:
  - Costo Unitario Estimado.
  - Costo Total a surtir.
  - Proveedor Sugerido.
- **Objetivo**: Ayudar a los aportadores a decidir mejor qué necesidades cubrir.

### 4. 💰 Módulo de Balance (Refinamiento Previo)
- Preparada la estructura para **Categorías y Subcategorías** (`EXTEND_FINANCE_MODULE.sql`).
- Nuevas métricas: "Ahorro por Donativos" y "Necesidades Pendientes".

---

## 🟢 Sesión: Finanzas e Inventario (30 Ene 2026)

### 1. 💰 Módulo de Finanzas (¡Nuevo!) [Ver walkthrough](../.gemini/antigravity/brain/e5311563-87d0-4dd1-97da-ed7060c63120/walkthrough.md)
Se ha implementado el módulo de **Finanzas y Balance** (`/finanzas`) con las siguientes capacidades:
- **Balance Operativo**: Distingue entre ingresos/gastos **Regulares** (Renta, Nómina) y **Eventuales**.
- **Integración con Almacén**: Los Donativos en especie se reflejan automáticamente.
- **Gestión Completa**: Crear, **Editar** y Eliminar movimientos.
- **Navegación Histórica**: Selector de meses funcional para revisar balances pasados.
- **Base de Datos**: Script `ADD_FINANCE_COLS.sql` para soportar columna `frequency`.

### 2. 📦 Correcciones en Inventario
- **Historial de Ítems**: Implementado modal en `/almacen` para ver entradas/salidas de cada insumo.
- **Eliminar Entradas**: Corregido bug de permisos (RLS) que impedía borrar registros en `/entradas`. Script `FIX_DELETE_POLICY.sql`.
- **Ajuste Manual**: Corregida la respuesta visual al guardar un ajuste de inventario.

---

## 🛠️ Correcciones de Estabilidad (Sesión Anterior)
*(Ver historial previo para detalles de Auth y Admin)*
