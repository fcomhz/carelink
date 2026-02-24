<template>
  <div class="container-fluid px-0 h-100">
    <div class="row h-100 justify-content-center">
        <div class="col-lg-10 mb-5 pb-5"> 
            
            <!-- Header -->
            <div class="d-flex justify-content-between align-items-center mb-4 pt-3 border-bottom pb-3">
                <div>
                   <h5 class="text-teal fw-bold mb-0"><i class="fas fa-warehouse me-2"></i>ALMACÉN E INVENTARIO</h5>
                   <small class="text-muted">Gestiona existencias y registra salidas/consumos.</small>
                </div>
                <!-- Action Buttons -->
                <div class="d-flex gap-2">
                    <button class="btn btn-warning rounded-pill shadow-sm fw-bold" @click="openAuditModal" :disabled="items.length === 0">
                        <i class="fas fa-clipboard-check me-1"></i> Inventario Físico
                    </button>
                    <button class="btn btn-outline-danger rounded-pill shadow-sm" @click="openConsumeModal" :disabled="items.length === 0">
                        <i class="fas fa-minus-circle me-1"></i> Registrar Salida
                    </button>
                    <!-- Admin Only: Adjust/Add stock directly (Manual) -->
                    <button v-if="isAdmin" class="btn btn-outline-teal rounded-pill shadow-sm" @click="openAdjustModal">
                        <i class="fas fa-plus-circle me-1"></i> Ajuste Manual
                    </button>
                </div>
            </div>

            <!-- Stats / Summary -->
             <div class="row g-3 mb-4">
                <div class="col-6 col-md-3">
                    <div class="card bg-teal-light border-0 shadow-sm p-3 text-center h-100">
                        <h3 class="fw-bold text-teal mb-0">{{ items.length }}</h3>
                        <small class="text-muted">Items Únicos</small>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="card bg-warning-subtle border-0 shadow-sm p-3 text-center h-100">
                        <h3 class="fw-bold text-danger mb-0">{{ lowStockItems.length }}</h3>
                        <small class="text-muted">Bajo Stock</small>
                    </div>
                </div>
             </div>

            <!-- Inventory List -->
            <div class="card border-0 shadow-sm rounded-4">
                <div class="card-body p-0">
                    <div v-if="loading" class="text-center py-5">
                        <div class="spinner-border text-teal" role="status"></div>
                    </div>

                    <div v-else class="table-responsive">
                        <table class="table table-hover align-middle mb-0">
                            <thead class="bg-light">
                                <tr>
                                    <th class="ps-4">Item / Insumo</th>
                                    <th class="text-center">Stock Actual</th>
                                    <th class="text-center">Mínimo</th>
                                    <th>Estado</th>
                                    <th class="text-end pe-4">Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="item in items" :key="item.id">
                                    <td class="ps-4">
                                        <div class="fw-bold text-dark">{{ item.name }}</div>
                                        <small class="text-muted">{{ item.location || 'Sin ubicación' }}</small>
                                    </td>
                                    <td class="text-center fw-bold fs-5">{{ item.quantity }}</td>
                                    <td class="text-center text-muted">{{ item.min_stock }}</td>
                                    <td>
                                        <span v-if="item.quantity <= item.min_stock" class="badge bg-danger rounded-pill">
                                            <i class="fas fa-exclamation-triangle me-1"></i> Reabastecer
                                        </span>
                                        <span v-else class="badge bg-success rounded-pill">OK</span>
                                    </td>
                                    <td class="text-end pe-4">
                                        <button class="btn btn-sm btn-light text-muted me-1" title="Ver Movimientos" @click="viewHistory(item)">
                                            <i class="fas fa-history"></i>
                                        </button>
                                        <button v-if="isAdmin" class="btn btn-sm btn-light text-teal" title="Editar" @click="editItem(item)">
                                            <i class="fas fa-edit"></i>
                                        </button>
                                        <button v-if="isAdmin" class="btn btn-sm btn-light text-danger ms-1" title="Eliminar Item" @click="deleteItem(item)">
                                            <i class="fas fa-trash"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr v-if="items.length === 0">
                                    <td colspan="5" class="text-center py-5 text-muted">Aún no hay inventario registrado.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- MODAL CONSUME / OUT -->
    <div v-if="showConsumeModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0 pb-0">
                    <h5 class="fw-bold text-danger"><i class="fas fa-minus-circle me-2"></i>Registrar Salida</h5>
                    <button type="button" class="btn-close" @click="closeModal"></button>
                </div>
                <div class="modal-body p-4">
                    <form @submit.prevent="handleConsume">
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">¿Qué se retira?</label>
                            <select v-model="form.item_id" class="form-select" required @change="updateMaxQty">
                                <option value="" disabled>Selecciona un insumo...</option>
                                <option v-for="i in items" :key="i.id" :value="i.id">
                                    {{ i.name }} (Disp: {{ i.quantity }})
                                </option>
                            </select>
                        </div>
                        <div class="mb-3">
                             <label class="form-label small fw-bold text-muted">Cantidad a Retirar</label>
                             <input type="number" v-model="form.quantity" class="form-control" min="1" :max="maxQty" required>
                             <div class="form-text x-small text-end">Máximo disponible: {{ maxQty }}</div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Motivo / Destino</label>
                            <textarea v-model="form.notes" class="form-control" rows="2" placeholder="Ej. Paciente Cama 4, Limpieza general..." required></textarea>
                        </div>
                        <div class="d-flex justify-content-end gap-2 mt-4">
                            <button type="button" class="btn btn-light" @click="closeModal">Cancelar</button>
                            <button type="submit" class="btn btn-danger px-4" :disabled="submitting">Confirmar Salida</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL MANUAL ADJUST (ADMIN) -->
    <div v-if="showAdjustModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0 pb-0">
                    <h5 class="fw-bold text-teal"><i class="fas fa-sliders-h me-2"></i>Ajuste / Edición Manual</h5>
                    <button type="button" class="btn-close" @click="closeModal"></button>
                </div>
                <div class="modal-body p-4">
                    <form @submit.prevent="handleAdjust">
                        <div v-if="!editModeItem" class="alert alert-info small">
                            Usa esto para crear un item desde cero o corregir inventario inicial.
                        </div>

                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Nombre del Item</label>
                            <input v-model="adjustForm.name" class="form-control" placeholder="Ej. Jeringas 5ml" required :disabled="!!editModeItem">
                        </div>
                        <div class="row">
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Stock Real</label>
                                <input type="number" v-model="adjustForm.quantity" class="form-control" min="0" required>
                            </div>
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Stock Mínimo</label>
                                <input type="number" v-model="adjustForm.min_stock" class="form-control" min="1" required>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Ubicación</label>
                            <input v-model="adjustForm.location" class="form-control" placeholder="Ej. Estante A-2">
                            </div>
                        <div class="d-flex justify-content-end gap-2 mt-4">
                            <button type="button" class="btn btn-light" @click="closeModal">Cancelar</button>
                            <button type="submit" class="btn btn-teal px-4" :disabled="submitting">Guardar Ajuste</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
    
    <!-- HISTORY MODAL -->
    <div v-if="showHistoryModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0 pb-0">
                    <h5 class="fw-bold text-teal"><i class="fas fa-history me-2"></i>Historial: {{ historicalItem?.name }}</h5>
                    <button type="button" class="btn-close" @click="showHistoryModal = false"></button>
                </div>
                <div class="modal-body p-4">
                    <div v-if="history.length === 0" class="text-center py-4 text-muted">
                        No hay movimientos registrados.
                    </div>
                    <div v-else class="table-responsive">
                        <table class="table table-hover align-middle">
                            <thead class="bg-light">
                                <tr>
                                    <th class="small text-muted">Fecha</th>
                                    <th class="small text-muted">Tipo</th>
                                    <th class="small text-muted">Cant.</th>
                                    <th class="small text-muted">Usuario</th>
                                    <th class="small text-muted">Notas</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="h in history" :key="h.id">
                                    <td class="small">{{ new Date(h.created_at).toLocaleString() }}</td>
                                    <td>
                                        <span class="badge" :class="h.type === 'IN' ? 'bg-success-subtle text-success' : 'bg-danger-subtle text-danger'">
                                            {{ h.type === 'IN' ? 'ENTRADA' : 'SALIDA' }}
                                        </span>
                                    </td>
                                    <td class="fw-bold">{{ h.quantity }}</td>
                                    <td class="small">{{ h.profile?.full_name || 'Desconocido' }}</td>
                                    <td class="small text-muted fst-italic">{{ h.notes }}</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div class="mt-3 text-end">
                         <button class="btn btn-light btn-sm" @click="showHistoryModal = false">Cerrar</button>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- PREMIUM DELETE CONFIRMATION MODAL -->
    <div v-if="itemToDelete" class="modal d-block" style="background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); z-index: 2000;" @click.self="itemToDelete = null">
        <div class="modal-dialog modal-dialog-centered" style="max-width: 400px;">
            <div class="modal-content rounded-4 border-0 shadow-lg animate-up">
                <div class="modal-body p-4 text-center">
                    <div class="mb-4">
                        <div class="bg-danger-subtle text-danger rounded-circle d-inline-flex align-items-center justify-content-center mb-3 shadow-sm" style="width: 70px; height: 70px;">
                            <i class="fas fa-trash-alt fa-2x"></i>
                        </div>
                        <h5 class="fw-bold text-dark">¿Eliminar Insumo?</h5>
                        <p class="text-muted small px-2">
                            Estás a punto de eliminar <strong>"{{ itemToDelete.name }}"</strong> del inventario. 
                            Se borrará también todo su historial de movimientos.
                        </p>
                    </div>
                    <div class="d-grid gap-2">
                        <button class="btn btn-danger py-2 fw-bold rounded-pill" @click="confirmDeleteItem" :disabled="submitting">
                            <i v-if="submitting" class="spinner-border spinner-border-sm me-2"></i>
                            {{ submitting ? 'Eliminando...' : 'Sí, Eliminar Permanentemente' }}
                        </button>
                        <button class="btn btn-light py-2 rounded-pill text-muted fw-bold" @click="itemToDelete = null" :disabled="submitting">
                            Cancelar
                        </button>
                    </div>
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

const items = ref<any[]>([])
const loading = ref(true)
const submitting = ref(false)
const showConsumeModal = ref(false)
const showAdjustModal = ref(false)
const showAuditModal = ref(false)
const itemToDelete = ref<any>(null)

// Forms
const form = reactive({
    item_id: '',
    quantity: 1,
    notes: ''
})
const maxQty = ref(1000)

const auditForm = reactive({
    item_id: '',
    physical_quantity: 0,
    notes: ''
})

const adjustForm = reactive({
    id: null as string | null,
    name: '',
    quantity: 0,
    min_stock: 5,
    location: ''
})
const editModeItem = ref<any>(null)

// Computed
const lowStockItems = computed(() => items.value.filter(i => i.quantity <= i.min_stock))

const auditDiff = computed(() => {
    if (!auditForm.item_id) return 0
    const item = items.value.find(i => i.id === auditForm.item_id)
    return item ? auditForm.physical_quantity - item.quantity : 0
})

// FETCH
const fetchInventory = async () => {
    loading.value = true
    const { data, error } = await supabase.schema('app_carelink')
        .from('inventory_items')
        .select('*')
        .order('name')
    
    if (error) console.error(error)
    items.value = data || []
    loading.value = false
}

// CONSUME LOGIC
const openConsumeModal = () => {
    form.item_id = ''
    form.quantity = 1
    form.notes = ''
    showConsumeModal.value = true
}

// HISTORY LOGIC
const history = ref<any[]>([])
const historicalItem = ref<any>(null)
const showHistoryModal = ref(false)

const viewHistory = async (item: any) => {
    historicalItem.value = item
    history.value = []
    showHistoryModal.value = true
    
    const { data, error } = await supabase.schema('app_carelink')
        .from('inventory_transactions')
        .select(`
            *,
            profile:performed_by(full_name)
        `)
        .eq('item_id', item.id)
        .order('created_at', { ascending: false })
    
    if (error) {
        alert('Error cargando historial')
        console.error(error)
        return
    }
    history.value = data || []
}

const updateMaxQty = () => {
    const item = items.value.find(i => i.id === form.item_id)
    if (item) maxQty.value = item.quantity
}

const handleConsume = async () => {
    submitting.value = true
    try {
        const item = items.value.find(i => i.id === form.item_id)
        if (!item) return

        if (form.quantity > item.quantity) {
             alert(`Error: Solo hay ${item.quantity} disponibles.`)
             submitting.value = false
             return
        }

        // 1. Transaction
        const { error: tErr } = await supabase.schema('app_carelink').from('inventory_transactions').insert({
            organization_id: organizationId.value,
            item_id: form.item_id,
            type: 'OUT',
            quantity: form.quantity,
            performed_by: profile.value.id,
            notes: form.notes
        })
        if (tErr) throw tErr

        // 2. Update Item
        const { error: iErr } = await supabase.schema('app_carelink').from('inventory_items')
            .update({ quantity: item.quantity - form.quantity })
            .eq('id', form.item_id)
        if (iErr) throw iErr

        await fetchInventory()
        closeModal()
        alert('Salida registrada correctamente.')

    } catch (e: any) {
        alert('Error: ' + e.message)
    } finally {
        submitting.value = false
    }
}

// ADJUST LOGIC
const openAdjustModal = () => {
    editModeItem.value = null
    adjustForm.id = null
    adjustForm.name = ''
    adjustForm.quantity = 0
    adjustForm.min_stock = 5
    adjustForm.location = ''
    showAdjustModal.value = true
}

const editItem = (item: any) => {
    editModeItem.value = item
    adjustForm.id = item.id
    adjustForm.name = item.name
    adjustForm.quantity = item.quantity
    adjustForm.min_stock = item.min_stock
    adjustForm.location = item.location
    showAdjustModal.value = true
}

const handleAdjust = async () => {
    console.log('handleAdjust triggered')
    if (!organizationId.value) {
        alert('Error: No se detecta la organización ID. Recarga la página.')
        return
    }
    
    submitting.value = true
    try {
        const payload = {
            organization_id: organizationId.value,
            name: adjustForm.name,
            quantity: adjustForm.quantity,
            min_stock: adjustForm.min_stock,
            location: adjustForm.location
        }

        let error
        if (adjustForm.id) {
            // Update
             const res = await supabase.schema('app_carelink').from('inventory_items').update(payload).eq('id', adjustForm.id)
             error = res.error
        } else {
            // Insert
            const res = await supabase.schema('app_carelink').from('inventory_items').insert(payload)
            error = res.error
        }

        if (error) throw error

        await fetchInventory()
        closeModal()
        alert('Ajuste de inventario guadado correctamente.')

    } catch (e: any) {
        console.error(e)
        alert('Error: ' + e.message)
    } finally {
        submitting.value = false
    }
}

// AUDIT LOGIC
const openAuditModal = () => {
    auditForm.item_id = ''
    auditForm.physical_quantity = 0
    auditForm.notes = ''
    showAuditModal.value = true
}

const handleAudit = async () => {
    submitting.value = true
    try {
        const item = items.value.find(i => i.id === auditForm.item_id)
        if (!item) return

        const diff = auditDiff.value
        if (diff === 0 && !confirm('La cantidad física coincide con el sistema. ¿Deseas registrar la auditoría de todos modos?')) {
            submitting.value = false
            return
        }

        // 1. Transaction
        const { error: tErr } = await supabase.schema('app_carelink').from('inventory_transactions').insert({
            organization_id: organizationId.value,
            item_id: auditForm.item_id,
            type: 'ADJUST',
            quantity: Math.abs(diff) || 0,
            performed_by: profile.value.id,
            notes: `Inventario Físico: ${auditForm.notes || 'Ajuste de auditoría'}. Diferencia: ${diff}`
        })
        if (tErr) throw tErr

        // 2. Update Item Quantity
        const { error: iErr } = await supabase.schema('app_carelink').from('inventory_items')
            .update({ quantity: auditForm.physical_quantity, last_updated: new Date().toISOString() })
            .eq('id', auditForm.item_id)
        if (iErr) throw iErr

        await fetchInventory()
        showAuditModal.value = false
        alert('Inventario físico actualizado correctamente.')

    } catch (e: any) {
        alert('Error: ' + e.message)
    } finally {
        submitting.value = false
    }
}
const deleteItem = (item: any) => {
    itemToDelete.value = item
}

const confirmDeleteItem = async () => {
    if (!itemToDelete.value) return
    submitting.value = true
    try {
        const { error } = await supabase.schema('app_carelink')
            .from('inventory_items')
            .delete()
            .eq('id', itemToDelete.value.id)
        
        if (error) {
            // Check for potential conflict if cascade fix failed
            if (error.code === '23503') {
                throw new Error('No se puede eliminar porque existen transacciones vinculadas. Por favor contacta soporte para aplicar el fix de integridad.')
            }
            throw error
        }
        
        itemToDelete.value = null
        await fetchInventory()
    } catch (e: any) {
        console.error('Delete Item Error:', e)
        alert('Error al eliminar: ' + (e.message || e.details || 'Error desconocido'))
    } finally {
        submitting.value = false
    }
}

const closeModal = () => {
    showConsumeModal.value = false
    showAdjustModal.value = false
}



onMounted(() => {
    fetchInventory()
})
</script>
