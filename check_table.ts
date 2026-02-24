import { createClient } from '@supabase/supabase-js'
import * as dotenv from 'dotenv'
dotenv.config()

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!)

async function check() {
  const { data, error } = await supabase.rpc('get_table_info', { t_name: 'push_subscriptions' })
  if (error) {
    // If RPC doesn't exist, try a direct query to information_schema
    const { data: cols, error: colError } = await supabase.from('push_subscriptions').select('*').limit(1)
    console.log('Table exists:', !colError)
    
    // Try to check constraints via direct SQL if possible (sometimes allowed for service_role)
    const { data: constraints, error: constError } = await supabase.rpc('inspect_constraints', { t_name: 'push_subscriptions' })
    console.log('Constraints error:', constError?.message)
  } else {
    console.log('Table info:', data)
  }
}

check()
