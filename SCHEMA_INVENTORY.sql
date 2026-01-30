BEGIN;

-- 1. Table: Inventory Items (Existencias)
CREATE TABLE IF NOT EXISTS app_carelink.inventory_items (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) NOT NULL,
  
  name text NOT NULL, -- Nombre del insumo
  quantity numeric DEFAULT 0 CHECK (quantity >= 0), -- Stock actual
  min_stock numeric DEFAULT 5, -- Nivel para alerta
  location text, -- Ubicación en anaquel/bodega
  category_id uuid REFERENCES app_carelink.categories(id),
  
  last_updated timestamptz DEFAULT now(),
  
  UNIQUE(organization_id, name) -- Evitar duplicados por nombre en la misma org
);

-- 2. Table: Inventory Transactions (Kardex: Entradas/Salidas)
CREATE TABLE IF NOT EXISTS app_carelink.inventory_transactions (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) NOT NULL,
  
  item_id uuid REFERENCES app_carelink.inventory_items(id) NOT NULL,
  type text NOT NULL CHECK (type IN ('IN', 'OUT', 'ADJUST')), -- Entrada, Salida, Ajuste
  quantity numeric NOT NULL CHECK (quantity > 0),
  
  performed_by uuid REFERENCES app_carelink.profiles(id),
  notes text, -- Motivo, o "Entrada de Compras", "Consumo Paciente X"
  related_entity_id uuid, -- ID de fulfillment o request si aplica
  
  created_at timestamptz DEFAULT now()
);

-- 3. RLS Policies

-- Items:
ALTER TABLE app_carelink.inventory_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View Inventory (Org)" ON app_carelink.inventory_items
  FOR SELECT TO authenticated
  USING (organization_id = app_carelink.get_user_org());

CREATE POLICY "Manage Inventory (Admins/Staff)" ON app_carelink.inventory_items
  FOR ALL TO authenticated
  USING (organization_id = app_carelink.get_user_org()) -- Se refine si quieres restringir solo a Admins, por ahora Staff también ayuda
  WITH CHECK (organization_id = app_carelink.get_user_org());

-- Transactions:
ALTER TABLE app_carelink.inventory_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View Transactions (Org)" ON app_carelink.inventory_transactions
  FOR SELECT TO authenticated
  USING (organization_id = app_carelink.get_user_org());

CREATE POLICY "Create Transactions (Org)" ON app_carelink.inventory_transactions
  FOR INSERT TO authenticated
  WITH CHECK (organization_id = app_carelink.get_user_org());

-- 4. Grants
GRANT ALL ON TABLE app_carelink.inventory_items TO authenticated;
GRANT ALL ON TABLE app_carelink.inventory_transactions TO authenticated;

COMMIT;
