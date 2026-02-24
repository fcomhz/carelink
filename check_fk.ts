
import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'
import fs from 'fs'
import path from 'path'

const envPath = path.resolve(process.cwd(), '.env')
const envConfig = dotenv.parse(fs.readFileSync(envPath))

const supabase = createClient(envConfig.SUPABASE_URL, envConfig.SUPABASE_SERVICE_KEY)

async function checkFKs() {
    console.log('--- CHECKING FOREIGN KEYS ---')
    const { data, error } = await supabase.rpc('exec_sql', {
        sql: `
            SELECT
                tc.table_name, 
                kcu.column_name, 
                ccu.table_name AS foreign_table_name,
                ccu.column_name AS foreign_column_name 
            FROM 
                information_schema.table_constraints AS tc 
                JOIN information_schema.key_column_usage AS kcu
                  ON tc.constraint_name = kcu.constraint_name
                  AND tc.table_schema = kcu.table_schema
                JOIN information_schema.constraint_column_usage AS ccu
                  ON ccu.constraint_name = tc.constraint_name
                  AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY' 
              AND tc.table_schema = 'app_carelink'
              AND tc.table_name = 'fulfillments';
        `
    })

    if (error) {
        console.error('Error:', error)
        // Alternative if exec_sql rpc doesn't exist
        console.log('Trying direct query on information_schema...')
        const { data: d2, error: e2 } = await supabase.from('information_schema.key_column_usage').select('*').eq('table_schema', 'app_carelink').eq('table_name', 'fulfillments')
        console.log('FKs (raw):', d2 || e2)
    } else {
        console.log('Foreign Keys:', data)
    }
}

checkFKs().then(() => process.exit(0))
