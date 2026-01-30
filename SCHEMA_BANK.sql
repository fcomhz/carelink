BEGIN;

-- 1. Create Bank Accounts Table
CREATE TABLE IF NOT EXISTS app_carelink.bank_accounts (
  id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
  organization_id uuid REFERENCES app_carelink.organizations(id) NOT NULL,
  
  bank_name text NOT NULL, -- e.g. BBVA, Santander
  account_number text, -- # Cuenta
  clabe text, -- CLABE interbancaria (18 digits)
  beneficiary text, -- Nombre del titular
  notes text, -- e.g. "Para donativos", "Gastos generales"
  
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 2. RLS Policies
ALTER TABLE app_carelink.bank_accounts ENABLE ROW LEVEL SECURITY;

-- Read: All authenticated users in the org (so they can see where to deposit)
CREATE POLICY "View Bank Accounts (Org)" ON app_carelink.bank_accounts
  FOR SELECT TO authenticated
  USING (organization_id = app_carelink.get_user_org());

-- Manage: Only Admins can create/edit/delete
CREATE POLICY "Manage Bank Accounts (Admin)" ON app_carelink.bank_accounts
  FOR ALL TO authenticated
  USING (
    organization_id = app_carelink.get_user_org() 
    AND 
    EXISTS (SELECT 1 FROM app_carelink.profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

-- 3. Grants
GRANT ALL ON TABLE app_carelink.bank_accounts TO authenticated;

COMMIT;
