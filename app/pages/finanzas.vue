<template>
  <div class="container-fluid px-0 h-100">
    <div class="row h-100 justify-content-center">
        <div class="col-lg-11 mb-5 pb-5"> 
            
            <!-- Header & Controls -->
            <div class="d-flex justify-content-between align-items-center mb-4 pt-3 border-bottom pb-3">
                <div>
                   <h5 class="text-teal fw-bold mb-0"><i class="fas fa-chart-line me-2"></i>FINANZAS Y BALANCE</h5>
                   <small class="text-muted">Administración de ingresos, egresos y balance operativo.</small>
                </div>
                <div class="d-flex gap-2">
                    <!-- Month Selector -->
                     <input type="month" v-model="selectedMonth" class="form-control" @change="fetchRecords">
                     
                     <button v-if="isAdmin" class="btn btn-teal rounded-pill shadow-sm px-4" @click="openModal">
                        <i class="fas fa-plus me-1"></i> Nuevo Movimiento
                     </button>
                </div>
            </div>

            <!-- SUMMARY CARDS -->
            <div class="row g-3 mb-4">
                <!-- OPERATIONAL BALANCE -->
                <div class="col-md-4">
                    <div class="card border-0 shadow-sm p-3 h-100 bg-light">
                        <h6 class="text-muted small fw-bold text-uppercase mb-3">Balance Operativo (Regular)</h6>
                        <div class="d-flex justify-content-between align-items-end mb-2">
                             <span class="text-muted small">Ingresos Reg:</span>
                             <span class="text-success fw-bold">{{ formatCurrency(balance.regularIncome) }}</span>
                        </div>
                        <div class="d-flex justify-content-between align-items-end mb-3 border-bottom pb-2">
                             <span class="text-muted small">Gastos Reg:</span>
                             <span class="text-danger fw-bold">- {{ formatCurrency(balance.regularExpense) }}</span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mt-auto">
                            <span class="fw-bold">Resultado Operativo:</span>
                            <span class="h4 mb-0 fw-bold" :class="balance.operational >= 0 ? 'text-teal' : 'text-danger'">
                                {{ formatCurrency(balance.operational) }}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- EVENTUALS -->
                <div class="col-md-4">
                    <div class="card border-0 shadow-sm p-3 h-100 bg-white">
                        <h6 class="text-muted small fw-bold text-uppercase mb-3">Movimientos Eventuales</h6>
                        <div class="d-flex justify-content-between align-items-end mb-2">
                             <span class="text-muted small">Extra / Eventual (IN):</span>
                             <span class="text-success fw-bold">{{ formatCurrency(balance.eventualIncome) }}</span>
                        </div>
                        <div class="d-flex justify-content-between align-items-end mb-3 border-bottom pb-2">
                             <span class="text-muted small">Gastos Extra (OUT):</span>
                             <span class="text-danger fw-bold">- {{ formatCurrency(balance.eventualExpense) }}</span>
                        </div>
                        <p class="text-muted x-small mb-0">Incluye donativos en especie y compras de emergencia.</p>
                    </div>
                </div>

                <!-- NET BALANCE -->
                <div class="col-md-4">
                     <div class="card border-0 shadow-sm p-3 h-100" :class="balance.net >= 0 ? 'bg-teal text-white' : 'bg-danger text-white'">
                        <h6 class="text-white-50 small fw-bold text-uppercase mb-3">Balance Neto (Total)</h6>
                         <div class="text-center my-auto">
                             <h2 class="display-6 fw-bold mb-0">{{ formatCurrency(balance.net) }}</h2>
                             <small class="text-white-50">Flujo de Caja Real</small>
                         </div>
                     </div>
                </div>
            </div>

            <!-- FILTERS & LIST -->
             <div class="card border-0 shadow-sm rounded-4">
                 <div class="card-header bg-white border-0 pt-4 px-4 d-flex justify-content-between align-items-center">
                     <h6 class="fw-bold mb-0">Movimientos del Mes</h6>
                     <div class="btn-group btn-group-sm">
                         <button class="btn btn-outline-secondary" :class="{active: filterType === 'ALL'}" @click="filterType = 'ALL'">Todos</button>
                         <button class="btn btn-outline-success" :class="{active: filterType === 'IN'}" @click="filterType = 'IN'">Ingresos</button>
                         <button class="btn btn-outline-danger" :class="{active: filterType === 'OUT'}" @click="filterType = 'OUT'">Egresos</button>
                     </div>
                 </div>
                 <div class="card-body p-0">
                     <div v-if="loading" class="text-center py-5">
                         <div class="spinner-border text-teal" role="status"></div>
                     </div>
                     <div v-else class="table-responsive">
                         <table class="table table-hover align-middle mb-0">
                             <thead class="bg-light">
                                 <tr>
                                     <th class="ps-4">Fecha</th>
                                     <th>Concepto</th>
                                     <th>Categoría</th>
                                     <th>Frecuencia</th>
                                     <th class="text-end pe-4">Monto</th>
                                     <th v-if="isAdmin" class="text-end">Acciones</th>
                                 </tr>
                             </thead>
                             <tbody>
                                 <tr v-for="rec in filteredRecords" :key="rec.id">
                                     <td class="ps-4 small text-muted">{{ rec.date_occurred }}</td>
                                     <td class="fw-bold text-dark">{{ rec.concept }}</td>
                                     <td><span class="badge bg-light text-dark border">{{ rec.category }}</span></td>
                                     <td>
                                         <span class="badge" :class="rec.frequency === 'REGULAR' ? 'bg-primary-subtle text-primary' : 'bg-warning-subtle text-warning-emphasis'">
                                             {{ rec.frequency || 'EVENTUAL' }}
                                         </span>
                                     </td>
                                     <td class="text-end pe-4 fw-bold" :class="rec.type === 'IN' ? 'text-success' : 'text-danger'">
                                         {{ rec.type === 'IN' ? '+' : '-' }} {{ formatCurrency(rec.amount) }}
                                     </td>
                                     <td v-if="isAdmin" class="text-end">
                                         <button class="btn btn-sm btn-light text-teal me-1" title="Editar" @click="openModal(rec)">
                                             <i class="fas fa-edit"></i>
                                         </button>
                                         <button class="btn btn-sm btn-light text-danger" title="Eliminar" @click="deleteRecord(rec.id)">
                                             <i class="fas fa-trash"></i>
                                         </button>
                                     </td>
                                 </tr>
                                 <tr v-if="filteredRecords.length === 0">
                                     <td colspan="6" class="text-center py-5 text-muted">No hay movimientos registrados en este periodo.</td>
                                 </tr>
                             </tbody>
                         </table>
                     </div>
                 </div>
             </div>

        </div>
    </div>

    <!-- MODAL -->
    <div v-if="showModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow rounded-4">
                <div class="modal-header border-0 pb-0">
                     <h5 class="fw-bold text-teal">{{ form.id ? 'Editar Movimiento' : 'Registrar Movimiento' }}</h5>
                     <button type="button" class="btn-close" @click="closeModal"></button>
                </div>
                <div class="modal-body p-4">
                    <form @submit.prevent="handleSubmit">
                        <div class="row">
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Tipo</label>
                                <select v-model="form.type" class="form-select" required>
                                    <option value="IN">Ingreso (+)</option>
                                    <option value="OUT">Egreso (-)</option>
                                </select>
                            </div>
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Frecuencia</label>
                                 <select v-model="form.frequency" class="form-select" required>
                                    <option value="REGULAR">Regular / Recurrente</option>
                                    <option value="EVENTUAL">Eventual / Único</option>
                                </select>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Fecha</label>
                            <input type="date" v-model="form.date_occurred" class="form-control" required>
                        </div>

                        <div class="mb-3">
                             <label class="form-label small fw-bold text-muted">Monto</label>
                             <div class="input-group">
                                 <span class="input-group-text">$</span>
                                 <input type="number" v-model="form.amount" class="form-control" min="0" step="0.01" required>
                             </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Concepto</label>
                            <input type="text" v-model="form.concept" class="form-control" placeholder="Ej. Renta de Oficina, Donativo Sr. Pérez..." required>
                        </div>
                        
                         <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Categoría</label>
                            <input type="text" v-model="form.category" class="form-control" placeholder="Ej. Servicios, Nómina, Donativos..." list="catList">
                            <datalist id="catList">
                                <option value="Servicios"></option>
                                <option value="Nómina"></option>
                                <option value="Donativo Efectivo"></option>
                                <option value="Mantenimiento"></option>
                                <option value="Materiales"></option>
                            </datalist>
                        </div>

                        <div class="d-flex justify-content-end gap-2 mt-4">
                             <button type="button" class="btn btn-light" @click="closeModal">Cancelar</button>
                             <button type="submit" class="btn btn-teal px-4" :disabled="submitting">Guardar</button>
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

// State
const records = ref<any[]>([])
const loading = ref(true)
const submitting = ref(false)
const showModal = ref(false)
const selectedMonth = ref(new Date().toISOString().slice(0, 7)) // YYYY-MM
const filterType = ref('ALL')

// Form
const form = reactive({
    id: null as string | null,
    type: 'OUT',
    frequency: 'EVENTUAL',
    date_occurred: new Date().toISOString().split('T')[0],
    amount: 0,
    concept: '',
    category: ''
})

// Metrics
const balance = computed(() => {
    let regularIncome = 0
    let eventualIncome = 0
    let regularExpense = 0
    let eventualExpense = 0

    records.value.forEach(r => {
        const val = Number(r.amount)
        if (r.type === 'IN') {
            if (r.frequency === 'REGULAR') regularIncome += val
            else eventualIncome += val
        } else {
            if (r.frequency === 'REGULAR') regularExpense += val
            else eventualExpense += val
        }
    })

    return {
        regularIncome,
        eventualIncome,
        regularExpense,
        eventualExpense,
        operational: regularIncome - regularExpense,
        net: (regularIncome + eventualIncome) - (regularExpense + eventualExpense)
    }
})

const filteredRecords = computed(() => {
    if (filterType.value === 'ALL') return records.value
    return records.value.filter(r => r.type === filterType.value)
})

// METHODS
const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val)
}

const fetchRecords = async () => {
    loading.value = true
    const [year, month] = selectedMonth.value.split('-')
    
    const startDate = `${selectedMonth.value}-01`
    const endDate = new Date(Number(year), Number(month), 0).toISOString().split('T')[0] // Last day of month

    const { data, error } = await supabase.schema('app_carelink')
        .from('finance_records')
        .select('*')
        .gte('date_occurred', startDate)
        .lte('date_occurred', endDate)
        .order('date_occurred', { ascending: false })
    
    if (error) console.error(error)
    records.value = data || []
    loading.value = false
}

const openModal = (record: any = null) => {
    if (record) {
        // Edit Mode
        form.id = record.id
        form.type = record.type
        form.frequency = record.frequency || 'EVENTUAL'
        form.date_occurred = record.date_occurred
        form.amount = record.amount
        form.concept = record.concept
        form.category = record.category
    } else {
        // Create Mode
        form.id = null
        form.type = 'OUT'
        form.frequency = 'EVENTUAL'
        form.amount = 0
        form.concept = ''
        form.category = ''
        form.date_occurred = new Date().toISOString().split('T')[0]
    }
    showModal.value = true
}

const closeModal = () => {
    showModal.value = false
}

const handleSubmit = async () => {
    if (!organizationId.value) return
    submitting.value = true
    try {
        const payload = {
            organization_id: organizationId.value,
            date_occurred: form.date_occurred,
            type: form.type,
            frequency: form.frequency,
            amount: form.amount,
            concept: form.concept,
            category: form.category,
            recorded_by: profile.value.id
        }

        let error
        if (form.id) {
            // Update
            const res = await supabase.schema('app_carelink').from('finance_records').update(payload).eq('id', form.id)
            error = res.error
        } else {
            // Insert
            const res = await supabase.schema('app_carelink').from('finance_records').insert(payload)
            error = res.error
        }
        
        if (error) throw error
        
        alert(form.id ? 'Movimiento actualizado.' : 'Movimiento registrado.')
        closeModal()
        await fetchRecords()
        
    } catch (e: any) {
        alert('Error: ' + e.message)
    } finally {
        submitting.value = false
    }
}

const deleteRecord = async (id: string) => {
    if (!confirm('¿Eliminar este registro financiero?')) return
    try {
        const { error } = await supabase.schema('app_carelink')
            .from('finance_records')
            .delete()
            .eq('id', id)
        
        if (error) throw error
        await fetchRecords()
    } catch (e: any) {
        alert('Error: ' + e.message)
    }
}

onMounted(() => {
    fetchRecords()
})
</script>
