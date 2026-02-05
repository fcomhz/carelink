<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-2">
        <h6 class="text-teal fw-bold mb-0">LISTA DE NECESIDADES</h6>
        <!-- DONATION BUTTON FOR SPONSORS -->
        <button v-if="isPatrocinador || isAdmin" 
            class="btn btn-warning rounded-pill px-3 fw-bold shadow-sm animate-pulse"
            @click="openDonationModal">
            <i class="fas fa-hand-holding-usd me-1"></i> Donar Dinero
        </button>
    </div>

    <div class="alert alert-light small border-start border-4 border-teal text-muted shadow-sm mb-4">
        <i class="fas fa-hand-holding-heart me-1"></i> 
        Ayuda surtiendo estos insumos o realizando una aportación económica directa.
    </div>

    <!-- TABS -->
    <ul class="nav nav-pills mb-4">
        <li class="nav-item">
            <button class="nav-link rounded-pill px-4" 
                :class="{ active: activeTab === 'needs' }"
                @click="activeTab = 'needs'">
                Necesidades Activas
            </button>
        </li>
        <li class="nav-item">
            <button class="nav-link rounded-pill px-4" 
                :class="{ active: activeTab === 'commits' }"
                @click="activeTab = 'commits'">
                Mis Compromisos
            </button>
        </li>
    </ul>

    <div class="tab-content">
        <!-- TAB 1: NEEDS -->
        <div v-if="activeTab === 'needs'" class="fade show active">
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>
            
            <div v-else class="row g-2">
                <div v-for="req in requests" :key="req.id" class="col-12">
                    <div class="card border-0 shadow-sm p-3">
                        <div class="d-flex justify-content-between align-items-start">
                            <div class="flex-grow-1">
                                <div class="d-flex align-items-center gap-2 mb-2">
                                    <strong class="text-teal">{{ req.item }}</strong>
                                    <span v-if="req.category_obj" class="badge bg-light text-muted border">{{ req.category_obj.name }}</span>
                                </div>
                                
                                <!-- Quantity Progress -->
                                <div class="small text-muted mb-2">
                                    <div class="d-flex align-items-center gap-2">
                                        <span>Faltan: <strong class="text-danger">{{ req.remaining_quantity }}</strong> / {{ req.quantity }}</span>
                                        <div class="progress" style="height: 6px; width: 100px;">
                                            <div class="progress-bar bg-teal" role="progressbar" 
                                                :style="{ width: ((req.committed_quantity / req.quantity) * 100) + '%' }"></div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Cost Information -->
                                <div v-if="req.estimated_unit_cost && req.estimated_unit_cost > 0" class="mb-2">
                                    <div class="d-flex gap-3 small">
                                        <div class="text-muted">
                                            <i class="fas fa-tag me-1"></i>
                                            Costo unitario: <strong class="text-dark">${{ req.estimated_unit_cost.toFixed(2) }}</strong>
                                        </div>
                                        <div class="text-success fw-bold">
                                            <i class="fas fa-calculator me-1"></i>
                                            Total estimado: ${{ (req.remaining_quantity * req.estimated_unit_cost).toFixed(2) }}
                                        </div>
                                    </div>
                                </div>

                                <!-- Suggested Provider -->
                                <div v-if="req.suggested_provider" class="small text-muted mb-2">
                                    <i class="fas fa-store me-1"></i>
                                    <strong>Proveedor sugerido:</strong> {{ req.suggested_provider }}
                                </div>

                                <!-- Comments -->
                                <div v-if="req.comments" class="small text-muted fst-italic border-start border-2 border-teal ps-2">
                                    "{{ req.comments }}"
                                </div>
                            </div>
                            
                            <div class="text-end ms-3">
                                <button class="btn btn-teal btn-sm rounded-pill px-3 shadow-sm" @click="openSurtirModal(req)">
                                    <i class="fas fa-box-open me-1"></i> Yo lo surto
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div v-if="requests.length === 0" class="text-center py-5 text-muted">
                    <i class="fas fa-check-circle fa-2x mb-3 opacity-25"></i>
                    <p>¡Por el momento no hay necesidades pendientes!</p>
                </div>
            </div>
        </div>

        <!-- TAB 2: MY COMMITMENTS -->
        <div v-if="activeTab === 'commits'" class="fade show active">
            <!-- ADMIN TOGGLE -->
            <div v-if="isAdmin" class="d-flex justify-content-end mb-3">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" id="flexSwitchCheckDefault" v-model="showAllCommits" @change="fetchMyCommits">
                    <label class="form-check-label small fw-bold text-muted" for="flexSwitchCheckDefault">Ver compromisos de todos</label>
                </div>
            </div>

            <div v-if="loadingCommits" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>
            <div v-else class="row g-2">
                <div v-for="c in myCommits" :key="c.id" class="col-12">
                     <div class="card border-0 shadow-sm p-3">
                         <div class="d-flex justify-content-between align-items-center">
                             <div>
                                 <strong class="text-dark">{{ c.request.item }}</strong>
                                 <div class="small text-muted">
                                     Compromiso: <strong>{{ c.quantity }} unidades</strong>
                                     <span class="mx-1">|</span>
                                     Entrega: {{ c.delivery_date || 'Sin fecha' }}
                                 </div>
                                 <div class="x-small text-muted mt-1">
                                     <i class="fas fa-map-marker-alt me-1"></i> {{ c.center?.name || 'Centro no especificado' }}
                                 </div>
                                 <div v-if="c.user_profile" class="mt-2">
                                    <span class="badge bg-light text-dark border">
                                        <i class="fas fa-user me-1 text-muted"></i> {{ c.user_profile.full_name || c.user_profile.email }}
                                    </span>
                                 </div>
                             </div>
                             <div>
                                 <span :class="['badge', c.status === 'PENDIENTE' ? 'bg-warning text-dark' : 'bg-success']">
                                     {{ c.status }}
                                 </span>
                             </div>
                         </div>
                     </div>
                 </div>
                 <div v-if="myCommits.length === 0" class="text-center py-5 text-muted">
                    <p>No tienes compromisos activos.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL SURTIR -->
    <div v-if="showModal" class="modal-backdrop d-flex align-items-center justify-content-center" style="background: rgba(0,0,0,0.5); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 1060;">
        <div class="card p-4 shadow-lg w-100 mx-3 animate-up" style="max-width: 450px;">
            <h5 class="fw-bold text-teal mb-3">Compromiso de Surtido</h5>
            
            <div class="alert alert-info small py-2 mb-3">
                Estás comprometiéndote a surtir: <strong>{{ selectedReq?.item }}</strong>
            </div>

            <form @submit.prevent="saveCommitment">
                <div class="mb-3">
                    <label class="small fw-bold text-muted">¿Cuántas unidades entregarás?</label>
                    <input type="number" v-model="form.quantity" class="form-control" min="1" :max="selectedReq?.remaining_quantity" required>
                    <div class="form-text x-small">Faltan por surtir: {{ selectedReq?.remaining_quantity }}</div>
                </div>

                <div class="mb-3">
                    <label class="small fw-bold text-muted">Centro de Acopio (Entrega)</label>
                    <select v-model="form.collection_center_id" class="form-select" required>
                        <option value="" disabled>Selecciona un lugar...</option>
                        <option v-for="center in centers" :key="center.id" :value="center.id">
                            {{ center.name }} ({{ center.schedule }})
                        </option>
                    </select>
                    <div v-if="centers.length === 0" class="form-text text-danger x-small">
                        No hay centros activos. Contacta al administrador.
                    </div>
                </div>

                <div class="mb-3">
                    <label class="small fw-bold text-muted">Fecha Estimada de Entrega</label>
                    <input type="date" v-model="form.delivery_date" class="form-control" required>
                </div>

                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-light flex-fill" @click="showModal = false">Cancelar</button>
                    <button type="submit" class="btn btn-teal flex-fill" :disabled="submitting">
                        {{ submitting ? 'Confirmando...' : 'Confirmar Compromiso' }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- MODAL DONACIÓN -->
    <div v-if="showDonationModal" class="modal d-block" style="background: rgba(0,0,0,0.5); z-index: 1070;">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0 bg-teal text-white rounded-top-4">
                    <h5 class="fw-bold mb-0"><i class="fas fa-hand-holding-usd me-2"></i>Datos para Donativos</h5>
                    <button type="button" class="btn-close btn-close-white" @click="showDonationModal = false"></button>
                </div>
                <div class="modal-body p-4 bg-light">
                    <p class="text-center text-muted small mb-4">
                        Gracias por tu generosidad. Puedes realizar tu aportación a cualquiera de las siguientes cuentas:
                    </p>

                    <div v-if="loadingBanks" class="text-center py-4">
                        <div class="spinner-border text-teal" role="status"></div>
                    </div>

                    <div v-else-if="bankAccounts.length === 0" class="text-center py-4 text-muted">
                        <i class="fas fa-university fa-2x mb-3 opacity-25"></i>
                        <p>No hay cuentas bancarias configuradas por el momento.</p>
                    </div>

                    <div v-else class="d-flex flex-column gap-3">
                        <div v-for="acc in bankAccounts" :key="acc.id" class="card border-0 shadow-sm">
                            <div class="card-body">
                                <h6 class="fw-bold text-teal mb-2">{{ acc.bank_name }}</h6>
                                <div class="small text-muted mb-1">BENEFICIARIO: <strong class="text-dark">{{ acc.beneficiary }}</strong></div>
                                <div class="d-flex justify-content-between align-items-center bg-light p-2 rounded mb-2">
                                    <span class="small text-muted">CLABE:</span>
                                    <span class="user-select-all fw-bold font-monospace">{{ acc.clabe }}</span>
                                </div>
                                <div class="d-flex justify-content-between align-items-center bg-light p-2 rounded">
                                    <span class="small text-muted">CUENTA:</span>
                                    <span class="user-select-all fw-bold font-monospace">{{ acc.account_number }}</span>
                                </div>
                                <div v-if="acc.notes" class="mt-2 text-muted x-small fst-italic">
                                    Nota: {{ acc.notes }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer border-0 bg-light rounded-bottom-4 justify-content-center">
                    <button class="btn btn-outline-secondary rounded-pill px-4" @click="showDonationModal = false">Cerrar</button>
                </div>
            </div>
        </div>
    </div>

  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { organizationId, profile } = useOrganization()
const { notifyRequestCompromised } = usePushNotificationSender()
// Importar composable de bancos
const { bankAccounts, loading: loadingBanks, fetchBankAccounts } = useBankInfo()

const activeTab = ref('needs')
const requests = ref<any[]>([])
const myCommits = ref<any[]>([])
const centers = ref<any[]>([])
const loading = ref(true)
const loadingCommits = ref(false)

// MODAL SURTIR STATE
const showModal = ref(false)
const submitting = ref(false)
const selectedReq = ref<any>(null)
const form = reactive({
    quantity: 1,
    collection_center_id: '',
    delivery_date: ''
})

// MODAL DONACIÓN STATE
const showDonationModal = ref(false)
const openDonationModal = async () => {
    showDonationModal.value = true
    if (bankAccounts.value.length === 0) {
        await fetchBankAccounts()
    }
}

// Computed Roles
const isAdmin = computed(() => {
    return user.value?.app_metadata?.role === 'ADMIN' || user.value?.user_metadata?.role === 'ADMIN' || profile.value?.role === 'ADMIN'
})

const isPatrocinador = computed(() => {
    return isAdmin.value || profile.value?.role === 'APORTADOR'
})

// FETCH DATA
const fetchData = async () => {
    loading.value = true
    
    // 1. Fetch Requests 
    const { data: reqs } = await supabase.schema('app_carelink')
        .from('requests')
        .select(`*, category_obj:category_id(name)`)
        .eq('status', 'APROBADO')
        .order('created_at', { ascending: false })
    
    // 2. Fetch Centers
    const { data: ctrs } = await supabase.schema('app_carelink')
        .from('collection_centers')
        .select('*')
        .eq('active', true)
    centers.value = ctrs || []

    // 3. Fetch ALL Fulfillments to calc remaining quantity
    const { data: allFulfills } = await supabase.schema('app_carelink')
        .from('fulfillments')
        .select('request_id, quantity')
        .neq('status', 'CANCELADO') // Don't count cancelled
    
    // Process remaining
    if (reqs && allFulfills) {
        requests.value = reqs.map(r => {
            const committed = allFulfills
                .filter(f => f.request_id === r.id)
                .reduce((sum, f) => sum + Number(f.quantity), 0)
            
            return {
                ...r,
                committed_quantity: committed,
                remaining_quantity: Math.max(0, r.quantity - committed)
            }
        }).filter(r => r.remaining_quantity > 0) // Hide fully fulfilled? Or show as completed? Let's hide for now or show distinct.
    } else {
        requests.value = reqs || []
    }

    loading.value = false
}

// Toggle for Admin to view all
const showAllCommits = ref(false)

const fetchMyCommits = async () => {
    // Robust User ID Get
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    if (!currentUser) return;
    
    loadingCommits.value = true
    
    let query = supabase.schema('app_carelink')
        .from('fulfillments')
        .select(`
            *,
            request:request_id(item),
            center:collection_center_id(name),
            user_profile:user_id(full_name, email)
        `)
        .order('created_at', { ascending: false })

    // If NOT (Admin checking 'All'), filter by my ID
    if (!isAdmin.value || !showAllCommits.value) {
        query = query.eq('user_id', currentUser.id)
    }
    
    const { data } = await query
    
    myCommits.value = data || []
    loadingCommits.value = false
    console.log('Commits fetched:', myCommits.value)
}

// ACTIONS
const openSurtirModal = (req: any) => {
    selectedReq.value = req
    form.quantity = req.remaining_quantity // Default to remaining amount
    form.collection_center_id = centers.value.length > 0 ? centers.value[0].id : ''
    // Default date: tomorrow
    const tmr = new Date()
    tmr.setDate(tmr.getDate() + 1)
    form.delivery_date = tmr.toISOString().split('T')[0]
    
    showModal.value = true
}

const saveCommitment = async () => {
    // Force get user ID just in case reactive 'user' is stale
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    
    if (!currentUser || !selectedReq.value) {
        alert('Error: No se pudo identificar al usuario. Por favor recarga e inicia sesión.')
        return
    }

    submitting.value = true
    
    // Explicitly construct payload with user_id
    const payload = {
        request_id: selectedReq.value.id,
        user_id: currentUser.id, // CRITICAL FIX: Ensure this is not undefined
        collection_center_id: form.collection_center_id,
        quantity: form.quantity,
        delivery_date: form.delivery_date,
        status: 'PENDIENTE'
    }

    console.log('Sending payload:', payload)

    const { error } = await supabase.schema('app_carelink')
        .from('fulfillments')
        .insert(payload)

    if (error) {
        alert('Error al guardar compromiso: ' + error.message)
    } else {
        // Notify Admins
        try {
            await notifyRequestCompromised(selectedReq.value.item,  profile.value?.full_name || 'Usuario')
        } catch (pushErr) {
            console.error('Push notification failed:', pushErr)
        }

        alert('¡Compromiso registrado con éxito!')
        showModal.value = false 
        
        // Refresh Lists
        await Promise.all([
            fetchData(),
            fetchMyCommits()
        ])
        
        // Switch tab
        activeTab.value = 'commits'
    }
    submitting.value = false
}

onMounted(() => {
    fetchData()
})

watch(activeTab, (val) => {
    if (val === 'commits') fetchMyCommits()
    else fetchData()
})
</script>
