<template>
  <Teleport to="body">
    <!-- Push Notification Permission Prompt -->
    <Transition name="slide-up">
      <div v-if="showPrompt" class="push-prompt-overlay">
        <div class="push-prompt-card animate-up">
          <div class="d-flex align-items-start gap-3">
            <div class="push-icon">
              <i class="fas fa-bell"></i>
            </div>
            <div class="flex-grow-1">
              <h6 class="fw-bold mb-1">Activar Notificaciones</h6>
              <p class="text-muted small mb-3">
                Recibe alertas de nuevas solicitudes, mensajes y anuncios importantes en tiempo real.
              </p>
              <div class="d-flex gap-2">
                <button 
                  class="btn btn-teal btn-sm rounded-pill px-3"
                  :disabled="isLoading"
                  @click="handleEnable"
                >
                  <i v-if="isLoading" class="fas fa-spinner fa-spin me-1"></i>
                  <i v-else class="fas fa-check me-1"></i>
                  Activar
                </button>
                <button 
                  class="btn btn-light btn-sm rounded-pill px-3"
                  @click="handleDismiss"
                >
                  Ahora no
                </button>
              </div>
            </div>
            <button class="btn-close" @click="handleDismiss" aria-label="Cerrar"></button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Success Toast -->
    <Transition name="fade">
      <div v-if="showSuccess" class="push-toast success">
        <i class="fas fa-check-circle me-2"></i>
        ¡Notificaciones activadas!
      </div>
    </Transition>

    <!-- Error Toast -->
    <Transition name="fade">
      <div v-if="showError" class="push-toast error">
        <i class="fas fa-exclamation-circle me-2"></i>
        {{ errorMessage }}
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
const { 
  isSupported, 
  isSubscribed, 
  isLoading, 
  permission,
  error,
  subscribe,
  checkSubscription 
} = usePushNotifications()

const showPrompt = ref(false)
const showSuccess = ref(false)
const showError = ref(false)
const errorMessage = ref('')
const dismissed = ref(false)

// Check if we should show the prompt
const shouldShowPrompt = computed(() => {
  return isSupported.value && 
         !isSubscribed.value && 
         permission.value !== 'denied' && 
         !dismissed.value
})

// Show prompt after a delay if conditions are met
onMounted(async () => {
  if (!import.meta.client) return
  
  // Check for previous dismissal
  const lastDismissed = localStorage.getItem('push_prompt_dismissed')
  if (lastDismissed) {
    const dismissedDate = new Date(lastDismissed)
    const daysSinceDismissed = (Date.now() - dismissedDate.getTime()) / (1000 * 60 * 60 * 24)
    // Don't show again for 7 days after dismissal
    if (daysSinceDismissed < 7) {
      dismissed.value = true
      return
    }
  }

  // Wait for SW to be ready and check subscription
  await checkSubscription()
  
  // Show prompt after 3 seconds if not subscribed
  setTimeout(() => {
    if (shouldShowPrompt.value) {
      showPrompt.value = true
    }
  }, 3000)
})

const handleEnable = async () => {
  const subscription = await subscribe()
  
  if (subscription) {
    showPrompt.value = false
    showSuccess.value = true
    setTimeout(() => {
      showSuccess.value = false
    }, 3000)
  } else if (error.value) {
    errorMessage.value = error.value
    showError.value = true
    setTimeout(() => {
      showError.value = false
    }, 4000)
  }
}

const handleDismiss = () => {
  showPrompt.value = false
  dismissed.value = true
  localStorage.setItem('push_prompt_dismissed', new Date().toISOString())
}
</script>

<style scoped>
.push-prompt-overlay {
  position: fixed;
  bottom: 80px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1040;
  width: calc(100% - 24px);
  max-width: 420px;
}

.push-prompt-card {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-radius: 16px;
  padding: 16px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.5);
}

.push-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: linear-gradient(135deg, #008080 0%, #00a8a8 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 1.25rem;
  flex-shrink: 0;
}

.push-toast {
  position: fixed;
  bottom: 90px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1050;
  padding: 12px 20px;
  border-radius: 50px;
  font-size: 0.875rem;
  font-weight: 600;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

.push-toast.success {
  background: #10b981;
  color: white;
}

.push-toast.error {
  background: #ef4444;
  color: white;
}

/* Transitions */
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s ease;
}

.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(20px);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
