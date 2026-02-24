
import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import fs from 'fs'
import path from 'path'

const envPath = path.resolve(process.cwd(), '.env')
const envConfig = dotenv.parse(fs.readFileSync(envPath))

const supabase = createClient(envConfig.SUPABASE_URL, envConfig.SUPABASE_SERVICE_KEY)

async function checkData() {
    console.log('--- STARTING FULFILLMENTS FETCH (SIMPLE) ---')
    try {
        console.log('Querying app_carelink.fulfillments...')
        const { data, error } = await supabase.schema('app_carelink')
            .from('fulfillments')
            .select(`
                *,
                request:requests!request_id(item),
                user_profile:profiles!user_id(full_name, email)
            `)
            .limit(5)

        if (error) {
            console.error('Error fetching fulfillments:', JSON.stringify(error, null, 2))
        } else {
            console.log('Successfully fetched', data?.length || 0, 'records')
            console.log('Data:', JSON.stringify(data, null, 2))
        }
    } catch (err) {
        console.error('Unexpected error:', err)
    }
}

checkData().then(() => process.exit(0)).catch(err => {
    console.error(err);
    process.exit(1);
})
