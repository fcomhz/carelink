/**
 * Composable for managing Push Notifications
 * Handles permission requests, subscription, and registration with Supabase
 */
export const usePushNotifications = () => {
    const supabase = useSupabaseClient()
    const user = useSupabaseUser()
    const { organizationId } = useOrganization()
    const config = useRuntimeConfig()

    const isSupported = ref(false)
    const isSubscribed = ref(false)
    const isLoading = ref(false)
    const permission = ref<NotificationPermission>('default')
    const error = ref<string | null>(null)

    // Check support on mount
    const checkSupport = () => {
        if (import.meta.client) {
            isSupported.value = 'serviceWorker' in navigator && 'PushManager' in window
            permission.value = Notification?.permission || 'default'
        }
    }

    // Request notification permission
    const requestPermission = async (): Promise<boolean> => {
        if (!isSupported.value) {
            error.value = 'Push notifications no soportadas en este navegador'
            return false
        }

        try {
            const result = await Notification.requestPermission()
            permission.value = result
            return result === 'granted'
        } catch (e) {
            error.value = 'Error al solicitar permisos'
            console.error('Permission request error:', e)
            return false
        }
    }

    // Subscribe to push notifications
    const subscribe = async (): Promise<PushSubscription | null> => {
        if (!isSupported.value) return null
        if (permission.value !== 'granted') {
            const granted = await requestPermission()
            if (!granted) return null
        }

        isLoading.value = true
        error.value = null

        try {
            const registration = await navigator.serviceWorker.ready

            // Check for existing subscription
            let subscription = await registration.pushManager.getSubscription()

            if (!subscription) {
                // Create new subscription
                const vapidPublicKey = config.public.vapidPublicKey
                if (!vapidPublicKey) {
                    throw new Error('VAPID public key not configured')
                }

                subscription = await registration.pushManager.subscribe({
                    userVisibleOnly: true,
                    applicationServerKey: urlBase64ToUint8Array(vapidPublicKey)
                })
            }

            // Save to Supabase
            const subscriptionJson = subscription.toJSON()

            const { error: dbError } = await supabase
                .from('push_subscriptions')
                .upsert({
                    user_id: user.value?.id,
                    organization_id: organizationId.value,
                    endpoint: subscription.endpoint,
                    keys: subscriptionJson.keys,
                    updated_at: new Date().toISOString()
                }, {
                    onConflict: 'endpoint'
                })

            if (dbError) {
                console.error('Error saving subscription:', dbError)
                throw dbError
            }

            isSubscribed.value = true
            console.log('Push subscription saved successfully')
            return subscription

        } catch (e: any) {
            error.value = e.message || 'Error al suscribirse a notificaciones'
            console.error('Subscription error:', e)
            return null
        } finally {
            isLoading.value = false
        }
    }

    // Unsubscribe from push notifications
    const unsubscribe = async (): Promise<boolean> => {
        if (!isSupported.value) return false

        isLoading.value = true
        error.value = null

        try {
            const registration = await navigator.serviceWorker.ready
            const subscription = await registration.pushManager.getSubscription()

            if (subscription) {
                // Remove from Supabase first
                await supabase
                    .from('push_subscriptions')
                    .delete()
                    .eq('endpoint', subscription.endpoint)

                // Then unsubscribe from push manager
                await subscription.unsubscribe()
            }

            isSubscribed.value = false
            return true

        } catch (e: any) {
            error.value = e.message || 'Error al cancelar suscripción'
            console.error('Unsubscribe error:', e)
            return false
        } finally {
            isLoading.value = false
        }
    }

    // Check if already subscribed
    const checkSubscription = async (): Promise<boolean> => {
        if (!isSupported.value) return false

        try {
            const registration = await navigator.serviceWorker.ready
            const subscription = await registration.pushManager.getSubscription()
            isSubscribed.value = !!subscription
            return isSubscribed.value
        } catch (e) {
            console.error('Error checking subscription:', e)
            return false
        }
    }

    // Initialize on client
    onMounted(() => {
        checkSupport()
        if (isSupported.value && permission.value === 'granted') {
            checkSubscription()
        }
    })

    return {
        isSupported,
        isSubscribed,
        isLoading,
        permission,
        error,
        requestPermission,
        subscribe,
        unsubscribe,
        checkSubscription
    }
}

/**
 * Convert VAPID public key from base64 URL to Uint8Array
 */
function urlBase64ToUint8Array(base64String: string): Uint8Array {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding)
        .replace(/-/g, '+')
        .replace(/_/g, '/')

    const rawData = atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i)
    }

    return outputArray
}
