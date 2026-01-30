-- ESQUEMA DE SURTIDO Y ACOPIO (FASE 4)

BEGIN;

-- 1. Tabla de Centros de Acopio (Lugares de entrega)
CREATE TABLE IF NOT EXISTS app_carelink.collection_centers (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) NOT NULL,
  
  name text NOT NULL,
  address text NOT NULL,
  google_maps_link text,
  schedule text NOT NULL, -- Horarios de recepción
  contact_info text,      -- Teléfono o persona de contacto
  
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- 2. Tabla de Compromisos (Surtido Parcial/Total)
CREATE TABLE IF NOT EXISTS app_carelink.fulfillments (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  
  request_id uuid REFERENCES app_carelink.requests(id) NOT NULL,
  user_id uuid REFERENCES app_carelink.profiles(id) NOT NULL, -- Quién se compromete (Sponsor/Admin)
  collection_center_id uuid REFERENCES app_carelink.collection_centers(id), -- Dónde entregará

  quantity numeric NOT NULL CHECK (quantity > 0), -- Cuánto va a surtir
  status text NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE, ENTREGADO, CANCELADO
  
  delivery_date date, -- Cuándo planea entregar
  
  -- Campos de Recepción (llenados por Admin)
  received_at timestamptz,
  received_by uuid REFERENCES app_carelink.profiles(id),
  financial_value numeric DEFAULT 0, -- Valor monetario real para Finanzas
  
  created_at timestamptz DEFAULT now()
);

-- 3. Índices para rendimiento
CREATE INDEX IF NOT EXISTS idx_fulfillments_request ON app_carelink.fulfillments(request_id);
CREATE INDEX IF NOT EXISTS idx_fulfillments_user ON app_carelink.fulfillments(user_id);
CREATE INDEX IF NOT EXISTS idx_cc_org ON app_carelink.collection_centers(organization_id);

-- 4. Permisos RLS (Seguridad)

-- Centros de Acopio:
-- Ver: Todos los autenticados de la misma org (o si es público, todos?)
-- Dejémoslo por org por ahora.
ALTER TABLE app_carelink.collection_centers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver Centros de Acopio (Misma Org)" ON app_carelink.collection_centers
  FOR SELECT TO authenticated
  USING (organization_id = app_carelink.get_user_org());

CREATE POLICY "Admin Gestionar Centros" ON app_carelink.collection_centers
  FOR ALL TO authenticated
  USING (
    organization_id = app_carelink.get_user_org() 
    AND 
    EXISTS (SELECT 1 FROM app_carelink.profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- Compromisos (Fulfillments):
-- Ver: Todos en la org (necesario para ver progreso)
ALTER TABLE app_carelink.fulfillments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver Compromisos (Misma Org)" ON app_carelink.fulfillments
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM app_carelink.requests r
      WHERE r.id = fulfillments.request_id AND r.organization_id = app_carelink.get_user_org()
    )
  );

-- Crear: Cualquier usuario autenticado (Sponsors, Admins)
-- PERO solo si la solicitud pertenece a su organización (o es pública? por ahora org)
CREATE POLICY "Crear Compromiso" ON app_carelink.fulfillments
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM app_carelink.requests r
      WHERE r.id = request_id AND r.organization_id = app_carelink.get_user_org()
    )
  );

-- Actualizar: El creador (si está pendiente) O Admin (si recibe)
CREATE POLICY "Gestionar Compromiso" ON app_carelink.fulfillments
  FOR UPDATE TO authenticated
  USING (
    user_id = auth.uid() -- El dueño puede editar
    OR 
    EXISTS (SELECT 1 FROM app_carelink.profiles WHERE id = auth.uid() AND role = 'ADMIN') -- Admin puede editar
  );


-- 5. Permisos Grant
GRANT ALL ON TABLE app_carelink.collection_centers TO authenticated;
GRANT ALL ON TABLE app_carelink.fulfillments TO authenticated;

COMMIT;
