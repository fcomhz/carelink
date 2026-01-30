<template>
  <div>
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h6 class="text-teal fw-bold mb-0">ADMINISTRACIÓN</h6>
    </div>

    <!-- TABS NAVIGATION -->
    <ul class="nav nav-pills mb-4">
        <li class="nav-item">
            <button class="nav-link rounded-pill px-4" 
                :class="{ active: activeTab === 'general' }"
                @click="activeTab = 'general'">
                General
            </button>
        </li>
        <li class="nav-item">
            <button class="nav-link rounded-pill px-4" 
                :class="{ active: activeTab === 'categories' }"
                @click="activeTab = 'categories'">
                Categorías Artículos/insumos
            </button>
        </li>
        <li class="nav-item">
            <button class="nav-link rounded-pill px-4" 
                :class="{ active: activeTab === 'centers' }"
                @click="activeTab = 'centers'">
                Centros de Acopio
            </button>
        </li>
        <li class="nav-item">
            <button class="nav-link rounded-pill px-4" 
                :class="{ active: activeTab === 'bank' }"
                @click="activeTab = 'bank'">
                Datos Bancarios
            </button>
        </li>
    </ul>

    <div class="tab-content">
        <!-- TAB 1: GENERAL (Users & Org) -->
        <div v-if="activeTab === 'general'" class="fade show active">
            <!-- Org Settings -->
            <div class="card p-3 border-0 shadow-sm mb-4 bg-teal-light">
                <h6 class="small fw-bold text-muted mb-2">NOMBRE DE ORGANIZACIÓN</h6>
                <form @submit.prevent="updateOrgName" class="d-flex gap-2">
                    <input v-model="orgNameModel" class="form-control" placeholder="Nombre de la Organización" required>
                    <button type="submit" class="btn btn-teal px-4" :disabled="updatingOrg">
                    <i v-if="updatingOrg" class="fas fa-spinner fa-spin"></i>
                    <span v-else>Guardar</span>
                    </button>
                </form>
            </div>

            <!-- Quick Actions -->
            <div class="row mb-4">
                <div class="col-md-6 mb-3 mb-md-0">
                    <NuxtLink to="/entradas" class="card p-3 border-0 shadow-sm text-decoration-none card-hover bg-white h-100">
                        <div class="d-flex align-items-center gap-3">
                            <div class="bg-light rounded-circle d-flex align-items-center justify-content-center text-teal" style="width: 50px; height: 50px;">
                                <i class="fas fa-boxes fa-lg"></i>
                            </div>
                            <div>
                                <h6 class="fw-bold text-dark mb-1">Entradas de Almacén</h6>
                                <small class="text-muted d-block">Validar recepciones y registrar donativos.</small>
                            </div>
                            <div class="ms-auto text-muted"><i class="fas fa-chevron-right"></i></div>
                        </div>
                    </NuxtLink>
                </div>
                <div class="col-md-6">
                    <NuxtLink to="/almacen" class="card p-3 border-0 shadow-sm text-decoration-none card-hover bg-white h-100">
                        <div class="d-flex align-items-center gap-3">
                            <div class="bg-light rounded-circle d-flex align-items-center justify-content-center text-danger" style="width: 50px; height: 50px;">
                                <i class="fas fa-warehouse fa-lg"></i>
                            </div>
                            <div>
                                <h6 class="fw-bold text-dark mb-1">Almacén e Inventario</h6>
                                <small class="text-muted d-block">Gestionar stock y registrar consumo interno.</small>
                            </div>
                            <div class="ms-auto text-muted"><i class="fas fa-chevron-right"></i></div>
                        </div>
                    </NuxtLink>
                </div>
            </div>

            <div class="d-flex justify-content-between align-items-center mb-3">
                <h6 class="text-teal fw-bold mb-0">DIRECTORIO DE USUARIOS</h6>
                <button class="btn btn-teal btn-sm rounded-circle" @click="openUserModal()">
                <i class="fas fa-user-plus"></i>
                </button>
            </div>

            <!-- User List -->
            <div v-if="loadingUsers" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>
            
            <div v-else id="feed-users" class="row g-2">
                <div v-for="u in users" :key="u.id" class="col-12">
                    <div class="card p-3 border-0 shadow-sm">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                        <div class="fw-bold">{{ u.full_name }}</div>
                        <small class="text-muted d-block">{{ u.email }}</small>
                        <span class="badge bg-teal-light text-teal x-small mt-1">{{ u.role }}</span>
                        </div>
                        <div>
                        <button class="btn btn-sm btn-light me-1" @click="openUserModal(u)">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-light text-danger" @click="deleteUser(u.id)">
                            <i class="fas fa-trash"></i>
                        </button>
                        </div>
                    </div>
                    </div>
                </div>
                <div v-if="users.length === 0" class="text-center py-4 text-muted small">
                    No hay usuarios registrados en esta organización.
                </div>
            </div>
        </div>

        <!-- TAB 2: CATEGORIES -->
        <div v-if="activeTab === 'categories'" class="fade show active">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h6 class="text-teal fw-bold mb-0">CATEGORÍAS DE INSUMOS</h6>
                <button class="btn btn-teal btn-sm rounded-circle" @click="openCategoryModal()">
                   <i class="fas fa-plus"></i>
                </button>
            </div>

            <div v-if="loadingCats" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>

            <div v-else class="row g-2">
                <div v-for="cat in categories" :key="cat.id" class="col-md-6">
                    <div class="card p-3 border-0 shadow-sm h-100">
                        <div class="d-flex justify-content-between align-items-start">
                            <div class="me-2">
                                <h6 class="fw-bold mb-1">{{ cat.name }}</h6>
                                <p class="text-muted small mb-0">{{ cat.description || 'Sin descripción' }}</p>
                            </div>
                            <div class="d-flex gap-1">
                                <button class="btn btn-sm btn-light text-muted" @click="openCategoryModal(cat)"><i class="fas fa-edit"></i></button>
                                <button class="btn btn-sm btn-light text-danger" @click="deleteCategory(cat.id)"><i class="fas fa-trash"></i></button>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-if="categories.length === 0" class="col-12 text-center py-5 text-muted">
                    <i class="fas fa-tags fa-2x mb-3 opacity-25"></i>
                    <p>No hay categorías definidas. Crea algunas para organizar los pedidos.</p>
                </div>
            </div>
        </div>

        <!-- TAB 3: COLLECTION CENTERS -->
        <div v-if="activeTab === 'centers'" class="fade show active">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h6 class="text-teal fw-bold mb-0">LUGARES DE ENTREGA (ACOPIO)</h6>
                <button class="btn btn-teal btn-sm rounded-circle" @click="openCenterModal()">
                   <i class="fas fa-plus"></i>
                </button>
            </div>

            <div v-if="loadingCenters" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>

            <div v-else class="row g-2">
                <div v-for="center in centers" :key="center.id" class="col-md-6">
                    <div class="card p-3 border-0 shadow-sm h-100">
                        <div class="d-flex justify-content-between align-items-start">
                            <div class="me-2">
                                <h6 class="fw-bold mb-1">{{ center.name }}</h6>
                                <p class="text-muted small mb-1"><i class="fas fa-map-marker-alt me-1"></i> {{ center.address }}</p>
                                <p class="text-muted x-small mb-1"><i class="far fa-clock me-1"></i> {{ center.schedule }}</p>
                                <a v-if="center.google_maps_link" :href="center.google_maps_link" target="_blank" class="x-small text-teal text-decoration-none">
                                    <i class="fas fa-external-link-alt"></i> Ver Mapa
                                </a>
                            </div>
                            <div class="d-flex gap-1">
                                <button class="btn btn-sm btn-light text-muted" @click="openCenterModal(center)"><i class="fas fa-edit"></i></button>
                                <button class="btn btn-sm btn-light text-danger" @click="deleteCenter(center.id)"><i class="fas fa-trash"></i></button>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-if="centers.length === 0" class="col-12 text-center py-5 text-muted">
                    <i class="fas fa-building fa-2x mb-3 opacity-25"></i>
                    <p>No hay centros de acopio registrados.</p>
                </div>
            </div>
        </div>

        <!-- TAB 4: BANK DATA -->
        <div v-if="activeTab === 'bank'" class="fade show active">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h6 class="text-teal fw-bold mb-0">CUENTAS BANCARIAS Y RECAUDACIÓN</h6>
                <button class="btn btn-teal btn-sm rounded-circle" @click="openBankModal()">
                   <i class="fas fa-plus"></i>
                </button>
            </div>

            <div v-if="loadingBanks" class="text-center py-5">
                <div class="spinner-border text-teal" role="status"></div>
            </div>

            <div v-else class="row g-2">
                <div v-for="acc in bankAccounts" :key="acc.id" class="col-md-6 col-lg-4">
                    <div class="card p-3 border-0 shadow-sm h-100 bg-white">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <h6 class="fw-bold mb-1 text-teal">{{ acc.bank_name }}</h6>
                                <p class="small text-muted mb-1 font-monospace">{{ acc.account_number || acc.clabe }}</p>
                                <p class="x-small text-muted mb-0">Bene: {{ acc.beneficiary }}</p>
                                <p v-if="acc.notes" class="x-small text-muted mt-2 fst-italic">{{ acc.notes }}</p>
                            </div>
                            <div class="d-flex gap-1">
                                <button class="btn btn-sm btn-light text-muted" @click="openBankModal(acc)"><i class="fas fa-edit"></i></button>
                                <button class="btn btn-sm btn-light text-danger" @click="deleteBank(acc.id)"><i class="fas fa-trash"></i></button>
                            </div>
                        </div>
                    </div>
                </div>
                <div v-if="bankAccounts.length === 0" class="col-12 text-center py-5 text-muted">
                    <i class="fas fa-university fa-2x mb-3 opacity-25"></i>
                    <p>No hay cuentas bancarias registradas.</p>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL USER -->
    <div v-if="showUserModal" class="modal-backdrop d-flex align-items-start justify-content-center pt-5" style="background: rgba(0,0,0,0.5); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 1050;">
      <div class="card p-4 shadow-lg w-100 mx-3 animate-up" style="max-width: 450px; max-height: 85vh; overflow-y: auto;">
        <h5 class="fw-bold text-teal mb-3">{{ editUser?.id ? 'Editar' : 'Nuevo' }} Usuario</h5>
        <form @submit.prevent="saveUser">
          <div class="mb-3">
            <label class="small fw-bold text-muted">Nombre Completo</label>
            <input v-model="userForm.full_name" class="form-control" placeholder="Ej. Ana Pérez" required>
          </div>
          <div class="mb-3">
            <label class="small fw-bold text-muted">Email</label>
            <input v-model="userForm.email" type="email" class="form-control" placeholder="correo@ejemplo.com" :disabled="!!editUser?.id" required>
          </div>
          <div class="mb-3">
            <label class="small fw-bold text-muted">Contraseña</label>
            <input v-model="userForm.password" type="password" class="form-control" :placeholder="editUser?.id ? 'Dejar en blanco para no cambiar' : 'Mínimo 6 caracteres'" :required="!editUser?.id">
          </div>
          <div class="mb-3">
            <label class="small fw-bold text-muted">Teléfono</label>
            <input v-model="userForm.phone" class="form-control" placeholder="+52 ...">
          </div>
          <div class="mb-3">
            <label class="small fw-bold text-muted">Rol</label>
            <select v-model="userForm.role" class="form-select">
              <option value="ADMIN">Administrador</option>
              <option value="ASISTENTE">Asistente</option>
              <option value="ENFERMERO">Enfermero</option>
              <option value="APORTADOR">Patrocinador</option>
            </select>
          </div>
          <div class="d-flex gap-2">
            <button type="button" class="btn btn-light flex-fill" @click="showUserModal = false">Cancelar</button>
            <button type="submit" class="btn btn-teal flex-fill" :disabled="savingUser">
              {{ savingUser ? 'Guardando...' : 'Guardar' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL CATEGORY -->
    <div v-if="showCatModal" class="modal-backdrop d-flex align-items-center justify-content-center" style="background: rgba(0,0,0,0.5); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 1060;">
        <div class="card p-4 shadow-lg w-100 mx-3 animate-up" style="max-width: 400px;">
            <h5 class="fw-bold text-teal mb-3">{{ editCat?.id ? 'Editar' : 'Nueva' }} Categoría</h5>
            <form @submit.prevent="saveCategory">
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Nombre</label>
                    <input v-model="catForm.name" class="form-control" placeholder="Ej. Higiene" required>
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Descripción</label>
                    <textarea v-model="catForm.description" class="form-control" rows="2" placeholder="Breve detalle..."></textarea>
                </div>
                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-light flex-fill" @click="showCatModal = false">Cancelar</button>
                    <button type="submit" class="btn btn-teal flex-fill" :disabled="savingCat">
                        {{ savingCat ? 'Guardando...' : 'Guardar' }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- MODAL COLLECTION CENTER -->
    <div v-if="showCenterModal" class="modal-backdrop d-flex align-items-center justify-content-center" style="background: rgba(0,0,0,0.5); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 1060;">
        <div class="card p-4 shadow-lg w-100 mx-3 animate-up" style="max-width: 450px;">
            <h5 class="fw-bold text-teal mb-3">{{ editCenter?.id ? 'Editar' : 'Nuevo' }} Centro de Acopio</h5>
            <form @submit.prevent="saveCenter">
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Nombre del Lugar</label>
                    <input v-model="centerForm.name" class="form-control" placeholder="Ej. Almacén Central" required>
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Dirección Completa</label>
                    <textarea v-model="centerForm.address" class="form-control" rows="2" placeholder="Calle, Número, Colonia, CP..." required></textarea>
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Link de Google Maps (Opcional)</label>
                    <input v-model="centerForm.google_maps_link" class="form-control" placeholder="https://maps.google.com/...">
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Horarios de Recepción</label>
                    <input v-model="centerForm.schedule" class="form-control" placeholder="Ej. Lunes a Viernes 9am - 5pm" required>
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Info de Contacto (Opcional)</label>
                    <input v-model="centerForm.contact_info" class="form-control" placeholder="Teléfono o nombre de encargado">
                </div>
                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-light flex-fill" @click="showCenterModal = false">Cancelar</button>
                    <button type="submit" class="btn btn-teal flex-fill" :disabled="savingCenter">
                        {{ savingCenter ? 'Guardando...' : 'Guardar' }}
                    </button>
                </div>
            </form>
        </div>
    </div>
    <!-- MODAL BANK ACCOUNT -->
    <div v-if="showBankModal" class="modal-backdrop d-flex align-items-center justify-content-center" style="background: rgba(0,0,0,0.5); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 1060;">
        <div class="card p-4 shadow-lg w-100 mx-3 animate-up" style="max-width: 450px;">
            <h5 class="fw-bold text-teal mb-3">{{ editBank?.id ? 'Editar' : 'Nueva' }} Cuenta Bancaria</h5>
            <form @submit.prevent="saveBank">
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Banco *</label>
                    <input v-model="bankForm.bank_name" class="form-control" placeholder="Ej. BBVA" required>
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Beneficiario *</label>
                    <input v-model="bankForm.beneficiary" class="form-control" placeholder="Ej. Carelink A.C." required>
                </div>
                <div class="row">
                    <div class="col-6 mb-3">
                         <label class="small fw-bold text-muted">No. Cuenta</label>
                         <input v-model="bankForm.account_number" class="form-control" placeholder="1234567890">
                    </div>
                    <div class="col-6 mb-3">
                         <label class="small fw-bold text-muted">CLABE</label>
                         <input v-model="bankForm.clabe" class="form-control" placeholder="18 dígitos">
                    </div>
                </div>
                <div class="mb-3">
                    <label class="small fw-bold text-muted">Notas / Referencia</label>
                    <input v-model="bankForm.notes" class="form-control" placeholder="Ej. Para donativos deducibles">
                </div>
                <div class="d-flex gap-2">
                    <button type="button" class="btn btn-light flex-fill" @click="showBankModal = false">Cancelar</button>
                    <button type="submit" class="btn btn-teal flex-fill" :disabled="savingBank">
                        {{ savingBank ? 'Guardando...' : 'Guardar' }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- MODAL CONFIRM DELETE -->
    <div v-if="showConfirmModal" class="modal-backdrop d-flex align-items-center justify-content-center" style="background: rgba(0,0,0,0.6); position: fixed; top:0; left:0; width:100%; height:100%; z-index: 2000;">
        <div class="card p-4 shadow-lg w-100 mx-3 animate-up border-0" style="max-width: 350px;">
            <div class="text-center mb-3">
                <div class="bg-danger-subtle text-danger rounded-circle d-inline-flex align-items-center justify-content-center mb-3" style="width: 60px; height: 60px; font-size: 1.5rem;">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>
                <h5 class="fw-bold text-dark">¿Estás seguro?</h5>
                <p class="text-muted small">Esta acción no se puede deshacer y podría afectar datos relacionados.</p>
            </div>
            <div class="d-flex gap-2">
                <button type="button" class="btn btn-light flex-fill" @click="showConfirmModal = false">Cancelar</button>
                <button type="button" class="btn btn-danger flex-fill" @click="executeDelete" :disabled="deleting">
                    {{ deleting ? 'Borrando...' : 'Sí, Eliminar' }}
                </button>
            </div>
        </div>
    </div>

  </div>
</template>

<script setup lang="ts">
const supabase = useSupabaseClient()
const { organizationId, organizationName, fetchProfile } = useOrganization()

const activeTab = ref('general');

// ORG & USERS STATE
const users = ref<any[]>([])
const loadingUsers = ref(true)
const savingUser = ref(false)
const showUserModal = ref(false)
const editUser = ref<any>(null)
const orgNameModel = ref('')
const updatingOrg = ref(false)

const userForm = reactive({
  full_name: '',
  email: '',
  password: '',
  phone: '',
  role: 'ASISTENTE' as any
})

// CATEGORIES STATE
const categories = ref<any[]>([])
const loadingCats = ref(true)
const showCatModal = ref(false)
const savingCat = ref(false)
const editCat = ref<any>(null)
const catForm = reactive({ name: '', description: '' })

// CENTERS STATE
const centers = ref<any[]>([])
const loadingCenters = ref(true)
const showCenterModal = ref(false)
const savingCenter = ref(false)
const editCenter = ref<any>(null)
const centerForm = reactive({
    name: '',
    address: '',
    google_maps_link: '',
    schedule: '',
    contact_info: ''
})

// BANK STATE
const bankAccounts = ref<any[]>([])
const loadingBanks = ref(true)
const showBankModal = ref(false)
const savingBank = ref(false)
const editBank = ref<any>(null)
const bankForm = reactive({
    bank_name: '',
    account_number: '',
    clabe: '',
    beneficiary: '',
    notes: ''
})

// CONFIRM MODAL STATE
const showConfirmModal = ref(false)
const deleting = ref(false)
const pendingDelete = ref<{ id: string, type: 'user' | 'category' | 'center' | 'bank' } | null>(null)


// --- USERS & ORG LOGIC ---

const updateOrgName = async () => {
    if (!organizationId.value) return
    updatingOrg.value = true
    const { error } = await supabase.schema('app_carelink')
        .from('organizations')
        .update({ name: orgNameModel.value })
        .eq('id', organizationId.value)
    
    if (!error) {
        alert('Nombre de organización actualizado')
        await fetchProfile()
    } else {
        alert('Error al actualizar: ' + error.message)
    }
    updatingOrg.value = false
}

const fetchUsers = async () => {
  loadingUsers.value = true
  const { data, error } = await supabase.schema('app_carelink')
    .from('profiles')
    .select('*')
    .order('full_name')
  
  if (!error) users.value = data || []
  loadingUsers.value = false
}

const openUserModal = (user: any = null) => {
  editUser.value = user
  if (user) {
    userForm.full_name = user.full_name
    userForm.email = user.email
    userForm.password = ''
    userForm.phone = user.phone
    userForm.role = user.role
  } else {
    Object.assign(userForm, { full_name: '', email: '', password: '', phone: '', role: 'ASISTENTE' })
  }
  showUserModal.value = true
}

const saveUser = async () => {
  if (!organizationId.value) return
  savingUser.value = true
  try {
    const result = await $fetch('/api/admin/manage-user', {
      method: 'POST',
      body: {
        ...userForm,
        id: editUser.value?.id,
        organization_id: organizationId.value
      }
    }) as any

    if (result.error) throw new Error(result.error)

    showUserModal.value = false
    await fetchUsers()
  } catch (err: any) {
    alert('Error al guardar: ' + (err.message || err))
  } finally {
    savingUser.value = false
  }
}

const deleteUser = (id: string) => {
    pendingDelete.value = { id, type: 'user' }
    showConfirmModal.value = true
}

// --- CATEGORIES LOGIC ---

const fetchCategories = async () => {
    loadingCats.value = true
    const { data } = await supabase.schema('app_carelink')
        .from('categories')
        .select('*')
        .order('name')
    categories.value = data || []
    loadingCats.value = false
}

const openCategoryModal = (cat: any = null) => {
    editCat.value = cat
    if (cat) {
        catForm.name = cat.name
        catForm.description = cat.description
    } else {
        catForm.name = ''
        catForm.description = ''
    }
    showCatModal.value = true
}

const saveCategory = async () => {
    if (!organizationId.value) return
    savingCat.value = true

    const payload = {
        organization_id: organizationId.value,
        name: catForm.name,
        description: catForm.description
    }

    let promise
    if (editCat.value?.id) {
        promise = supabase.schema('app_carelink').from('categories').update(payload).eq('id', editCat.value.id)
    } else {
        promise = supabase.schema('app_carelink').from('categories').insert(payload)
    }

    const { error } = await promise
    
    if (error) alert('Error: ' + error.message)
    else {
        showCatModal.value = false
        await fetchCategories()
    }
    savingCat.value = false
}

const deleteCategory = (id: string) => {
    pendingDelete.value = { id, type: 'category' }
    showConfirmModal.value = true
}

const executeDelete = async () => {
    if (!pendingDelete.value) return
    deleting.value = true
    
    try {
        if (pendingDelete.value.type === 'user') {
            const { error } = await $fetch('/api/admin/manage-user', {
                method: 'DELETE',
                body: { id: pendingDelete.value.id }
            }) as any
            if (error) throw new Error(error)
            await fetchUsers()
        } else if (pendingDelete.value.type === 'category') {
            // Delete category logic
             const { error } = await supabase.schema('app_carelink')
                .from('categories')
                .delete()
                .eq('id', pendingDelete.value.id)
            if (error) throw error
            await fetchCategories()
        } else if (pendingDelete.value.type === 'center') {
             const { error } = await supabase.schema('app_carelink')
                .from('collection_centers')
                .delete()
                .eq('id', pendingDelete.value.id)
            if (error) throw error
            await fetchCenters()
        } else if (pendingDelete.value.type === 'bank') {
             const { error } = await supabase.schema('app_carelink')
                .from('bank_accounts')
                .delete()
                .eq('id', pendingDelete.value.id)
            if (error) throw error
            await fetchBanks()
        }
        showConfirmModal.value = false
    } catch (err: any) {
        alert('Error al eliminar: ' + (err.message || err))
    } finally {
        deleting.value = false
        pendingDelete.value = null
    }
}

// --- CENTERS LOGIC ---

const fetchCenters = async () => {
    loadingCenters.value = true
    const { data } = await supabase.schema('app_carelink')
        .from('collection_centers')
        .select('*')
        .order('created_at', { ascending: false })
    centers.value = data || []
    loadingCenters.value = false
}

const openCenterModal = (center: any = null) => {
    editCenter.value = center
    if (center) {
        centerForm.name = center.name
        centerForm.address = center.address
        centerForm.google_maps_link = center.google_maps_link
        centerForm.schedule = center.schedule
        centerForm.contact_info = center.contact_info
    } else {
        Object.assign(centerForm, { name: '', address: '', google_maps_link: '', schedule: '', contact_info: '' })
    }
    showCenterModal.value = true
}

const saveCenter = async () => {
    if (!organizationId.value) return
    savingCenter.value = true

    const payload = {
        organization_id: organizationId.value,
        ...centerForm
    }

    let promise
    if (editCenter.value?.id) {
        promise = supabase.schema('app_carelink').from('collection_centers').update(payload).eq('id', editCenter.value.id)
    } else {
        promise = supabase.schema('app_carelink').from('collection_centers').insert(payload)
    }

    const { error } = await promise
    
    if (error) alert('Error: ' + error.message)
    else {
        showCenterModal.value = false
        await fetchCenters()
    }
    savingCenter.value = false
}

const deleteCenter = (id: string) => {
    pendingDelete.value = { id, type: 'center' }
    showConfirmModal.value = true
}

// --- BANK LOGIC ---

const fetchBanks = async () => {
    loadingBanks.value = true
    const { data } = await supabase.schema('app_carelink')
        .from('bank_accounts')
        .select('*')
        .order('created_at', { ascending: false })
    bankAccounts.value = data || []
    loadingBanks.value = false
}

const openBankModal = (acc: any = null) => {
    editBank.value = acc
    if (acc) {
        bankForm.bank_name = acc.bank_name
        bankForm.account_number = acc.account_number
        bankForm.clabe = acc.clabe
        bankForm.beneficiary = acc.beneficiary
        bankForm.notes = acc.notes
    } else {
        Object.assign(bankForm, { bank_name: '', account_number: '', clabe: '', beneficiary: '', notes: '' })
    }
    showBankModal.value = true
}

const saveBank = async () => {
    if (!organizationId.value) return
    savingBank.value = true

    const payload = {
        organization_id: organizationId.value,
        ...bankForm
    }

    let promise
    if (editBank.value?.id) {
        promise = supabase.schema('app_carelink').from('bank_accounts').update(payload).eq('id', editBank.value.id)
    } else {
        promise = supabase.schema('app_carelink').from('bank_accounts').insert(payload)
    }

    const { error } = await promise
    
    if (error) alert('Error: ' + error.message)
    else {
        showBankModal.value = false
        await fetchBanks()
    }
    savingBank.value = false
}

const deleteBank = (id: string) => {
    pendingDelete.value = { id, type: 'bank' }
    showConfirmModal.value = true
}

onMounted(async () => {
  await Promise.all([fetchUsers(), fetchCategories(), fetchCenters(), fetchBanks()])
  
  watch(organizationName, (newVal) => {
      if (newVal) orgNameModel.value = newVal
  }, { immediate: true })
})
</script>
