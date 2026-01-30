import { createClient } from '@supabase/supabase-js'

const url = process.env.SUPABASE_URL || 'https://qqhbxoipqhhmlopbwnhm.supabase.co'
const key = process.env.SUPABASE_SERVICE_ROLE_KEY

const supabase = createClient(url, key!)

async function main() {
    const userId = '37c15d08-4db8-4fc7-9ee2-09aac4ab7b12'
    console.log('Checking profile for user:', userId)

    const { data: profile, error } = await supabase.schema('app_carelink')
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single()

    if (error) {
        console.error('Error fetching profile:', error)
    } else {
        console.log('Profile found:', JSON.stringify(profile, null, 2))
    }

    // Check organizations
    const { data: orgs } = await supabase.schema('app_carelink').from('organizations').select('*')
    console.log('Available Organizations:', JSON.stringify(orgs, null, 2))

    // Check if get_user_org function returns correct ID for this user
    const { data: orgFunc, error: funcErr } = await supabase.rpc('get_user_org', {}, {})
    // Wait, RPC might not work for stable function if we call it from service role without setting auth.uid()
    // But we can check via SQL if we had query access.
}

main()
