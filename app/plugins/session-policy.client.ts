export default defineNuxtPlugin(() => {
    const supabase = useSupabaseClient()

    // Nombres por defecto de las cookies de Supabase
    const tokenName = 'sb-access-token'
    const refreshTokenName = 'sb-refresh-token'

    if (process.client) {
        const isPWA = window.matchMedia('(display-mode: standalone)').matches || (window.navigator as any).standalone === true

        // LOGIC:
        // If NOT PWA (Standard Browser), we want cookies to be "Session Cookies" (deleted on window close).
        // If PWA, we keep defaults (Persistent Cookies).

        if (!isPWA) {
            const makeSessionCookie = (name: string) => {
                // Leer el valor actual
                const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'))
                if (match) {
                    const value = match[2]
                    // Reescribir la cookie SIN 'max-age' ni 'expires', lo que la hace de sesión.
                    // Mantenemos path y secure.
                    // Nota: Al no poner expires, el navegador la borra al cerrar.
                    document.cookie = `${name}=${value}; path=/; samesite=lax; secure`
                }
            }

            // 1. Ejecutar al montar (por si ya hay cookies persistentes de una sesión anterior, las convertimos a sesión)
            // Usamos timeout para asegurar que el cliente de Supabase ya haya inicializado
            setTimeout(() => {
                makeSessionCookie(tokenName)
                makeSessionCookie(refreshTokenName)
            }, 1000)

            // 2. Ejecutar cada vez que cambie el estado (Login, Refresh Token)
            supabase.auth.onAuthStateChange((event, session) => {
                if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
                    setTimeout(() => {
                        makeSessionCookie(tokenName)
                        makeSessionCookie(refreshTokenName)
                    }, 500)
                }
            })
        }
    }
})
