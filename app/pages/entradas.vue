<template>
  <div class="container-fluid px-0 h-100">
    <div class="row h-100 justify-content-center">
        <div class="col-lg-10 mb-5 pb-5"> 
            <!-- Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 pt-3 border-bottom pb-3">
                <div>
                   <h5 class="text-teal fw-bold mb-0"><i class="fas fa-boxes me-2"></i>ENTRADAS DE ALMACÉN</h5>
                   <small class="text-muted">Valida la recepción de insumos y registra donativos.</small>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-warning rounded-pill px-4 fw-bold shadow-sm" @click="openDirectDonationModal">
                        <i class="fas fa-hand-holding-heart me-1"></i> Donación Directa
                    </button>
                </div>
            </div>

            <!-- Tabs -->
             <ul class="nav nav-pills mb-4">
                <li class="nav-item">
                    <button class="nav-link rounded-pill px-4" 
                        :class="{ active: activeTab === 'pending' }"
                        @click="activeTab = 'pending'">
                        Pendientes de Recepción
                    </button>
                </li>
                <li class="nav-item">
                    <button class="nav-link rounded-pill px-4" 
                        :class="{ active: activeTab === 'history' }"
                        @click="activeTab = 'history'">
                        Historial Recibido
                    </button>
                </li>
            </ul>

            <!-- Loading -->
            <div v-if="loading" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>

            <!-- List -->
            <div v-else class="row g-3">
                <div v-for="item in filteredList" :key="item.id" class="col-md-6">
                    <div class="card border-0 shadow-sm border-start border-4" :class="item.status === 'PENDIENTE' ? 'border-warning' : 'border-success'">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h6 class="fw-bold mb-1">{{ item.request?.item }}</h6>
                                    <div class="text-muted small">
                                        <i class="fas fa-box-open text-teal me-1"></i> Cantidad: <strong>{{ item.quantity }}</strong>
                                    </div>
                                    <div class="text-muted small">
                                        <i class="fas fa-user me-1"></i> Aporta: {{ item.profile?.full_name || 'Anónimo' }}
                                    </div>
                                    <div class="text-muted small">
                                        <i class="fas fa-map-marker-alt me-1"></i> Entrega: <span class="fw-bold">{{ item.center?.name }}</span>
                                    </div>
                                    <div class="text-muted small">
                                        <i class="far fa-calendar me-1"></i> Fecha Est.: {{ item.delivery_date || 'N/A' }}
                                    </div>
                                </div>
                                <div class="ms-auto text-end">
                                    <div class="badge rounded-pill mb-2" :class="item.status === 'PENDIENTE' ? 'bg-warning text-dark' : 'bg-success'">
                                        {{ item.status }}
                                    </div>
                                    <div class="d-flex justify-content-end gap-1 mt-2">
                                        <button v-if="activeTab === 'pending'" class="btn btn-sm btn-teal" @click="openValidateModal(item)">
                                            Validar <i class="fas fa-check ms-1"></i>
                                        </button>
                                        
                                        <!-- Delete Button Logic -->
                                        <button v-if="isAdmin && deletingId !== item.id" 
                                            class="btn btn-sm btn-light text-danger" 
                                            title="Eliminar Entrada" 
                                            @click="deletingId = item.id">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                        <div v-if="isAdmin && deletingId === item.id" class="d-flex gap-1 animate-up">
                                            <button class="btn btn-sm btn-danger text-white fw-bold" @click="deleteEntry(item.id)">
                                                ¿Confirmar?
                                            </button>
                                            <button class="btn btn-sm btn-light border" @click="deletingId = null">
                                                <i class="fas fa-times"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div v-if="filteredList.length === 0" class="col-12 text-center py-5">
                    <p class="text-muted">No hay registros en esta sección.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL VALIDATE -->
    <div v-if="showModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0">
                    <h5 class="fw-bold text-teal">Validar Recepción</h5>
                    <button type="button" class="btn-close" @click="closeModal"></button>
                </div>
                <div class="modal-body p-4">
                    <form @submit.prevent="handleValidate">
                         <div class="alert alert-light border small text-muted mb-3">
                            Confirmas la recepción de: <strong>{{ form.item_name }}</strong>.
                         </div>

                         <div class="row">
                             <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Cantidad Recibida</label>
                                <input type="number" v-model="form.quantity" class="form-control" min="1" required>
                             </div>
                             <div class="col-6 mb-3">
                                 <label class="form-label small fw-bold text-muted">Costo Unitario ($)</label>
                                 <div class="input-group">
                                     <span class="input-group-text bg-light">$</span>
                                     <input type="number" v-model="form.unit_price" class="form-control" min="0" step="0.01" required>
                                 </div>
                             </div>
                         </div>

                         <div class="alert alert-success border-success bg-success-subtle small fw-bold d-flex justify-content-between">
                            <span>Total a Registrar:</span>
                            <span>{{ new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(form.quantity * form.unit_price) }}</span>
                         </div>
                         <div class="form-text x-small mb-3">Este total se registrará como ingreso en Finanzas si la opción está marcada.</div>

                         <div class="form-check mb-4">
                             <input class="form-check-input" type="checkbox" v-model="form.register_finance" id="chkFin">
                             <label class="form-check-label small" for="chkFin">
                                 Registrar automáticamente como <strong>Ingreso (Donativo en Especie)</strong> en Finanzas.
                             </label>
                         </div>

                         <div class="d-flex justify-content-end gap-2">
                             <button type="button" class="btn btn-light" @click="closeModal">Cancelar</button>
                             <button type="submit" class="btn btn-success px-4" :disabled="submitting">
                                 {{ submitting ? 'Procesando...' : 'Confirmar Entrada' }}
                             </button>
                         </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL DIRECT DONATION -->
    <div v-if="showDirectModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0 bg-warning text-dark rounded-top-4">
                    <h5 class="fw-bold mb-0"><i class="fas fa-hand-holding-heart me-2"></i>Registrar Donación Directa</h5>
                    <button type="button" class="btn-close" @click="showDirectModal = false"></button>
                </div>
                <div class="modal-body p-4">
                    <form @submit.prevent="handleDirectDonation">
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">¿Qué se donó? (Nombre del Item)</label>
                            <input v-model="directForm.item_name" class="form-control" placeholder="Ej. Pañales Etapa 3" required>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Aportante (Nombre)</label>
                            <input v-model="directForm.donor_name" class="form-control" placeholder="Ej. Juan Pérez (Opcional)">
                        </div>
                        <div class="row">
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Cantidad</label>
                                <input type="number" v-model="directForm.quantity" class="form-control" min="1" required>
                            </div>
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Costo Unitario (Est.)</label>
                                <div class="input-group">
                                    <span class="input-group-text">$</span>
                                    <input type="number" v-model="directForm.unit_price" class="form-control" min="0" step="0.01">
                                </div>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Categoría</label>
                            <select v-model="directForm.category_id" class="form-select">
                                <option value="">Sin categoría...</option>
                                <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                            </select>
                        </div>
                        <div class="form-check mb-4">
                             <input class="form-check-input" type="checkbox" v-model="directForm.register_finance" id="chkDirectFin">
                             <label class="form-check-label small" for="chkDirectFin">
                                 Registrar en Finanzas (Donativo Especie)
                             </label>
                        </div>
                        <div class="d-flex justify-content-end gap-2">
                             <button type="button" class="btn btn-light" @click="showDirectModal = false">Cancelar</button>
                             <button type="submit" class="btn btn-warning px-4 fw-bold" :disabled="submitting">
                                 Registrar Donación
                             </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const { organizationId, profile } = useOrganization()

const isAdmin = computed(() => profile.value?.role === 'ADMIN')

const activeTab = ref('pending')
const loading = ref(true)
const submitting = ref(false)
const showModal = ref(false)

const list = ref<any[]>([])
const categories = ref<any[]>([])
const showDirectModal = ref(false)

// Form
const form = reactive({
    fulfillment_id: '',
    item_name: '',
    quantity: 0,
    unit_price: 0,
    request_id: '',
    sponsor_name: '',
    register_finance: true
})

const directForm = reactive({
    item_name: '',
    donor_name: '',
    quantity: 1,
    unit_price: 0,
    category_id: '',
    register_finance: true
})

const filteredList = computed(() => {
    if (activeTab.value === 'pending') return list.value.filter(i => i.status === 'PENDIENTE')
    return list.value.filter(i => i.status === 'ENTREGADO')
})

const fetchData = async () => {
    loading.value = true
    const { data, error } = await supabase.schema('app_carelink')
        .from('fulfillments')
        .select(`
            *,
            request:request_id(item),
            profile:user_id(full_name),
            center:collection_center_id(name)
        `)
        .order('created_at', { ascending: false })
    
    if (error) console.error(error)
    list.value = data || []

    // Fetch Categories for direct donation
    const { data: catData } = await supabase.schema('app_carelink').from('categories').select('*').order('name')
    categories.value = catData || []

    loading.value = false
}

const openDirectDonationModal = () => {
    directForm.item_name = ''
    directForm.donor_name = ''
    directForm.quantity = 1
    directForm.unit_price = 0
    directForm.category_id = ''
    directForm.register_finance = true
    showDirectModal.value = true
}

const handleDirectDonation = async () => {
    submitting.value = true
    try {
        const totalAmount = directForm.quantity * directForm.unit_price

        // 1. Check/Update Inventory
        let itemId = null
        const { data: existingItem } = await supabase.schema('app_carelink')
            .from('inventory_items')
            .select('id, quantity')
            .eq('name', directForm.item_name)
            .eq('organization_id', organizationId.value)
            .maybeSingle()

        if (existingItem) {
            itemId = existingItem.id
            const { error: upErr } = await supabase.schema('app_carelink')
                .from('inventory_items')
                .update({ quantity: Number(existingItem.quantity) + Number(directForm.quantity) })
                .eq('id', itemId)
            if (upErr) throw upErr
        } else {
            const { data: newItem, error: crErr } = await supabase.schema('app_carelink')
                .from('inventory_items')
                .insert({
                    organization_id: organizationId.value,
                    name: directForm.item_name,
                    quantity: directForm.quantity,
                    min_stock: 5,
                    location: 'Recepción',
                    category_id: directForm.category_id || null
                })
                .select()
                .single()
            if (crErr) throw crErr
            itemId = newItem.id
        }

        // 2. Register Transaction
        await supabase.schema('app_carelink').from('inventory_transactions').insert({
            organization_id: organizationId.value,
            item_id: itemId,
            type: 'IN',
            quantity: directForm.quantity,
            performed_by: profile.value.id,
            notes: `Donación Directa (Aportante: ${directForm.donor_name || 'Anónimo'})`
        })

        // 3. Register Finance
        if (directForm.register_finance && totalAmount > 0) {
            await supabase.schema('app_carelink').from('finance_records').insert({
                organization_id: organizationId.value,
                date_occurred: new Date().toISOString().split('T')[0],
                concept: `Donativo Directo: ${directForm.item_name} (x${directForm.quantity}) - ${directForm.donor_name || 'Anónimo'}`,
                amount: totalAmount,
                category: 'Donativo en Especie',
                type: 'IN',
                recorded_by: profile.value.id
            })
        }

        alert('¡Donación registrada con éxito!')
        showDirectModal.value = false
        await fetchData()
    } catch (e: any) {
        alert('Error: ' + e.message)
    } finally {
        submitting.value = false
    }
}

const openValidateModal = (item: any) => {
    form.fulfillment_id = item.id
    form.item_name = item.request?.item
    form.quantity = item.quantity
    form.unit_price = 0 
    form.request_id = item.request_id
    form.sponsor_name = item.profile?.full_name || 'Anónimo'
    form.register_finance = true
    showModal.value = true
}

const closeModal = () => {
    showModal.value = false
}

const handleValidate = async () => {
    submitting.value = true
    try {
        const totalAmount = form.quantity * form.unit_price

        // 1. Update Fulfillment Status
        const { error: fError } = await supabase.schema('app_carelink')
            .from('fulfillments')
            .update({
                status: 'ENTREGADO',
                quantity: form.quantity, 
                received_at: new Date().toISOString(),
                received_by: profile.value.id,
                financial_value: totalAmount
            })
            .eq('id', form.fulfillment_id)
        
        if (fError) throw fError

        // 2. INVENTORY INTEGRATION
        // Check if item exists in inventory by name
        let itemId = null
        const { data: existingItem } = await supabase.schema('app_carelink')
            .from('inventory_items')
            .select('id, quantity')
            .eq('name', form.item_name) // Match exact name for now
            .eq('organization_id', organizationId.value)
            .single()

        if (existingItem) {
            // Update existing
            itemId = existingItem.id
            const { error: upErr } = await supabase.schema('app_carelink')
                .from('inventory_items')
                .update({ quantity: Number(existingItem.quantity) + Number(form.quantity) })
                .eq('id', itemId)
            if (upErr) throw upErr
        } else {
            // Create new
            const { data: newItem, error: crErr } = await supabase.schema('app_carelink')
                .from('inventory_items')
                .insert({
                    organization_id: organizationId.value,
                    name: form.item_name,
                    quantity: form.quantity,
                    min_stock: 5, // Default
                    location: 'Recepción'
                })
                .select()
                .single()
            if (crErr) throw crErr
            itemId = newItem.id
        }

        // Register Transaction
        if (itemId) {
            await supabase.schema('app_carelink').from('inventory_transactions').insert({
                organization_id: organizationId.value,
                item_id: itemId,
                type: 'IN',
                quantity: form.quantity,
                performed_by: profile.value.id,
                notes: `Recepción de pedido (ID: ${form.fulfillment_id})`,
                related_entity_id: form.fulfillment_id
            })
        }

        // 3. Register Finance (Optional)
        if (form.register_finance && totalAmount >= 0) {
            const { error: finError } = await supabase.schema('app_carelink')
                .from('finance_records')
                .insert({
                    organization_id: organizationId.value,
                    date_occurred: new Date().toISOString().split('T')[0],
                    concept: `Donativo Especie: ${form.item_name} (x${form.quantity}) - ${form.sponsor_name}`,
                    amount: totalAmount,
                    category: 'Donativo en Especie',
                    type: 'IN',
                    recorded_by: profile.value.id
                })
            
            if (finError) throw finError
        }

        alert('¡Entrada registrada en Inventario y Finanzas!')
        await fetchData()
        closeModal()

    } catch (e: any) {
        alert('Error: ' + e.message)
    } finally {
        submitting.value = false
    }
}

const deletingId = ref<string | null>(null)

const deleteEntry = async (id: string) => {
    // Delete validation directly
    try {
        const { error } = await supabase.schema('app_carelink')
            .from('fulfillments')
            .delete()
            .eq('id', id)
        
        if (error) throw error
        
        alert('Entrada eliminada.')
        deletingId.value = null // Reset
        await fetchData()
    } catch (e: any) {
        console.error(e)
        alert('Error: ' + e.message)
    }
}

onMounted(() => {
    fetchData()
})
</script>
