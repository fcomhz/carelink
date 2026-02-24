import { createClient } from '@supabase/supabase-js'
import * as dotenv from 'dotenv'
dotenv.config()

// Switch to service_role to bypass RLS and read system info
const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
  db: { schema: 'app_carelink' }
})

async function check() {
  console.log('Checking app_carelink.announcements...')
  
  // Try to test if RLS is enabled by doing a dummy query with service_role (should always work)
  // But we want to know IF it's enabled. We can query pg_class.
  
  const { data, error } = await supabase.rpc('inspect_table_rls', { schema_name: 'app_carelink', table_name: 'announcements' })
  
  if (error) {
     console.log('RPC inspect_table_rls failed. Trying raw query via pg_tables/pg_class...')
     // Most projects don't have these RPCs. Let's try to query the table directly with service_role.
     const { data: testData, error: testError } = await supabase.from('announcements').select('id').limit(1)
     if (testError) {
        console.log('Error selecting from announcements (service_role):', testError.message)
     } else {
        console.log('Selection with service_role worked. Table exists.')
     }
  } else {
     console.log('RLS Info:', data)
  }

  // LET'S TRY TO CREATE POLICIES IF THEY ARE MISSING
  // Based on categories policies, announcements should probably have:
  // 1. SELECT for all in org
  // 2. ALL (Insert/Update/Delete) for ADMINs in org
}

check()
