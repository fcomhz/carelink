<template>
  <div class="container-fluid px-0 h-100">
    <div class="row h-100 justify-content-center">
        <div class="col-lg-11 mb-5 pb-5"> 
            
            <!-- Header & Controls -->
            <div class="d-flex justify-content-between align-items-center mb-4 pt-3 border-bottom pb-3">
                <div>
                   <h5 class="text-teal fw-bold mb-0"><i class="fas fa-chart-line me-2"></i>FINANZAS Y BALANCE</h5>
                   <small class="text-muted">Administración integral de ingresos, egresos y donativos.</small>
                </div>
                <div class="d-flex gap-2">
                    <!-- Date Range Selector -->
                    <div class="d-flex align-items-center gap-2">
                        <input type="date" v-model="filterStartDate" class="form-control form-control-sm" @change="fetchAllData">
                        <span class="text-muted">-</span>
                        <input type="date" v-model="filterEndDate" class="form-control form-control-sm" @change="fetchAllData">
                    </div>
                     
                     <button v-if="isAdmin" class="btn btn-teal rounded-pill shadow-sm px-4" @click="openModal">
                        <i class="fas fa-plus me-1"></i> Nuevo Movimiento
                     </button>
                </div>
            </div>

            <!-- SUMMARY CARDS - ROW 1: Core Balance -->
            <div class="row g-3 mb-3">
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
                        <p class="text-muted x-small mb-0">Incluye donativos en efectivo y compras de emergencia.</p>
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

            <!-- SUMMARY CARDS - ROW 2: Needs & Donations -->
            <div class="row g-3 mb-4">
                <!-- PENDING NEEDS -->
                <div class="col-md-6">
                    <div class="card border-0 shadow-sm p-3 h-100 border-start border-4 border-warning">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <h6 class="text-muted small fw-bold text-uppercase mb-1">Necesidades Pendientes</h6>
                                <p class="text-muted x-small mb-2">Valor estimado de solicitudes aprobadas sin surtir</p>
                            </div>
                            <i class="fas fa-clock fa-lg text-warning opacity-50"></i>
                        </div>
                        <h3 class="fw-bold text-warning mb-0">{{ formatCurrency(pendingNeedsValue) }}</h3>
                        <small class="text-muted">Por cubrir (compra o donativo)</small>
                    </div>
                </div>

                <!-- DONATION SAVINGS -->
                <div class="col-md-6">
                     <div class="card border-0 shadow-sm p-3 h-100 border-start border-4 border-success">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <h6 class="text-muted small fw-bold text-uppercase mb-1">Ahorro por Donativos</h6>
                                <p class="text-muted x-small mb-2">Valor de insumos recibidos en especie</p>
                            </div>
                            <i class="fas fa-hand-holding-heart fa-lg text-success opacity-50"></i>
                        </div>
                        <h3 class="fw-bold text-success mb-0">{{ formatCurrency(donationSavings) }}</h3>
                        <small class="text-muted">No se tuvo que comprar</small>
                     </div>
                </div>
            </div>

            <!-- FILTERS & LIST -->
             <div class="card border-0 shadow-sm rounded-4">
                 <div class="card-header bg-white border-0 pt-4 px-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
                     <h6 class="fw-bold mb-0">Movimientos del Mes</h6>
                     <div class="d-flex gap-2 flex-wrap">
                         <!-- Type Filter -->
                         <div class="btn-group btn-group-sm">
                             <button class="btn btn-outline-secondary" :class="{active: filterType === 'ALL'}" @click="filterType = 'ALL'">Todos</button>
                             <button class="btn btn-outline-success" :class="{active: filterType === 'INGRESO'}" @click="filterType = 'INGRESO'">Ingresos</button>
                             <button class="btn btn-outline-danger" :class="{active: filterType === 'EGRESO'}" @click="filterType = 'EGRESO'">Egresos</button>
                         </div>
                         <!-- Category Filter -->
                         <select v-model="filterCategory" class="form-select form-select-sm" style="max-width: 180px;">
                             <option value="ALL">Todas categorías</option>
                             <option v-for="cat in categories" :key="cat.name" :value="cat.name">{{ cat.display_name }}</option>
                         </select>
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
                                     <td class="fw-bold text-dark">
                                         {{ rec.concept }}
                                         <div v-if="rec.subcategory" class="x-small text-muted">{{ rec.subcategory }}</div>
                                     </td>
                                     <td>
                                         <span class="badge bg-light text-dark border">
                                             <i v-if="getCategoryIcon(rec.category)" :class="['fas', getCategoryIcon(rec.category), 'me-1']"></i>
                                             {{ getCategoryDisplayName(rec.category) }}
                                         </span>
                                     </td>
                                     <td>
                                         <span class="badge" :class="rec.frequency === 'REGULAR' ? 'bg-primary-subtle text-primary' : 'bg-warning-subtle text-warning-emphasis'">
                                             {{ rec.frequency || 'EVENTUAL' }}
                                         </span>
                                     </td>
                                     <td class="text-end pe-4 fw-bold" :class="rec.type === 'INGRESO' || rec.type === 'IN' ? 'text-success' : 'text-danger'">
                                         {{ rec.type === 'INGRESO' || rec.type === 'IN' ? '+' : '-' }} {{ formatCurrency(rec.amount) }}
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
                                <select v-model="form.type" class="form-select" required @change="form.category = ''">
                                    <option value="INGRESO">Ingreso (+)</option>
                                    <option value="EGRESO">Egreso (-)</option>
                                </select>
                            </div>
                            <div class="col-6 mb-3">
                                <label class="form-label small fw-bold text-muted">Frecuencia</label>
                                 <select v-model="form.frequency" class="form-select" required>
                                    <option value="EVENTUAL">Eventual / Único</option>
                                    <option value="REGULAR">Regular / Recurrente</option>
                                </select>
                            </div>
                        </div>

                        <!-- Recurrence Options -->
                        <div v-if="form.frequency === 'REGULAR'" class="card bg-light border-0 p-3 mb-3">
                            <h6 class="text-teal small fw-bold mb-2">Configuración de Recurrencia</h6>
                            <div class="row">
                                <div class="col-6">
                                    <label class="form-label x-small text-muted">Repetir cada:</label>
                                    <select v-model="form.recurrence_type" class="form-select form-select-sm">
                                        <option value="MONTHLY">Mes</option>
                                        <option value="WEEKLY">Semana</option>
                                        <option value="BIWEEKLY">Quincena</option>
                                        <option value="YEARLY">Año</option>
                                    </select>
                                </div>
                                <div class="col-6">
                                    <label class="form-label x-small text-muted">Cantidad de veces:</label>
                                    <input type="number" v-model="form.recurrence_total" class="form-control form-control-sm" min="2" max="60">
                                </div>
                                <div class="col-12 mt-2">
                                    <small class="text-muted x-small">
                                        <i class="fas fa-info-circle me-1"></i>
                                        Se generarán <strong>{{ form.recurrence_total }}</strong> registros individuales hacia el futuro.
                                    </small>
                                </div>
                            </div>
                        </div>

                        <div class="mb-3">
                            <label class="form-label small fw-bold text-muted">Categoría</label>
                            <select v-model="form.category" class="form-select" required>
                                <option value="" disabled>Selecciona una categoría...</option>
                                <option v-for="cat in filteredCategories" :key="cat.name" :value="cat.name">
                                    {{ cat.display_name }}
                                </option>
                            </select>
                        </div>

                        <div v-if="form.category === 'SERVICIOS'" class="mb-3">
                            <label class="form-label small fw-bold text-muted">Subcategoría (Servicio)</label>
                            <select v-model="form.subcategory" class="form-select">
                                <option value="">Sin especificar</option>
                                <option value="Luz">Luz (CFE)</option>
                                <option value="Gas">Gas</option>
                                <option value="Agua">Agua</option>
                                <option value="Internet">Internet / Teléfono</option>
                                <option value="Otro">Otro servicio</option>
                            </select>
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
                            <label class="form-label small fw-bold text-muted">Concepto / Descripción</label>
                            <input type="text" v-model="form.concept" class="form-control" placeholder="Ej. Renta Enero, Donativo Sr. Pérez..." required>
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
const { fetchPendingNeedsValue, fetchDonationSavings, fetchCategories, calculateMonthlyBalance } = useFinanceMetrics()

const isAdmin = computed(() => profile.value?.role === 'ADMIN')

// State
const records = ref<any[]>([])
const categories = ref<any[]>([])
const loading = ref(true)
const submitting = ref(false)
const showModal = ref(false)
// const selectedMonth = ref(new Date().toISOString().slice(0, 7)) // YYYY-MM REPLACED
const now = new Date()
const filterStartDate = ref(new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0])
const filterEndDate = ref(new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0])
const filterType = ref('ALL')
const filterCategory = ref('ALL')

// Extra Metrics
const pendingNeedsValue = ref(0)
const donationSavings = ref(0)

// Form
const form = reactive({
    id: null as string | null,
    type: 'EGRESO',
    frequency: 'EVENTUAL',
    category: '',
    subcategory: '',
    date_occurred: new Date().toISOString().split('T')[0],
    amount: 0,
    concept: '',
    // Recurrence
    recurrence_type: 'MONTHLY',
    recurrence_total: 12
})

// Computed: Balance
const balance = computed(() => calculateMonthlyBalance(records.value))

// Computed: Filtered categories for form (based on type)
const filteredCategories = computed(() => {
    return categories.value.filter(c => c.type === form.type)
})

// Computed: Filtered records for table
const filteredRecords = computed(() => {
    let result = records.value
    
    if (filterType.value !== 'ALL') {
        result = result.filter(r => r.type === filterType.value || 
            (filterType.value === 'INGRESO' && r.type === 'IN') ||
            (filterType.value === 'EGRESO' && r.type === 'OUT'))
    }
    
    if (filterCategory.value !== 'ALL') {
        result = result.filter(r => r.category === filterCategory.value)
    }
    
    return result
})

// Category helpers
const getCategoryDisplayName = (catName: string) => {
    const cat = categories.value.find(c => c.name === catName)
    return cat?.display_name || catName || 'General'
}

const getCategoryIcon = (catName: string) => {
    const cat = categories.value.find(c => c.name === catName)
    return cat?.icon || null
}

// METHODS
const formatCurrency = (val: number) => {
    return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(val)
}

const fetchAllData = async () => {
    loading.value = true
    
    // Fetch categories
    categories.value = await fetchCategories()
    
    // Fetch records for selected date range
    // const [year, month] = selectedMonth.value.split('-')
    // const startDate = `${selectedMonth.value}-01`
    // const endDate = new Date(Number(year), Number(month), 0).toISOString().split('T')[0]

    const { data, error } = await supabase.schema('app_carelink')
        .from('finance_records')
        .select('*')
        .select('*')
        .gte('date_occurred', filterStartDate.value)
        .lte('date_occurred', filterEndDate.value)
        .order('date_occurred', { ascending: false })
    
    if (error) console.error(error)
    records.value = data || []
    
    // Fetch extra metrics
    pendingNeedsValue.value = await fetchPendingNeedsValue()
    donationSavings.value = await fetchDonationSavings()
    
    loading.value = false
}

const openModal = (record: any = null) => {
    if (record && record.id) {
        // Edit Mode
        form.id = record.id
        form.type = record.type === 'IN' ? 'INGRESO' : (record.type === 'OUT' ? 'EGRESO' : record.type)
        form.frequency = record.frequency || 'EVENTUAL'
        form.category = record.category || ''
        form.subcategory = record.subcategory || ''
        form.date_occurred = record.date_occurred
        form.amount = record.amount
        form.concept = record.concept
    } else {
        // Create Mode
        form.id = null
        form.type = 'EGRESO'
        form.frequency = 'EVENTUAL'
        form.category = ''
        form.subcategory = ''
        form.amount = 0
        form.concept = ''
        form.date_occurred = new Date().toISOString().split('T')[0]
        
        // Reset recurrence defaults
        form.recurrence_type = 'MONTHLY'
        form.recurrence_total = 12
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
        let error

        if (form.id) {
            // EDIT EXISTING
            const payload = {
                organization_id: organizationId.value,
                date_occurred: form.date_occurred,
                type: form.type,
                frequency: form.frequency,
                amount: form.amount,
                concept: form.concept,
                category: form.category,
                subcategory: form.subcategory || null,
                recorded_by: profile.value?.id
            }
            const res = await supabase.schema('app_carelink').from('finance_records').update(payload).eq('id', form.id)
            error = res.error
        } else {
            // NEW RECORD (HANDLE RECURRENCE)
            const recordsToInsert = []
            
            if (form.frequency === 'REGULAR' && form.recurrence_total > 1) {
                // Generate Series
                const recurrenceId = crypto.randomUUID() // Client-side UUID generation if available or use a library. 
                // Browsers usually support crypto.randomUUID()
                
                let baseDate = new Date(form.date_occurred + 'T12:00:00') // Avoid timezone shift
                
                for (let i = 0; i < form.recurrence_total; i++) {
                    let nextDate = new Date(baseDate)
                    
                    // Increment based on type
                    if (form.recurrence_type === 'MONTHLY') {
                        nextDate.setMonth(baseDate.getMonth() + i)
                    } else if (form.recurrence_type === 'WEEKLY') {
                        nextDate.setDate(baseDate.getDate() + (i * 7))
                    } else if (form.recurrence_type === 'BIWEEKLY') {
                         nextDate.setDate(baseDate.getDate() + (i * 14))
                    } else if (form.recurrence_type === 'YEARLY') {
                        nextDate.setFullYear(baseDate.getFullYear() + i)
                    }

                    recordsToInsert.push({
                        organization_id: organizationId.value,
                        date_occurred: nextDate.toISOString().split('T')[0],
                        type: form.type,
                        frequency: form.frequency,
                        amount: form.amount,
                        concept: `${form.concept} (${i + 1}/${form.recurrence_total})`,
                        category: form.category,
                        subcategory: form.subcategory || null,
                        recorded_by: profile.value?.id,
                        recurrence_id: recurrenceId,
                        recurrence_total: form.recurrence_total,
                        recurrence_index: i + 1,
                        recurrence_type: form.recurrence_type
                    })
                }
            } else {
                // Single Record
                recordsToInsert.push({
                    organization_id: organizationId.value,
                    date_occurred: form.date_occurred,
                    type: form.type,
                    frequency: form.frequency,
                    amount: form.amount,
                    concept: form.concept,
                    category: form.category,
                    subcategory: form.subcategory || null,
                    recorded_by: profile.value?.id
                })
            }

            const res = await supabase.schema('app_carelink').from('finance_records').insert(recordsToInsert)
            error = res.error
        }
        
        if (error) throw error
        
        alert(form.id ? 'Movimiento actualizado.' : 'Movimiento registrado.')
        closeModal()
        await fetchAllData()
        
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
        await fetchAllData()
    } catch (e: any) {
        alert('Error: ' + e.message)
    }
}

onMounted(() => {
    fetchAllData()
})
</script>
