<template>
    <div class="pb-5 mb-5" :class="{ 'menu-collapsed-padding': isMenuCollapsed }">
        <!-- TOP NAVBAR (Premium Gradient) -->
        <nav class="navbar text-white shadow-sm sticky-top px-3 pb-2 pt-2" style="background: var(--teal-gradient);">
            <div class="d-flex align-items-center">
                <div class="bg-white text-teal rounded-circle d-flex justify-content-center align-items-center shadow-sm me-2"
                    style="width:38px;height:38px; font-weight:bold;">
                    <i class="fas fa-heartbeat"></i>
                </div>
                <div style="line-height:1.2">
                    <div class="fw-bold small">{{ profile?.full_name || 'Cargando...' }}</div>
                    
                    <div class="badge bg-white text-teal shadow-xs x-small" style="font-size:0.55rem; letter-spacing:1px; text-transform:uppercase;">
                        {{ profile?.role || 'User' }}
                    </div>
                </div>
            </div>
            <div class="d-flex align-items-center">
                <div class="text-white me-3 d-none d-sm-block small opacity-75 fw-bold">
                    {{ organizationName }}
                </div>
                <button class="btn btn-sm text-white opacity-75 p-2" @click="logout" title="Cerrar Sesión">
                    <i class="fas fa-sign-out-alt fa-lg"></i>
                </button>
            </div>
        </nav>

        <main class="container mt-3 animate-up pb-5" style="min-height: 80vh; position: relative;">
            <slot />
            
            <div class="text-center py-5 mt-5">
                <small style="font-size: 0.8rem; letter-spacing: 1px; color: #aaa;" class="text-uppercase fw-bold d-flex align-items-center justify-content-center gap-2">
                    DESARROLLADO POR 
                    <a href="https://nubliti.com" target="_blank" class="text-decoration-none d-flex align-items-center">
                        <img src="/logo-nubliti.png" alt="nubliTI" style="height: 20px; opacity: 0.8;" onerror="this.onerror=null;this.src='https://nubliti.com/logo.png'">
                    </a>
                </small>
            </div>
        </main>

        <!-- BOTTOM NAV (Glassmorphism + Role Based) -->
        <div v-if="isAdmin" class="menu-toggle-container fixed-bottom d-flex justify-content-center" :class="{ 'collapsed': isMenuCollapsed }">
            <button class="btn btn-teal btn-sm rounded-pill shadow-sm px-3 py-1 mb-2 toggle-btn" @click="isMenuCollapsed = !isMenuCollapsed">
                <i class="fas" :class="isMenuCollapsed ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
                <span class="ms-2 x-small fw-bold">{{ isMenuCollapsed ? 'Mostrar Menú' : 'Contraer' }}</span>
            </button>
        </div>

        <nav class="navbar fixed-bottom glass-nav py-1 shadow-lg transition-transform" :class="{ 'menu-collapsed': isMenuCollapsed }">
            <div class="container-fluid d-flex justify-content-around align-items-center px-1">
                <NuxtLink v-if="isAdmin || isPatrocinador" to="/" class="nav-btn text-center text-decoration-none" active-class="active">
                    <div class="nav-icon-container"><i class="fas fa-house-user"></i></div>
                    Inicio
                </NuxtLink>
                <NuxtLink v-if="isAdmin || isAsistente" to="/solicitudes" class="nav-btn text-center text-decoration-none" active-class="active">
                    <div class="nav-icon-container"><i class="fas fa-notes-medical"></i></div>
                    Pedidos
                </NuxtLink>
                <NuxtLink v-if="isAdmin || isPatrocinador" to="/surtir" class="nav-btn text-center text-decoration-none" active-class="active">
                    <div class="nav-icon-container"><i class="fas fa-hand-holding-heart"></i></div>
                    Surtir
                </NuxtLink>
                <NuxtLink v-if="isAdmin || isAsistente" to="/chat" class="nav-btn text-center text-decoration-none" active-class="active">
                    <div class="nav-icon-container"><i class="fas fa-comments"></i></div>
                    Asuntos
                </NuxtLink>
                <NuxtLink v-if="isAdmin" to="/finanzas" class="nav-btn text-center text-decoration-none" active-class="active">
                    <div class="nav-icon-container"><i class="fas fa-chart-pie"></i></div>
                    Balance
                </NuxtLink>
                <NuxtLink v-if="isAdmin" to="/admin" class="nav-btn text-center text-decoration-none" active-class="active">
                    <div class="nav-icon-container"><i class="fas fa-user-shield"></i></div>
                    Admin
                </NuxtLink>
            </div>
        </nav>

        <!-- Push Notification Prompt (Client Only) -->
        <ClientOnly>
            <PushNotificationPrompt />
        </ClientOnly>
    </div>
</template>

<script setup lang="ts">
const { profile, organizationName, fetchProfile } = useOrganization()
const user = useSupabaseUser()
const supabase = useSupabaseClient()
const router = useRouter()

const isAdmin = computed(() => profile.value?.role === 'ADMIN')
const isAsistente = computed(() => ['ASISTENTE', 'ENFERMERO'].includes(profile.value?.role))
const isPatrocinador = computed(() => profile.value?.role === 'APORTADOR')

const isMenuCollapsed = useCookie('admin_menu_collapsed', { default: () => false })


const logout = async () => {
    await supabase.auth.signOut()
    router.push('/login')
}

// Watch user state to redirect if session is lost
watch(user, (u) => {
    if (!u) {
        router.push('/login')
    }
})

onMounted(async () => {
    if (!user.value) {
        // Double check if we are on a protected route (handled by middleware usually, but layout is a safety net)
        if (router.currentRoute.value.path !== '/login') {
            router.push('/login')
        }
    } else {
        const fetchedProfile = await fetchProfile()
        
        // If fetchProfile returns null (because error/ghost session), useOrganization logic handles logout, 
        // but we can double check here
        if (!fetchedProfile && !profile.value) {
            console.warn('Layout: Profile failed to load. Redirecting...')
            await logout()
            return
        }

        // Logical redirection based on access if landing on non-accessible home
        if (isAsistente.value && router.currentRoute.value.path === '/') {
            router.push('/solicitudes')
        }
    }
})
</script>

<style scoped>
/* Scoped styles if any, mostly handled by main.scss */
</style>
