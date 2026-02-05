/**
 * API Route: Send Push Notifications
 * POST /api/push/send
 * 
 * Sends push notifications to users in an organization
 */
import webpush from 'web-push'
import { serverSupabaseServiceRole } from '#supabase/server'

interface PushPayload {
    organizationId: string
    title: string
    body: string
    url?: string
    icon?: string
    targetUserIds?: string[]
    excludeUserId?: string
}

export default defineEventHandler(async (event) => {
    const config = useRuntimeConfig()

    // Validate VAPID configuration
    if (!config.public.vapidPublicKey || !config.vapidPrivateKey) {
        throw createError({
            statusCode: 500,
            message: 'VAPID keys not configured'
        })
    }

    // Parse request body
    const body = await readBody<PushPayload>(event)

    if (!body.organizationId || !body.title || !body.body) {
        throw createError({
            statusCode: 400,
            message: 'Missing required fields: organizationId, title, body'
        })
    }

    // Configure web-push
    webpush.setVapidDetails(
        `mailto:${config.vapidEmail}`,
        config.public.vapidPublicKey,
        config.vapidPrivateKey
    )

    // Get Supabase client with service role
    const supabase = await serverSupabaseServiceRole(event)

    // Build query for subscriptions
    let query = supabase
        .from('push_subscriptions')
        .select('id, user_id, endpoint, keys')
        .eq('organization_id', body.organizationId)

    // Filter by specific users if provided
    if (body.targetUserIds?.length) {
        query = query.in('user_id', body.targetUserIds)
    }

    // Exclude sender if specified
    if (body.excludeUserId) {
        query = query.neq('user_id', body.excludeUserId)
    }

    const { data: subscriptions, error: fetchError } = await query

    if (fetchError) {
        console.error('Error fetching subscriptions:', fetchError)
        throw createError({
            statusCode: 500,
            message: 'Error fetching push subscriptions'
        })
    }

    if (!subscriptions?.length) {
        return { sent: 0, total: 0, message: 'No subscriptions found' }
    }

    // Prepare notification payload
    const notificationPayload = JSON.stringify({
        title: body.title,
        body: body.body,
        icon: body.icon || '/icons/icon-192.png',
        badge: '/icons/icon-192.png',
        url: body.url || '/',
        timestamp: Date.now()
    })

    // Send to all subscriptions
    const results = await Promise.allSettled(
        subscriptions.map(async (sub) => {
            try {
                await webpush.sendNotification(
                    {
                        endpoint: sub.endpoint,
                        keys: sub.keys as { p256dh: string; auth: string }
                    },
                    notificationPayload
                )
                return { success: true, id: sub.id }
            } catch (error: any) {
                // Handle expired subscriptions
                if (error.statusCode === 404 || error.statusCode === 410) {
                    // Remove expired subscription
                    await supabase
                        .from('push_subscriptions')
                        .delete()
                        .eq('id', sub.id)

                    console.log(`Removed expired subscription: ${sub.id}`)
                }
                return { success: false, id: sub.id, error: error.message }
            }
        })
    )

    const successful = results.filter(
        (r) => r.status === 'fulfilled' && (r.value as any).success
    ).length

    const failed = results.length - successful

    console.log(`Push notifications sent: ${successful}/${results.length}`)

    return {
        sent: successful,
        failed,
        total: results.length
    }
})
