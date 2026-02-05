<template>
  <div class="container-fluid px-0 h-100">
    <div class="row h-100 justify-content-center">
        <div class="col-lg-10 mb-5 pb-5"> 
            <!-- Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 pt-3 border-bottom pb-3">
                <div>
                   <h5 class="text-teal fw-bold mb-0"><i class="fas fa-notes-medical me-2"></i>PEDIDOS DE INSUMOS</h5>
                   <small class="text-muted">Gestiona las necesidades del centro.</small>
                </div>
                <!-- Only Admins and Assistants can create -->
                <button class="btn btn-teal rounded-pill px-3 shadow-sm" @click="openRequestModal">
                    <i class="fas fa-plus me-1"></i> Nueva Solicitud
                </button>
            </div>

            <!-- Filters -->
            <div class="d-flex gap-2 mb-4 overflow-auto pb-2">
                <button class="btn btn-sm rounded-pill fw-bold" 
                    :class="filterStatus === 'ALL' ? 'btn-teal' : 'btn-light text-muted'"
                    @click="filterStatus = 'ALL'">
                    Todos
                </button>
                <button class="btn btn-sm rounded-pill fw-bold" 
                    :class="filterStatus === 'PENDIENTE' ? 'btn-warning text-dark' : 'btn-light text-muted'"
                    @click="filterStatus = 'PENDIENTE'">
                    Pendientes
                </button>
                <button class="btn btn-sm rounded-pill fw-bold" 
                    :class="filterStatus === 'APROBADO' ? 'btn-success text-white' : 'btn-light text-muted'"
                    @click="filterStatus = 'APROBADO'">
                    Aprobados
                </button>
            </div>

            <!-- Request List -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>

            <div v-else class="row g-3">
                <div v-for="req in filteredRequests" :key="req.id" class="col-md-6 col-xl-4">
                    <div class="card h-100 border-0 shadow-sm animate-up card-hover" :class="{'border-start border-5 border-warning': req.status === 'PENDIENTE', 'border-start border-5 border-success': req.status === 'APROBADO'}">
                         <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <span class="badge rounded-pill fw-normal" 
                                    :class="req.category_obj ? 'bg-primary-subtle text-primary' : 'bg-light text-muted'">
                                    {{ req.category_obj?.name || 'General' }}
                                </span>
                                <div class="d-flex gap-1">
                                    <span v-if="req.visibility === 'PRIVADA'" class="badge bg-secondary rounded-pill"><i class="fas fa-lock"></i></span>
                                    <span class="badge rounded-pill" :class="getStatusBadgeClass(req.status)">
                                        {{ req.status }}
                                    </span>
                                </div>
                            </div>

                            <div class="d-flex gap-3 mb-3">
                                <div v-if="req.image_url" class="flex-shrink-0">
                                    <div class="bg-light rounded d-flex align-items-center justify-content-center overflow-hidden" style="width: 70px; height: 70px;">
                                        <img :src="req.image_url" class="w-100 h-100 object-fit-cover" @click="viewImage(req.image_url)" style="cursor: zoom-in;">
                                    </div>
                                </div>
                                <div>
                                    <h6 class="fw-bold mb-1 text-dark">{{ req.item }}</h6>
                                    <div class="text-muted small">Cant: <span class="fw-bold text-teal">{{ req.quantity }}</span></div>
                                    <div v-if="isAdmin && req.estimated_unit_cost > 0" class="text-muted small">Est: ${{ req.estimated_unit_cost }} c/u</div>
                                </div>
                            </div>
                            
                            <p v-if="req.comments" class="text-muted small mb-3 fst-italic border-start ps-2">"{{ req.comments }}"</p>

                            <div class="d-flex justify-content-between align-items-center mt-auto pt-3 border-top">
                                <small class="text-muted x-small">
                                    <i class="far fa-user me-1"></i> {{ req.requester_obj?.full_name || 'Usuario' }}
                                    <br>
                                    <i class="far fa-calendar me-1"></i> {{ new Date(req.created_at).toLocaleDateString() }}
                                </small>
                                
                                <!-- Admin Actions -->
                                <div v-if="isAdmin" class="d-flex gap-2">
                                     <button v-if="req.status === 'PENDIENTE'" 
                                        class="btn btn-sm btn-outline-success rounded-pill px-3"
                                        @click="openApproveModal(req)">
                                        <i class="fas fa-check me-1"></i> Revisar
                                     </button>
                                     
                                     <button v-if="req.status === 'APROBADO'" 
                                        class="btn btn-sm btn-outline-warning rounded-pill px-3" 
                                        @click="returnToPending(req)">
                                        <i class="fas fa-undo me-1"></i> Desaprobar
                                     </button>

                                     <button class="btn btn-sm btn-light text-danger rounded-circle" 
                                        title="Eliminar Solicitud"
                                        @click="deleteRequest(req)">
                                        <i class="fas fa-trash"></i>
                                     </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div v-if="filteredRequests.length === 0" class="col-12 text-center py-5">
                    <div class="opacity-25 mb-3"><i class="fas fa-clipboard-list fa-3x"></i></div>
                    <p class="text-muted">No se encontraron solicitudes con este filtro.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL NUEVA/EDITAR SOLICITUD -->
    <div v-if="showModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content rounded-4 border-0 shadow">
                <div class="modal-header border-0 pb-0">
                    <h5 class="fw-bold text-teal">{{ isApproving ? 'Revisar y Aprobar' : 'Nueva Solicitud' }}</h5>
                    <button type="button" class="btn-close" @click="closeModal"></button>
                </div>
                <div class="modal-body p-4">
                    <form @submit.prevent="handleSubmit">
                        <div class="row g-3">
                            <!-- Left Col: Basic Info -->
                            <div class="col-md-6">
                                <div class="mb-3">
                                    <label class="form-label small text-muted fw-bold">Artículo / Insumo *</label>
                                    <input v-model="form.item" type="text" class="form-control" required placeholder="Ej. Paracetamol 500mg" list="item-history" @change="onItemSelect">
                                    <datalist id="item-history">
                                        <option v-for="(h, i) in historicalItems" :key="i" :value="h.item"></option>
                                    </datalist>
                                </div>
                                <div class="row">
                                    <div class="col-6 mb-3">
                                        <label class="form-label small text-muted fw-bold">Cantidad *</label>
                                        <input v-model="form.quantity" type="number" min="1" class="form-control" required>
                                    </div>
                                    <!-- Cost only required/visible for Admin in Approval mode, or optional during creation -->
                                    <div class="col-6 mb-3" v-if="isAdmin || isApproving">
                                        <label class="form-label small text-muted fw-bold">Costo Est. (Unit)</label>
                                        <div class="input-group">
                                            <span class="input-group-text bg-light">$</span>
                                            <input v-model="form.estimated_unit_cost" type="number" min="0" step="0.01" class="form-control">
                                        </div>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small text-muted fw-bold">Categoría *</label>
                                    <select v-model="form.category_id" class="form-select text-capitalize" required>
                                        <option value="" disabled>Selecciona...</option>
                                        <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                                        <option value="NEW_CATEGORY">+ Crear Nueva...</option>
                                    </select>
                                    <!-- Input for New Category -->
                                    <div v-if="form.category_id === 'NEW_CATEGORY'" class="mt-2 animate-up">
                                        <input v-model="newCategoryName" type="text" class="form-control form-control-sm border-teal" placeholder="Nombre de nueva categoría" required>
                                    </div>
                                </div>
                                
                                <!-- Visibility Toggle (Only Approval) -->
                                <div v-if="isApproving" class="mb-3 p-3 bg-light rounded">
                                    <label class="form-label small text-muted fw-bold d-block">Visibilidad Post-Aprobación</label>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" v-model="form.visibility" value="PUBLICA">
                                        <label class="form-check-label small">Pública (Todos)</label>
                                    </div>
                                    <div class="form-check form-check-inline">
                                        <input class="form-check-input" type="radio" v-model="form.visibility" value="PRIVADA">
                                        <label class="form-check-label small">Privada (Solo Admin)</label>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Right Col: Details & Image -->
                            <div class="col-md-6">
                                <div v-if="!isApproving" class="mb-3">
                                    <label class="form-label small text-muted fw-bold">Foto Referencia</label>
                                    <input type="file" @change="handleImage" accept="image/*" capture="environment" class="form-control">
                                    <div v-if="imagePreview || form.image_url" class="mt-2 text-center bg-light rounded p-2 position-relative">
                                         <button v-if="!isApproving" @click="removeImage" type="button" class="btn-close position-absolute top-0 end-0 m-2"></button>
                                         <img :src="imagePreview || form.image_url" class="rounded" style="max-height: 120px;">
                                    </div>
                                </div>
                                <!-- Only show image preview in Approve mode (read only basically) -->
                                <div v-else-if="form.image_url" class="mb-3 text-center bg-light rounded p-2">
                                     <label class="small text-muted d-block mb-1">Foto Adjunta</label>
                                     <img :src="form.image_url" class="rounded" style="max-height: 150px;">
                                </div>

                                <div class="mb-3">
                                    <label class="form-label small text-muted fw-bold">Comentarios</label>
                                    <textarea v-model="form.comments" class="form-control" rows="3" placeholder="Justificación o detalles..."></textarea>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label small text-muted fw-bold">Sugerencia Proveedor (Opcional)</label>
                                    <input v-model="form.suggested_provider" type="text" class="form-control" placeholder="Ej. Farmacia del Ahorro">
                                </div>
                            </div>
                        </div>

                        <div class="mt-4 d-flex justify-content-end gap-2 border-top pt-3">
                            <button type="button" class="btn btn-light" @click="closeModal">Cancelar</button>
                            
                            <!-- Actions based on Mode -->
                            <button v-if="isApproving" type="button" class="btn btn-success px-4" @click="approveRequest" :disabled="submitting">
                                <i class="fas fa-check-circle me-1"></i> {{ submitting ? 'Procesando...' : 'Confirmar Aprobación' }}
                            </button>
                            
                            <button v-else type="submit" class="btn btn-teal px-4" :disabled="submitting">
                                <i class="fas fa-paper-plane me-1"></i> {{ submitting ? 'Enviando...' : 'Crear Solicitud' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Image Modal Zoom -->
    <div v-if="zoomImage" class="modal d-block" style="background: rgba(0,0,0,0.85); z-index: 2000;" @click="zoomImage = null">
        <div class="modal-dialog modal-dialog-centered modal-xl">
            <div class="modal-content bg-transparent border-0 text-center">
                <img :src="zoomImage" class="img-fluid rounded shadow-lg" style="max-height: 90vh;">
            </div>
        </div>
    </div>

  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const { profile, organizationId } = useOrganization()
const { notifyNewRequest, sendNotification } = usePushNotificationSender() 

const isAdmin = computed(() => profile.value?.role === 'ADMIN')

// Data State
const requests = ref<any[]>([])
const categories = ref<any[]>([])
const historicalItems = ref<any[]>([])
const loading = ref(true)
const submitting = ref(false)

// UI State
const showModal = ref(false)
const filterStatus = ref('ALL') // ALL, PENDING, APPROVED
const isApproving = ref(false)
const zoomImage = ref<string | null>(null)
const newCategoryName = ref('')

// Form State
const form = reactive({
    id: null as string | null, // For edits
    item: '',
    quantity: 1,
    estimated_unit_cost: null as number | null,
    category_id: '',
    suggested_provider: '',
    related_link: '',
    comments: '',
    visibility: 'PUBLICA', // Default
    image_url: null as string | null,
    imageFile: null as File | null
})
const imagePreview = ref<string | null>(null)

// Computed
const filteredRequests = computed(() => {
    if (filterStatus.value === 'ALL') return requests.value
    return requests.value.filter(r => r.status === filterStatus.value)
})

// METHODS

const fetchMetadata = async () => {
    loading.value = true
    // 1. Fetch Categories
    const { data: cats } = await supabase.schema('app_carelink').from('categories').select('id, name')
    categories.value = cats || []

    // 2. Fetch Requests
    const { data: reqs, error } = await supabase.schema('app_carelink')
        .from('requests')
        .select(`
            *,
            category_obj:category_id(name),
            requester_obj:requester_id(full_name)
        `)
        .order('created_at', { ascending: false })
    
    if (error) {
        console.error('Error fetching requests', error)
        alert('Error cargando datos: ' + error.message)
        loading.value = false
        return
    }

    requests.value = reqs || []
    
    // Fetch History for Autocomplete
    await fetchHistory()

    loading.value = false
}

const fetchHistory = async () => {
    // Basic distinct emulation: fetch latest 200 requests to find unique items
    const { data } = await supabase.schema('app_carelink')
        .from('requests')
        .select('item, category_id, estimated_unit_cost, suggested_provider')
        .order('created_at', { ascending: false })
        .limit(200)

    if (data) {
        const map = new Map()
        data.forEach(d => {
            if (d.item && !map.has(d.item.toLowerCase())) {
                map.set(d.item.toLowerCase(), d)
            }
        })
        historicalItems.value = Array.from(map.values())
    }
}

const onItemSelect = () => {
    if (!form.item) return
    const match = historicalItems.value.find(h => h.item.toLowerCase() === form.item.toLowerCase())
    if (match) {
        // Auto-fill logic: only if field is empty or user wants suggestions
        if (!form.category_id && match.category_id) form.category_id = match.category_id
        if ((!form.estimated_unit_cost || form.estimated_unit_cost === 0) && match.estimated_unit_cost) form.estimated_unit_cost = match.estimated_unit_cost
        if (!form.suggested_provider && match.suggested_provider) form.suggested_provider = match.suggested_provider
    }
}

const returnToPending = async (req: any) => {
    if (!confirm('¿Estás seguro de regresar esta solicitud a estado PENDIENTE?')) return
    
    // Check if there are fulfillments? Ideally yes, but logic says "Requests should disappear if fully fulfilled".
    // If Admin disapproves, maybe we should warn if there are commitments.
    // Simplicity first: just update.
    
    const { error } = await supabase.schema('app_carelink')
        .from('requests')
        .update({ status: 'PENDIENTE', approved_by: null, approval_date: null })
        .eq('id', req.id)
    
    if (error) alert('Error: ' + error.message)
    else await fetchMetadata()
}

const openRequestModal = () => {
    isApproving.value = false
    resetForm()
    showModal.value = true
}

const openApproveModal = (req: any) => {
    if (!isAdmin.value) return
    isApproving.value = true
    // Fill Form
    form.id = req.id
    form.item = req.item
    form.quantity = req.quantity
    form.estimated_unit_cost = req.estimated_unit_cost
    form.category_id = req.category_id
    form.suggested_provider = req.suggested_provider
    form.related_link = req.related_link
    form.comments = req.comments
    form.visibility = req.visibility || 'PUBLICA'
    form.image_url = req.image_url
    showModal.value = true
}

const closeModal = () => {
    showModal.value = false
    resetForm()
}

const resetForm = () => {
    form.id = null
    form.item = ''
    form.quantity = 1
    form.estimated_unit_cost = null
    form.category_id = ''
    form.suggested_provider = ''
    form.related_link = ''
    form.comments = ''
    form.visibility = 'PUBLICA'
    form.image_url = null
    form.imageFile = null
    newCategoryName.value = ''
    imagePreview.value = null
}

const handleImage = (e: Event) => {
    const input = e.target as HTMLInputElement
    if (input.files?.[0]) {
        form.imageFile = input.files[0]
        imagePreview.value = URL.createObjectURL(input.files[0])
    }
}

const removeImage = () => {
    form.imageFile = null
    imagePreview.value = null
}

const handleSubmit = async () => {
    if (!organizationId.value) return
    submitting.value = true

    try {
        // Handle New Category Creation
        let finalCategoryId = form.category_id
        if (form.category_id === 'NEW_CATEGORY') {
            if (!newCategoryName.value.trim()) throw new Error('Escribe el nombre de la nueva categoría.')
            
            const { data: newCat, error: catError } = await supabase.schema('app_carelink')
                .from('categories')
                .insert({
                    organization_id: organizationId.value,
                    name: newCategoryName.value.trim()
                })
                .select()
                .single()
            
            if (catError) throw catError
            finalCategoryId = newCat.id
        }

        let imageUrl = form.image_url // Keep existing if needed

        // Upload new image if present
        if (form.imageFile) {
            const fileExt = form.imageFile.name.split('.').pop()
            const fileName = `req-${Date.now()}.${fileExt}`
            const { error: upErr } = await supabase.storage.from('requests').upload(fileName, form.imageFile)
            if (upErr) throw upErr
            
            const { data: publicUr } = supabase.storage.from('requests').getPublicUrl(fileName)
            imageUrl = publicUr.publicUrl
        }

        const payload = {
            organization_id: organizationId.value,
            item: form.item,
            category: 'REF', // Legacy column must be satisfied if not patched
            quantity: form.quantity,
            estimated_unit_cost: form.estimated_unit_cost || 0,
            category_id: finalCategoryId, 
            suggested_provider: form.suggested_provider,
            related_link: form.related_link,
            comments: form.comments,
            image_url: imageUrl,
            requester_id: profile.value.id,
            status: 'PENDIENTE',
            visibility: 'PUBLICA' 
        }

        const { error } = await supabase.schema('app_carelink').from('requests').insert(payload)
        if (error) throw error

        // 3.1 Notify Admins
        try {
            await notifyNewRequest(
                form.item, 
                profile.value?.full_name || 'Usuario', 
                profile.value?.id || '',
                organizationId.value
            )
        } catch (pushErr) {
            console.error('Push notification failed but request created:', pushErr)
        }

        await fetchMetadata()
        closeModal()

    } catch (e: any) {
        console.error('Error in handleSubmit:', e)
        const msg = e.message || (typeof e === 'object' ? JSON.stringify(e) : e)
        alert('Error: ' + msg)
    } finally {
        submitting.value = false
    }
}

const approveRequest = async () => {
    if (!form.id || !isAdmin.value) return
    submitting.value = true
    try {
        // Handle New Category Creation (Edge case if Admin changes category to New during approval)
        let finalCategoryId = form.category_id
        if (form.category_id === 'NEW_CATEGORY') {
             if (!newCategoryName.value.trim()) throw new Error('Escribe el nombre de la nueva categoría.')
             const { data: newCat, error: catError } = await supabase.schema('app_carelink')
                .from('categories')
                .insert({
                    organization_id: organizationId.value,
                    name: newCategoryName.value.trim()
                })
                .select()
                .single()
            if (catError) throw catError
            finalCategoryId = newCat.id
        }

        // Update fields + Status
        const { error } = await supabase.schema('app_carelink').from('requests').update({
            item: form.item,
            quantity: form.quantity,
            estimated_unit_cost: form.estimated_unit_cost,
            category_id: finalCategoryId,
            suggested_provider: form.suggested_provider,
            related_link: form.related_link,
            comments: form.comments,
            status: 'APROBADO',
            visibility: form.visibility, // Save Visibility Toggle
            approved_by: profile.value.id,
            approval_date: new Date().toISOString()
        }).eq('id', form.id)

        if (error) throw error
        await fetchMetadata()
        closeModal()
    } catch (e: any) {
         console.error('Error in approveRequest:', e)
         const msg = e.message || (typeof e === 'object' ? JSON.stringify(e) : e)
         alert('Error: ' + msg)
    } finally {
        submitting.value = false
    }
}

const getStatusBadgeClass = (status: string) => {
    switch (status) {
        case 'APROBADO': return 'bg-success text-white'
        case 'RECHAZADO': return 'bg-danger text-white'
        case 'PENDIENTE': return 'bg-warning text-dark'
        default: return 'bg-secondary text-white'
    }
}

const viewImage = (url: string) => {
    zoomImage.value = url
}

const deleteRequest = async (req: any) => {
    if (!confirm('¿Estás seguro de eliminar esta solicitud? Si ya tiene surtidos asociados, podría causar errores.')) return

    try {
        const { error } = await supabase.schema('app_carelink')
            .from('requests')
            .delete()
            .eq('id', req.id)
        
        if (error) throw error
        
        alert('Solicitud eliminada.')
        await fetchMetadata()
    } catch (e: any) {
        alert('Error: ' + e.message)
    }
}

onMounted(() => {
    fetchMetadata()
    fetchHistory()
})
</script>

<style scoped>
.card-hover:hover {
    transform: translateY(-2px);
    transition: all 0.2s ease;
}
</style>
