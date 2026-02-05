-- GRANT MASTER ADMIN ACCESS to fcomhz@gmail.com
-- This script matches the user by email in auth.users and updates/inserts their profile with ADMIN role.

DO $$
DECLARE
    target_email text := 'fcomhz@gmail.com';
    target_org_name text := 'GabyMartínez';
    user_id uuid;
    org_id uuid;
BEGIN
    -- 1. Find the User ID from auth.users
    SELECT id INTO user_id FROM auth.users WHERE email = target_email;

    IF user_id IS NULL THEN
        RAISE EXCEPTION 'User % not found in auth.users. Please sign up first.', target_email;
    END IF;

    -- 2. Find the Organization ID
    SELECT id INTO org_id FROM app_carelink.organizations WHERE name = target_org_name;

    IF org_id IS NULL THEN
        -- Fallback: If org doesn't exist, create it (Safety net)
        INSERT INTO app_carelink.organizations (name) VALUES (target_org_name)
        RETURNING id INTO org_id;
    END IF;

    -- 3. Upsert into Profiles with ADMIN role
    INSERT INTO app_carelink.profiles (id, organization_id, email, role, full_name, permissions)
    VALUES (
        user_id,
        org_id,
        target_email,
        'ADMIN',
        'Master Admin',
        '["ALL"]'::jsonb
    )
    ON CONFLICT (id) DO UPDATE SET
        organization_id = EXCLUDED.organization_id,
        role = 'ADMIN',
        permissions = '["ALL"]'::jsonb;

    RAISE NOTICE 'SUCCESS: User % granted ADMIN access to organization %', target_email, target_org_name;

END $$;
