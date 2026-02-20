import { serverSupabaseServiceRole } from '#supabase/server'

export default defineEventHandler(async (event) => {
    try {
        const method = getMethod(event)
        const client = serverSupabaseServiceRole(event)

        if (method === 'DELETE') {
            const { id } = await readBody(event)
            // Profiles usually cascade on delete cascade, but in schema.sql we have references.
            // If it doesn't cascade, we manually delete it.
            const { error: profileError } = await client.schema('app_carelink').from('profiles').delete().eq('id', id)
            if (profileError) throw profileError

            // Eliminate Auth user
            const { error: authError } = await client.auth.admin.deleteUser(id)
            if (authError) throw authError

            return { success: true }
        }

        const body = await readBody(event)
        const { id, email, password, full_name, phone, role, organization_id } = body

        let userId = id

        if (id) {
            // UPDATE EXISTING USER
            const updateData: any = {
                email: email,
                user_metadata: { full_name, role },
                app_metadata: {
                    schema: 'app_carelink',
                    organization: 'GabyMartínez',
                    organization_id: organization_id
                }
            }

            if (password && password.length >= 6) {
                updateData.password = password
            }

            const { error: authError } = await client.auth.admin.updateUserById(id, updateData)
            if (authError) throw authError

        } else {
            // CREATE NEW USER
            const { data: authData, error: authError } = await client.auth.admin.createUser({
                email: email,
                password: password,
                email_confirm: true,
                user_metadata: { full_name, role },
                app_metadata: {
                    schema: 'app_carelink',
                    organization: 'GabyMartínez',
                    organization_id: organization_id
                }
            })

            if (authError) throw authError
            if (!authData.user) throw new Error('No se pudo crear el usuario en Auth.')

            userId = authData.user.id
        }

        // UPSERT PROFILE
        const { error: profileError } = await client
            .schema('app_carelink')
            .from('profiles')
            .upsert({
                id: userId,
                organization_id,
                email,
                full_name,
                phone,
                role,
                updated_at: new Date().toISOString()
            })

        if (profileError) throw profileError

        return { success: true, userId }

    } catch (error: any) {
        console.error('Admin API Error:', error)
        // Return 200 with error details to ensure client sees the message
        return {
            success: false,
            error: error.message || 'Error desconocido',
            details: error
        }
    }
})
