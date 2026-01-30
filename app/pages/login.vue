<template>
  <div class="vh-100 d-flex flex-column align-items-center justify-content-center p-3" style="background: radial-gradient(circle at top left, #f0f7f7 0%, #ffffff 100%);">
    <div class="card card-premium p-4 w-100 shadow-lg animate-up text-center" style="max-width: 400px; background: rgba(255,255,255,0.9); backdrop-filter: blur(12px); border: 1px solid rgba(255,255,255,0.5);">
        <div class="mb-4">
          <div class="bg-teal text-white rounded-circle d-inline-flex justify-content-center align-items-center shadow-sm mb-3 animate-pulse"
               style="width: 75px; height: 75px; font-size: 2.2rem;">
            <i class="fas fa-heartbeat"></i>
          </div>
          <h4 class="fw-bold text-dark mb-1">CareLink NexGen</h4>
          <p class="text-muted small">Plataforma de Asistencia Médica</p>
        </div>

        <ClientOnly>
          <form @submit.prevent="handleLogin">
            <div class="form-floating mb-3">
              <input type="email" id="logEmail" class="form-control" placeholder="nombre@ejemplo.com" required v-model="email">
              <label class="text-muted">Correo Electrónico</label>
            </div>
            <div class="form-floating mb-4">
              <input type="password" id="logPass" class="form-control" placeholder="Contraseña" required v-model="password">
              <label class="text-muted">Contraseña</label>
            </div>
            <button class="btn btn-teal w-100 py-3 rounded-3 shadow-sm" :disabled="loading">
              {{ loading ? 'VERIFICANDO...' : 'INICIAR SESIÓN' }}
            </button>
          </form>
        </ClientOnly>

        <div class="mt-4 text-center">
            <small class="text-muted x-small opacity-50 d-block mb-3">v11.5 | NexGen Prototype</small>
            
             <small style="font-size: 0.7rem; letter-spacing: 1px; color: #aaa;" class="text-uppercase fw-bold d-flex align-items-center justify-content-center gap-2">
                DESARROLLADO POR 
                <a href="https://nubliti.com" target="_blank" class="text-decoration-none d-flex align-items-center">
                    <img src="/logo-nubliti.png" alt="nubliTI" style="height: 16px; opacity: 0.8;" onerror="this.style.display='none'">
                </a>
            </small>
        </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({
  layout: false
})

const email = ref('')
const password = ref('')
const router = useRouter()
const supabase = useSupabaseClient()
const loading = ref(false)

const handleLogin = async () => {
  loading.value = true
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })
  
  if (error) {
    alert('Error: ' + error.message)
  } else {
    router.push('/')
  }
  loading.value = false
}
</script>

<style scoped>
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}
.animate-pulse {
  animation: pulse 2s infinite ease-in-out;
}
</style>
