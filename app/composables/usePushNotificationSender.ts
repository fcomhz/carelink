/**
 * Composable for sending push notifications to users
 * Used by the application to trigger notifications for various events
 */
export const usePushNotificationSender = () => {
    const { organizationId } = useOrganization()
    const user = useSupabaseUser()

    /**
     * Send a notification to users in the organization
     */
    const sendNotification = async (options: {
        title: string
        body: string
        url?: string
        targetUserIds?: string[]
        excludeSelf?: boolean
    }): Promise<{ sent: number; failed: number } | null> => {
        if (!organizationId.value) {
            console.warn('No organization ID available')
            return null
        }

        try {
            const response = await $fetch('/api/push/send', {
                method: 'POST',
                body: {
                    organizationId: organizationId.value,
                    title: options.title,
                    body: options.body,
                    url: options.url || '/',
                    targetUserIds: options.targetUserIds,
                    excludeUserId: options.excludeSelf ? user.value?.id : undefined
                }
            })

            return response as { sent: number; failed: number }
        } catch (error) {
            console.error('Error sending push notification:', error)
            return null
        }
    }

    /**
     * Notify admins about a new request
     */
    const notifyNewRequest = async (itemName: string, requesterName: string, requesterId?: string, organizationId?: string) => {
        return sendNotification({
            title: '📋 Nueva Solicitud',
            body: `${requesterName} solicitó: ${itemName}`,
            url: '/solicitudes',
            excludeSelf: true
        })
    }

    /**
     * Notify about a new chat message
     */
    const notifyNewMessage = async (ticketTitle: string, senderName: string, messagePreview: string, targetUserIds?: string[]) => {
        return sendNotification({
            title: `💬 ${senderName} en: ${ticketTitle}`,
            body: messagePreview,
            url: '/chat',
            targetUserIds,
            excludeSelf: true
        })
    }

    /**
     * Notify admins that someone committed to fulfill a request
     */
    const notifyRequestCompromised = async (itemName: string, donorName: string) => {
        return sendNotification({
            title: '🤝 Nuevo Compromiso',
            body: `${donorName} se comprometió a surtir: ${itemName}`,
            url: '/surtir',
            excludeSelf: true
        })
    }

    /**
     * Notify about a new announcement
     */
    const notifyNewAnnouncement = async (announcementTitle: string) => {
        return sendNotification({
            title: '📢 Nuevo Aviso',
            body: announcementTitle,
            url: '/'
        })
    }

    /**
     * Notify requester about approval
     */
    const notifyRequestApproved = async (itemName: string, requesterId: string) => {
        return sendNotification({
            title: '✅ Solicitud Aprobada',
            body: `Tu solicitud de "${itemName}" fue aprobada`,
            url: '/solicitudes',
            targetUserIds: [requesterId]
        })
    }

    /**
     * Notify about donation received
     */
    const notifyDonationReceived = async (itemName: string, donorName: string) => {
        return sendNotification({
            title: '🎁 Donación Recibida',
            body: `${donorName} donó: ${itemName}`,
            url: '/surtir',
            excludeSelf: true
        })
    }

    return {
        sendNotification,
        notifyNewRequest,
        notifyNewMessage,
        notifyNewAnnouncement,
        notifyRequestApproved,
        notifyDonationReceived
    }
}
