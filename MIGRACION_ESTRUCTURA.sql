-- ==========================================
-- SCRIPT DE MIGRACIÓN COMPLETA (CARELINK)
-- Este archivo contiene la estructura y las relaciones
-- ==========================================

-- 1. LIMPIEZA / INICIALIZACIÓN
CREATE SCHEMA IF NOT EXISTS app_carelink;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TIPOS DE DATOS (ENUMS)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role' AND typnamespace = 'app_carelink'::regnamespace) THEN
        CREATE TYPE app_carelink.app_role AS ENUM ('ADMIN', 'ASISTENTE', 'ENFERMERO', 'APORTADOR');
    END IF;
END $$;

-- 3. TABLA DE ORGANIZACIONES
CREATE TABLE IF NOT EXISTS app_carelink.organizations (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  name text NOT NULL UNIQUE,
  created_at timestamptz DEFAULT now()
);

-- 4. TABLA DE PERFILES (VINCULADA A AUTH.USERS)
CREATE TABLE IF NOT EXISTS app_carelink.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) ON DELETE CASCADE NOT NULL,
  email text NOT NULL,
  full_name text,
  phone text,
  role app_carelink.app_role DEFAULT 'ASISTENTE',
  permissions jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 5. TABLA DE SOLICITUDES (REQUESTS)
CREATE TABLE IF NOT EXISTS app_carelink.requests (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  item text NOT NULL,
  category text NOT NULL, 
  cost numeric DEFAULT 0,
  quantity integer DEFAULT 1,
  requester_id uuid REFERENCES app_carelink.profiles(id) ON DELETE SET NULL,
  status text DEFAULT 'PENDIENTE', 
  provider_info text,
  donor_info text, 
  committed_by uuid REFERENCES app_carelink.profiles(id) ON DELETE SET NULL
);

-- 6. TABLA DE ANUNCIOS (ANNOUNCEMENTS)
CREATE TABLE IF NOT EXISTS app_carelink.announcements (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  title text NOT NULL,
  body text NOT NULL,
  image_url text,
  audience_role text DEFAULT 'TODOS',
  author_id uuid REFERENCES app_carelink.profiles(id) ON DELETE SET NULL
);

-- 7. TABLA DE FINANZAS (FINANCE_RECORDS)
CREATE TABLE IF NOT EXISTS app_carelink.finance_records (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  date_occurred date DEFAULT current_date,
  concept text NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  category text, 
  type text NOT NULL CHECK (type IN ('IN', 'OUT')),
  frequency text DEFAULT 'EVENTUAL',
  recorded_by uuid REFERENCES app_carelink.profiles(id) ON DELETE SET NULL
);

-- 8. SEGURIDAD (RLS)
ALTER TABLE app_carelink.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_carelink.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_carelink.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_carelink.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_carelink.finance_records ENABLE ROW LEVEL SECURITY;

-- 9. FUNCIÓN DE AYUDA PARA FILTRADO POR ORGANIZACIÓN
CREATE OR REPLACE FUNCTION app_carelink.get_user_org() RETURNS uuid AS $$
  SELECT organization_id FROM app_carelink.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- 10. POLÍTICAS BÁSICAS (EJEMPLO)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Tenant Isolation Profiles') THEN
        CREATE POLICY "Tenant Isolation Profiles" ON app_carelink.profiles 
        FOR ALL USING (organization_id = app_carelink.get_user_org());
    END IF;
END $$;

-- 11. PERMISOS DE ROL DE SERVICIO (NECESARIO PARA VERCEL/NUXT)
GRANT USAGE ON SCHEMA app_carelink TO authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA app_carelink TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA app_carelink TO authenticated, service_role;

DO $$ 
BEGIN 
    RAISE NOTICE 'Script de Migración (Estructura) completado con éxito.';
END $$;
