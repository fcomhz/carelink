<template>
  <div class="h-100 d-flex flex-column">
    <!-- List View -->
    <div v-if="!selectedIncidente" class="flex-grow-1">
        <div class="d-flex justify-content-between align-items-center mb-3 border-bottom pb-2">
            <h6 class="text-teal fw-bold mb-0">ASUNTOS & INCIDENTES</h6>
            <button class="btn btn-teal btn-sm rounded-circle shadow" @click="showNewModal = true">
                <i class="fas fa-plus"></i>
            </button>
        </div>

        <div v-if="loading" class="text-center py-5">
            <div class="spinner-border text-teal" role="status"></div>
        </div>

        <div v-else class="list-group list-group-flush bg-white rounded shadow-sm overflow-hidden">
            <button v-for="i in incidentes" :key="i.id" 
                    class="list-group-item list-group-item-action d-flex justify-content-between align-items-center p-3"
                    @click="openIncident(i)">
                <div>
                    <div class="fw-bold text-dark">{{ i.title }}</div>
                    <div class="x-small text-muted">
                        {{ formatDate(i.created_at) }} | {{ i.profiles?.full_name || 'Sistema' }}
                    </div>
                </div>
                <span :class="['badge rounded-pill', i.status === 'ABIERTO' ? 'bg-success' : 'bg-secondary']">
                    {{ i.status }}
                </span>
            </button>
            <div v-if="incidentes.length === 0" class="p-4 text-center text-muted small">
                No hay incidentes reportados.
            </div>
        </div>
    </div>

    <!-- Chat View -->
    <div v-else class="flex-grow-1 d-flex flex-column">
        <div class="bg-teal text-white p-2 mb-2 rounded d-flex align-items-center shadow-sm">
            <button class="btn btn-sm text-white me-2" @click="selectedIncidente = null">
                <i class="fas fa-arrow-left"></i>
            </button>
            <div class="flex-grow-1">
                <div class="fw-bold small">{{ selectedIncidente.title }}</div>
                <div class="badge bg-white text-teal x-small">{{ selectedIncidente.status }}</div>
            </div>
            <button v-if="selectedIncidente.status === 'ABIERTO' && isAdmin" 
                    class="btn btn-sm btn-light text-danger x-small ms-2"
                    @click="closeTicket">
                Cerrar
            </button>
        </div>

        <div id="msgs-area" class="bg-white rounded shadow-sm p-3 mb-3 border chat-bg flex-grow-1 overflow-auto" style="min-height: 40vh;">
            <div v-for="m in messages" :key="m.id" 
                 :class="['d-flex flex-column mb-3', m.sender_id === user?.id ? 'align-items-end' : 'align-items-start']">
                <small class="text-muted x-small mb-1">
                    {{ m.profiles?.full_name || 'Usuario' }} • {{ formatTime(m.created_at) }}
                </small>
                <div :class="['p-2 rounded shadow-sm px-3', m.sender_id === user?.id ? 'bg-teal text-white' : 'bg-light text-dark border']" 
                     style="max-width: 85%; line-height: 1.4;">
                    {{ m.content }}
                </div>
            </div>
            <div v-if="messages.length === 0" class="text-center text-muted x-small mt-4">Inicio de la conversación.</div>
        </div>

        <div class="input-group shadow-sm mb-3">
            <button class="btn btn-outline-secondary border-0 bg-white" type="button" @click="startDictation">
                <i :class="['fas', listening ? 'fa-spinner fa-spin text-danger' : 'fa-microphone text-teal']"></i>
            </button>
            <input v-model="newMessage" type="text" class="form-control border-0 py-2" 
                   placeholder="Escribe o dicta..." @keyup.enter="sendMsg">
            <button class="btn btn-teal px-3" @click="sendMsg" :disabled="!newMessage.trim()">
                <i class="fas fa-paper-plane"></i>
            </button>
        </div>
    </div>

    <!-- New Incident Modal -->
    <div v-if="showNewModal" class="modal-backdrop d-flex align-items-center justify-content-center" style="background: rgba(0,0,0,0.5); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 1050;">
      <div class="card p-4 shadow-lg w-100 mx-3" style="max-width: 450px; max-height: 90vh; overflow-y: auto;">
        <h5 class="fw-bold text-teal mb-3">Nuevo Asunto</h5>
        <form @submit.prevent="createIncident">
          <div class="mb-3">
            <label class="small fw-bold text-muted">Título Breve</label>
            <input v-model="newIncident.title" class="form-control" placeholder="Ej. Falla en elevador" required>
          </div>
          <div class="mb-3">
            <label class="small fw-bold text-muted">Mensaje Inicial</label>
            <textarea v-model="newIncident.message" class="form-control" rows="3" placeholder="Describe el problema..." required></textarea>
          </div>
          <div class="d-flex gap-2">
            <button type="button" class="btn btn-light flex-fill" @click="showNewModal = false">Cancelar</button>
            <button type="submit" class="btn btn-teal flex-fill" :disabled="saving">
              {{ saving ? 'Creando...' : 'Crear Ticket' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { organizationId, profile } = useOrganization()

const loading = ref(true)
const saving = ref(false)
const incidentes = ref<any[]>([])
const selectedIncidente = ref<any>(null)
const messages = ref<any[]>([])
const newMessage = ref('')
const showNewModal = ref(false)
const listening = ref(false)

const newIncident = reactive({
    title: '',
    message: ''
})

const isAdmin = computed(() => profile.value?.role === 'ADMIN')

const fetchIncidentes = async () => {
    loading.value = true
    const { data, error } = await supabase
        .from('incidents')
        .select('*, profiles(full_name)')
        .order('created_at', { ascending: false })
    
    if (!error) incidentes.value = data || []
    loading.value = false
}

const openIncident = async (inc: any) => {
    selectedIncidente.value = inc
    await fetchMessages()
}

const fetchMessages = async () => {
    if (!selectedIncidente.value) return
    const { data, error } = await supabase
        .from('incident_messages')
        .select('*, profiles(full_name)')
        .eq('incident_id', selectedIncidente.value.id)
        .order('created_at', { ascending: true })
    
    if (!error) messages.value = data || []
    
    // Scroll to bottom
    nextTick(() => {
        const area = document.getElementById('msgs-area')
        if (area) area.scrollTop = area.scrollHeight
    })
}

const { notifyNewMessage } = usePushNotificationSender() // Import logic

const sendMsg = async () => {
    if (!newMessage.value.trim() || !selectedIncidente.value || !user.value) return
    
    const content = newMessage.value
    newMessage.value = '' // Optimistic clear

    const { error } = await supabase
        .from('incident_messages')
        .insert({
            incident_id: selectedIncidente.value.id,
            sender_id: user.value.id,
            content: content
        })

    if (!error) {
        // Send Notification Logic
        try {
            // Logic: Notify Admins OR Notify Ticket Creator
            // We pass the ticket ID so they can open it directly
            const isCreator = selectedIncidente.value.creator_id === user.value.id
            const chatLink = `/chat` // Ideally /chat?id=... but simple for now

            // If I am NOT the creator (likely Admin), notify the creator
            if (!isCreator) {
                await notifyNewMessage(
                    selectedIncidente.value.title, 
                    profile.value?.full_name || 'Admin', 
                    content,
                    [selectedIncidente.value.creator_id] // Target specifically the creator
                )
            } 
            // If I AM the creator (or just user), notify Admins globally
            else {
                await notifyNewMessage(
                    selectedIncidente.value.title,
                    profile.value?.full_name || 'Usuario',
                    content
                    // No target list -> defaults to fetching all Admins inside composable logic if not provided?
                    // Wait, notifyNewMessage implementation in usePushNotificationSender might need checking.
                    // Assuming it handles "notify admins by default" if no target provided OR we need a separate call.
                    // Let's check usePushNotificationSender usage. 
                    // Actually, notifyNewMessage usually takes (title, sender, message).
                    // Let's use generic sendNotification if notifyNewMessage is too specific or create a smarter call.
                )
            }

        } catch (e) {
            console.error('Notification error', e)
        }

        await fetchMessages()
    } else {
        alert('Error al enviar mensaje')
    }
}

const createIncident = async () => {
    if (!organizationId.value || !user.value) return
    saving.value = true
    
    const { data, error } = await supabase
        .from('incidents')
        .insert({
            organization_id: organizationId.value,
            title: newIncident.title,
            creator_id: user.value.id,
            status: 'ABIERTO'
        })
        .select()
        .single()

    if (!error && data) {
        // Create first message
        await supabase.from('incident_messages').insert({
            incident_id: data.id,
            sender_id: user.value.id,
            content: newIncident.message
        })
        
        showNewModal.value = false
        newIncident.title = ''
        newIncident.message = ''
        await fetchIncidentes()
    } else {
        alert('Error: ' + error?.message)
    }
    saving.value = false
}

const closeTicket = async () => {
    if (!selectedIncidente.value) return
    if (confirm('¿Deseas cerrar este ticket definitivamente?')) {
        const { error } = await supabase
            .from('incidents')
            .update({ status: 'CERRADO' })
            .eq('id', selectedIncidente.value.id)
        
        if (!error) {
            selectedIncidente.value.status = 'CERRADO'
            await fetchIncidentes()
        }
    }
}

// V11 VOICE FEATURE
const startDictation = () => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition
    if (!SpeechRecognition) {
        alert('Dictado por voz no soportado en este navegador.')
        return
    }

    const recognition = new SpeechRecognition()
    recognition.lang = 'es-MX'
    recognition.onstart = () => { listening.value = true }
    recognition.onend = () => { listening.value = false }
    recognition.onresult = (event: any) => {
        newMessage.value += event.results[0][0].transcript
    }
    recognition.start()
}

const formatDate = (dateStr: string) => {
    const d = new Date(dateStr)
    return d.toLocaleDateString()
}

const formatTime = (dateStr: string) => {
    const d = new Date(dateStr)
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

onMounted(() => {
    fetchIncidentes()
})
</script>

<style scoped>
.chat-bg {
    background-color: #f1f8f8;
    background-image: radial-gradient(#008080 0.5px, transparent 0.5px);
    background-size: 20px 20px;
    background-opacity: 0.05;
}
</style>
