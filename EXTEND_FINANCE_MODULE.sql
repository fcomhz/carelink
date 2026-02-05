-- =====================================================
-- EXTENDER FINANCE_RECORDS PARA BALANCE INTEGRAL
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. Agregar columnas nuevas a finance_records
ALTER TABLE app_carelink.finance_records 
ADD COLUMN IF NOT EXISTS subcategory TEXT,
ADD COLUMN IF NOT EXISTS related_request_id UUID REFERENCES app_carelink.requests(id) ON DELETE SET NULL;

-- 2. Modificar el constraint CHECK para permitir INGRESO/EGRESO además de IN/OUT
-- Primero eliminamos el constraint existente
ALTER TABLE app_carelink.finance_records 
DROP CONSTRAINT IF EXISTS finance_records_type_check;

-- Recreamos el constraint con ambos formatos permitidos
ALTER TABLE app_carelink.finance_records
ADD CONSTRAINT finance_records_type_check 
CHECK (type IN ('IN', 'OUT', 'INGRESO', 'EGRESO'));

-- 3. Migrar datos existentes (opcional, mantiene compatibilidad)
-- Si prefieres usar solo INGRESO/EGRESO, descomenta estas líneas:
-- UPDATE app_carelink.finance_records SET type = 'INGRESO' WHERE type = 'IN';
-- UPDATE app_carelink.finance_records SET type = 'EGRESO' WHERE type = 'OUT';

-- 3. Crear tabla de categorías predefinidas (referencia)
CREATE TABLE IF NOT EXISTS app_carelink.finance_categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('INGRESO', 'EGRESO')),
    name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    icon TEXT,
    sort_order INTEGER DEFAULT 0
);

-- Insertar categorías predefinidas
INSERT INTO app_carelink.finance_categories (type, name, display_name, icon, sort_order) VALUES
-- INGRESOS
('INGRESO', 'PENSION', 'Pensión', 'fa-coins', 1),
('INGRESO', 'RENTA', 'Renta/Cuota Familiar', 'fa-home', 2),
('INGRESO', 'DONATIVO_EFECTIVO', 'Donativo en Efectivo', 'fa-hand-holding-usd', 3),
('INGRESO', 'OTRO_INGRESO', 'Otro Ingreso', 'fa-plus-circle', 10),
-- EGRESOS
('EGRESO', 'SERVICIOS', 'Servicios (Luz, Gas, Agua)', 'fa-bolt', 1),
('EGRESO', 'SUELDOS', 'Sueldos Base', 'fa-user-tie', 2),
('EGRESO', 'SUELDOS_EXTRA', 'Sueldos Extra (Feriados)', 'fa-calendar-plus', 3),
('EGRESO', 'AGUINALDO', 'Aguinaldo', 'fa-gift', 4),
('EGRESO', 'COMPRAS', 'Compras de Insumos', 'fa-shopping-cart', 5),
('EGRESO', 'MANTENIMIENTO', 'Mantenimiento', 'fa-tools', 6),
('EGRESO', 'OTRO_EGRESO', 'Otro Gasto', 'fa-minus-circle', 10)
ON CONFLICT DO NOTHING;

-- 4. Dar permisos
ALTER TABLE app_carelink.finance_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read categories" ON app_carelink.finance_categories;
CREATE POLICY "Anyone can read categories" ON app_carelink.finance_categories 
FOR SELECT USING (true);

GRANT SELECT ON app_carelink.finance_categories TO authenticated;

-- 5. Vista para resumen de balance (opcional, útil para reportes)
CREATE OR REPLACE VIEW app_carelink.v_balance_summary AS
SELECT 
    fr.organization_id,
    DATE_TRUNC('month', fr.date_occurred) AS month,
    SUM(CASE WHEN fr.type = 'INGRESO' AND fr.frequency = 'REGULAR' THEN fr.amount ELSE 0 END) AS regular_income,
    SUM(CASE WHEN fr.type = 'INGRESO' AND fr.frequency = 'EVENTUAL' THEN fr.amount ELSE 0 END) AS eventual_income,
    SUM(CASE WHEN fr.type = 'EGRESO' AND fr.frequency = 'REGULAR' THEN fr.amount ELSE 0 END) AS regular_expense,
    SUM(CASE WHEN fr.type = 'EGRESO' AND fr.frequency = 'EVENTUAL' THEN fr.amount ELSE 0 END) AS eventual_expense
FROM app_carelink.finance_records fr
GROUP BY fr.organization_id, DATE_TRUNC('month', fr.date_occurred);

GRANT SELECT ON app_carelink.v_balance_summary TO authenticated;
