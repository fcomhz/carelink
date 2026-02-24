import { createClient } from '@supabase/supabase-js'
import * as dotenv from 'dotenv'
dotenv.config()

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!)

async function inspect() {
  console.log('Inspecting app_carelink.announcements table...')
  
  // Check if RLS is enabled
  const { data: rlsStatus, error: rlsError } = await supabase.rpc('inspect_rls', { t_name: 'announcements' })
  // If RPC doesn't exist, use raw query
  if (rlsError) {
    const { data: p, error: pe } = await supabase.from('profiles').select('id, role').limit(1)
    console.log('Testing connectivity (profiles):', !!p)
    
    // We'll try to get policies using standard postgres queries if allowed via RPC or just report we can't
    const { data: policies, error: polError } = await supabase.rpc('get_policies', { t_name: 'announcements' })
    if (polError) {
       console.log('Could not use RPC to inspect policies. Error:', polError.message)
    } else {
       console.log('Policies found:', JSON.stringify(policies, null, 2))
    }
  } else {
    console.log('RLS Status:', JSON.stringify(rlsStatus, null, 2))
  }
  
  // List columns of announcements
  const { data: cols, error: colError } = await supabase.from('announcements').select('*').limit(1)
  if (colError) {
    console.log('Error selecting from announcements:', colError.message)
  } else {
    console.log('Columns sample (keys):', Object.keys(cols[0] || {}))
  }
}

inspect()
