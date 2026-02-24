
import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import fs from 'fs'
import path from 'path'

const envPath = path.resolve(process.cwd(), '.env')
const envConfig = dotenv.parse(fs.readFileSync(envPath))

const supabase = createClient(envConfig.SUPABASE_URL, envConfig.SUPABASE_SERVICE_KEY)

async function inspectSchema() {
    const tables = ['requests', 'collection_centers', 'profiles', 'fulfillments']

    for (const table of tables) {
        console.log(`--- TABLE: app_carelink.${table} ---`)
        const { data, error } = await supabase.rpc('inspect_table', {
            schema_name: 'app_carelink',
            table_name: table
        })

        if (error) {
            console.log(`Alternative view for ${table}...`)
            const { data: q, error: e } = await supabase.schema('app_carelink').from(table).select().limit(1)
            if (q) console.log('Columns:', Object.keys(q[0] || {}))
            else console.error('Error:', e)
        } else {
            console.log('Details:', JSON.stringify(data, null, 2))
        }
    }
}

inspectSchema().then(() => process.exit(0))
