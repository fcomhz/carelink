
import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import fs from 'fs'
import path from 'path'

const envPath = path.resolve(process.cwd(), '.env')
const envConfig = dotenv.parse(fs.readFileSync(envPath))

const supabase = createClient(envConfig.SUPABASE_URL, envConfig.SUPABASE_SERVICE_KEY)

async function checkFulfillments() {
    console.log('--- CHECKING FULFILLMENTS TABLE ---')
    const { data: cols, error } = await supabase.rpc('inspect_table', {
        schema_name: 'app_carelink',
        table_name: 'fulfillments'
    })

    if (error) {
        console.log('RPC failed, trying query...')
        const { data, error: qError } = await supabase.schema('app_carelink').from('fulfillments').select().limit(1)
        if (data && data.length > 0) {
            console.log('Columns:', Object.keys(data[0]))
        } else {
            console.log('No data found, trying to get columns from information_schema via RPC if possible')
            // Trying a generic SQL rpc if it exists
            const { data: schemaCols, error: sError } = await supabase.rpc('exec_sql', {
                sql: "SELECT column_name FROM information_schema.columns WHERE table_schema = 'app_carelink' AND table_name = 'fulfillments'"
            })
            console.log('Schema Cols:', schemaCols || sError)
        }
    } else {
        console.log('Columns:', cols)
    }
}

checkFulfillments()
