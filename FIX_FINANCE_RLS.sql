BEGIN;

-- Allow Admins to manage Finance Records
CREATE POLICY "Admins Manage Finance" ON app_carelink.finance_records
  FOR ALL TO authenticated
  USING (
    organization_id = app_carelink.get_user_org() 
    AND 
    EXISTS (SELECT 1 FROM app_carelink.profiles WHERE id = auth.uid() AND role = 'ADMIN')
  );

GRANT ALL ON TABLE app_carelink.finance_records TO authenticated;

COMMIT;
