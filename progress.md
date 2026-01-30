# Progreso del Proyecto CareLink

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
