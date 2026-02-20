export default defineNuxtRouteMiddleware((to) => {
    const user = useSupabaseUser()
    const { profile, loading } = useOrganization()

    // Public pages that don't require auth
    const publicPages = ['/login', '/register', '/forgot-password']

    if (!user.value && !publicPages.includes(to.path)) {
        return navigateTo('/login')
    }

    if (user.value && to.path === '/login') {
        return navigateTo('/')
    }

    // Optional: If user is logged in, but we still don't have a profile...
    // We rely on the composable to fetch it, but maybe we should wait here?
    // For now, let's just ensure we have basic auth check.
})
