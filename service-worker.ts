import { precacheAndRoute, cleanupOutdatedCaches } from 'workbox-precaching'
import { clientsClaim } from 'workbox-core'
import { registerRoute, NavigationRoute } from 'workbox-routing'
import { CacheFirst, NetworkFirst } from 'workbox-strategies'
import { ExpirationPlugin } from 'workbox-expiration'
import { CacheableResponsePlugin } from 'workbox-cacheable-response'

declare let self: ServiceWorkerGlobalScope

// Take control immediately
self.skipWaiting()
clientsClaim()

// Precache and route
precacheAndRoute(self.__WB_MANIFEST)
cleanupOutdatedCaches()

// Navigation fallback
registerRoute(
    new NavigationRoute(
        new NetworkFirst({
            cacheName: 'pages-cache',
            plugins: [
                new CacheableResponsePlugin({ statuses: [0, 200] })
            ]
        })
    )
)

// Google Fonts caching
registerRoute(
    /^https:\/\/fonts\.googleapis\.com\/.*/i,
    new CacheFirst({
        cacheName: 'google-fonts-cache',
        plugins: [
            new ExpirationPlugin({ maxEntries: 10, maxAgeSeconds: 60 * 60 * 24 * 365 }),
            new CacheableResponsePlugin({ statuses: [0, 200] })
        ]
    }),
    'GET'
)

// CDN caching
registerRoute(
    /^https:\/\/cdnjs\.cloudflare\.com\/.*/i,
    new CacheFirst({
        cacheName: 'cdn-cache',
        plugins: [
            new ExpirationPlugin({ maxEntries: 20, maxAgeSeconds: 60 * 60 * 24 * 30 }),
            new CacheableResponsePlugin({ statuses: [0, 200] })
        ]
    }),
    'GET'
)

// ============================================
// PUSH NOTIFICATION HANDLERS
// ============================================

// Listen for push events
self.addEventListener('push', (event) => {
    if (!event.data) return

    try {
        const data = event.data.json()

        const options = {
            body: data.body || 'Nueva notificación de CareLink',
            icon: data.icon || '/icons/icon-192.png',
            badge: '/icons/icon-192.png',
            vibrate: [100, 50, 100],
            data: {
                url: data.url || '/',
                timestamp: data.timestamp || Date.now()
            },
            tag: 'carelink-notification',
            renotify: true,
            requireInteraction: false
        } as NotificationOptions & { vibrate?: number[] }

        event.waitUntil(
            self.registration.showNotification(data.title || 'CareLink', options)
        )
    } catch (error) {
        console.error('Error parsing push data:', error)
        // Fallback for plain text
        const text = event.data?.text() || 'Nueva notificación'
        event.waitUntil(
            self.registration.showNotification('CareLink', {
                body: text,
                icon: '/icons/icon-192.png'
            })
        )
    }
})

// Handle notification click
self.addEventListener('notificationclick', (event) => {
    event.notification.close()

    const urlToOpen = event.notification.data?.url || '/'

    event.waitUntil(
        self.clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then((clientList) => {
                // Check if there's already an open window
                for (const client of clientList) {
                    if (client.url.includes(self.location.origin) && 'focus' in client) {
                        client.navigate(urlToOpen)
                        return client.focus()
                    }
                }
                // Open new window if none found
                if (self.clients.openWindow) {
                    return self.clients.openWindow(urlToOpen)
                }
            })
    )
})

export { }
