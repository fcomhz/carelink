-- CORRECCIÓN PARA ELIMINACIÓN DE CATEGORÍAS

BEGIN;

-- 1. Modificar la relación en Requests para permitir borrar la categoría sin borrar el pedido
-- (Se pondrá en NULL si la categoría desaparece)
ALTER TABLE app_carelink.requests 
  DROP CONSTRAINT IF EXISTS requests_category_id_fkey;

ALTER TABLE app_carelink.requests
  ADD CONSTRAINT requests_category_id_fkey 
  FOREIGN KEY (category_id) 
  REFERENCES app_carelink.categories(id)
  ON DELETE SET NULL;

-- 2. Asegurar que la política de Categorías permita DELETE
DROP POLICY IF EXISTS "Admins can manage categories" ON app_carelink.categories;

CREATE POLICY "Admins can manage categories" ON app_carelink.categories
  FOR ALL TO authenticated
  USING (
    organization_id = app_carelink.get_user_org() 
    AND 
    EXISTS (
      SELECT 1 FROM app_carelink.profiles 
      WHERE id = auth.uid() AND role = 'ADMIN'
    )
  );

-- 3. Otorgar permisos explícitos de DELETE
GRANT DELETE ON app_carelink.categories TO authenticated;

COMMIT;
