/**
 * Plugin to force Supabase schema configuration
 * The @nuxtjs/supabase module doesn't always respect the schema config in production
 */
export default defineNuxtPlugin({
    name: 'supabase-schema-fix',
    enforce: 'post', // Run after supabase plugin
    setup() {
        const client = useSupabaseClient()
        const config = useRuntimeConfig()

        // Get the schema from config or default to app_carelink
        const schema = 'app_carelink'

        if (import.meta.client) {
            console.log('[Supabase Schema Fix] Setting default schema to:', schema)

            // Override the from method to always use the correct schema
            const originalFrom = client.from.bind(client)

            client.from = function (table: string) {
                // Use the schema() method before from()
                return client.schema(schema).from(table)
            }

            console.log('[Supabase Schema Fix] Schema override applied')
        }
    }
})
