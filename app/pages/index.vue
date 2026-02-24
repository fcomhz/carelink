<template>
  <div id="sec-anuncios" class="section-view container-fluid px-0">
    <div class="row justify-content-center">
        <!-- FEED CENTERED -->
        <div class="col-lg-8 mb-4">
            <div class="d-flex justify-content-between align-items-center mb-3 pb-2 border-bottom">
                <h6 class="text-teal fw-bold mb-0"><i class="fas fa-bullhorn me-2"></i>TABLERO INFORMÁTICO</h6>
                <button v-if="isAdmin" class="btn btn-teal btn-sm rounded-pill px-3 shadow-sm" @click="openPostModal">
                    <i class="fas fa-plus me-1"></i> Nuevo Aviso
                </button>
            </div>

            <div id="feed-anuncios">
                <div v-if="loading" class="text-center py-5">
                    <div class="spinner-border text-teal" role="status"></div>
                </div>
                
                <div v-else class="post-list">
                    <div v-for="post in posts" :key="post.id" class="card card-premium mb-4 shadow-sm fw-light border-0 animate-up">
                        <div v-if="post.image_url" class="card-img-top-container position-relative bg-light" style="max-height: 400px; overflow: hidden; border-radius: 12px 12px 0 0;">
                            <!-- Priority Badge Overlay -->
                            <div v-if="post.priority === 'URGENTE'" class="position-absolute top-0 end-0 m-3 badge bg-danger text-white shadow-sm border border-light">
                                <i class="fas fa-exclamation-circle me-1"></i> URGENTE
                            </div>
                             <!-- Status Badge for Admin -->
                            <div v-if="isAdmin && post.status === 'INACTIVO'" class="position-absolute top-0 start-0 m-3 badge bg-secondary text-white shadow-sm border border-light">
                                INACTIVO
                            </div>

                            <img :src="post.image_url" class="w-100 h-100 object-fit-cover" :alt="post.title">
                        </div>
                        <div class="card-body p-4">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <h5 class="fw-bold text-dark mb-1">{{ post.title }}</h5>
                                    <div class="d-flex align-items-center gap-2">
                                        <!-- Fallback badge if no image to show priority -->
                                        <span v-if="!post.image_url && post.priority === 'URGENTE'" class="badge bg-danger rounded-pill px-2 py-1 x-small fw-bold">URGENTE</span>
                                        
                                        <span class="badge bg-teal-subtle text-teal rounded-pill px-2 py-1 x-small fw-bold">
                                            {{ post.audience_role === 'TODOS' ? 'GLOBAL' : post.audience_role }}
                                        </span>
                                        <small class="text-muted x-small">
                                            <i class="far fa-clock me-1"></i>{{ new Date(post.created_at).toLocaleDateString() }}
                                        </small>
                                    </div>
                                </div>
                                <div v-if="isAdmin" class="dropdown position-relative">
                                    <button class="btn btn-sm btn-link text-muted" type="button" @click="activeMenu = activeMenu === post.id ? null : post.id">
                                        <i class="fas fa-ellipsis-v"></i>
                                    </button>
                                    <ul v-if="activeMenu === post.id" class="dropdown-menu dropdown-menu-end border-0 shadow d-block show animate-up" style="position: absolute; right: 0; top: 100%; z-index: 1000;">
                                        <li><a class="dropdown-item py-2" href="#" @click.prevent="editPost(post); activeMenu = null"><i class="fas fa-edit me-2 text-primary"></i>Editar</a></li>
                                        <li><a class="dropdown-item py-2 text-danger" href="#" @click.prevent="openDeletePostModal(post); activeMenu = null"><i class="fas fa-trash me-2"></i>Eliminar</a></li>
                                    </ul>
                                </div>
                            </div>
                            <p class="text-secondary mb-3 mt-3" style="line-height: 1.6; white-space: pre-wrap;">{{ post.body }}</p>

                            <!-- PER POST RELATED LINKS -->
                            <div v-if="post.related_links && post.related_links.length > 0" class="mt-4 pt-3 border-top">
                                <h6 class="x-small text-uppercase text-muted fw-bold mb-2"><i class="fas fa-link me-1"></i> Enlaces Relacionados</h6>
                                <div class="d-flex flex-wrap gap-2">
                                    <a v-for="(link, idx) in post.related_links" :key="idx" 
                                       :href="link.url" target="_blank" 
                                       class="btn btn-sm btn-light border rounded-pill px-3">
                                       <i class="fas fa-external-link-alt small me-1 text-teal"></i> {{ link.title }}
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div v-if="posts.length === 0" class="text-center py-5 text-muted bg-light rounded-4 border border-dashed">
                        <div class="mb-3 opacity-25"><i class="fas fa-newspaper fa-3x"></i></div>
                        <p class="fw-bold mb-1">Sin noticias recientes</p>
                        <small>El tablero está limpio por ahora.</small>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- MODAL POST -->
    <div v-if="showPostModal" class="modal d-block" style="background: rgba(0,0,0,0.5)">
        <div class="modal-dialog modal-dialog-centered modal-lg">
            <div class="modal-content rounded-4 border-0 shadow">
                <div class="modal-header border-0 pb-0">
                    <h5 class="fw-bold">{{ postForm.id ? 'Editar Aviso' : 'Nuevo Aviso' }}</h5>
                    <button type="button" class="btn-close" @click="showPostModal = false"></button>
                </div>
                <div class="modal-body">
                    <form @submit.prevent="savePost">
                        <div class="row">
                            <div class="col-md-7 border-end">
                                <div class="mb-3">
                                    <label class="form-label small text-muted">Título</label>
                                    <input v-model="postForm.title" type="text" class="form-control" required placeholder="Ej: Mantenimiento Programado">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label small text-muted">Mensaje</label>
                                    <textarea v-model="postForm.body" class="form-control" rows="8" required placeholder="Escribe el contenido del aviso..."></textarea>
                                </div>
                            </div>
                            <!-- POST SETTINGS (Audience & Links) -->
                            <div class="col-md-5">
                                <div class="mb-3">
                                    <label class="form-label small text-muted">Prioridad</label>
                                    <select v-model="postForm.priority" class="form-select bg-light border-0">
                                        <option value="REGULAR">Regular</option>
                                        <option value="URGENTE">Urgente</option>
                                    </select>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label small text-muted">Estado</label>
                                    <select v-model="postForm.status" class="form-select bg-light border-0">
                                        <option value="ACTIVO">Activo (Visible)</option>
                                        <option value="INACTIVO">Inactivo (Oculto)</option>
                                    </select>
                                </div>

                                <div class="mb-3">
                                    <label class="form-label small text-muted">Imagen (Opcional)</label>
                                    <input type="file" @change="handleImageUpload" accept="image/*" capture="environment" class="form-control">
                                    <div v-if="imagePreview" class="mt-2 text-center bg-light rounded p-2 position-relative">
                                        <button @click="removeImage" type="button" class="btn-close position-absolute top-0 end-0 m-2"></button>
                                        <img :src="imagePreview" class="rounded" style="max-height: 150px;">
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-2">
                                        <label class="form-label small text-muted mb-0">Enlaces de Interés</label>
                                        <button type="button" @click="addLinkRow" class="btn btn-sm btn-link text-teal p-0">+ Agregar</button>
                                    </div>
                                    <div class="bg-light p-2 rounded">
                                        <div v-for="(link, idx) in postForm.links" :key="idx" class="mb-2 border-bottom pb-2">
                                            <input v-model="link.title" type="text" class="form-control form-control-sm mb-1" placeholder="Título (ej: Formulario PDF)">
                                            <div class="input-group input-group-sm">
                                                <input v-model="link.url" type="url" class="form-control" placeholder="https://...">
                                                <button type="button" class="btn btn-outline-danger" @click="removeLinkRow(idx)"><i class="fas fa-times"></i></button>
                                            </div>
                                        </div>
                                        <div v-if="postForm.links.length === 0" class="text-center text-muted x-small py-3">
                                            Sin enlaces adjuntos.
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
        
                        <div class="d-grid mt-3">
                            <button type="submit" class="btn btn-teal py-2 rounded-3" :disabled="uploading">
                                {{ uploading ? 'Guardando...' : (postForm.id ? 'Guardar Cambios' : 'Publicar Aviso') }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- PREMIUM DELETE CONFIRMATION MODAL -->
    <div v-if="postToDelete" class="modal d-block" style="background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); z-index: 2000;" @click.self="postToDelete = null">
        <div class="modal-dialog modal-dialog-centered" style="max-width: 400px;">
            <div class="modal-content rounded-4 border-0 shadow-lg animate-up">
                <div class="modal-body p-4 text-center">
                    <div class="mb-4">
                        <div class="bg-danger-subtle text-danger rounded-circle d-inline-flex align-items-center justify-content-center mb-3 shadow-sm" style="width: 70px; height: 70px;">
                            <i class="fas fa-trash-alt fa-2x"></i>
                        </div>
                        <h5 class="fw-bold text-dark">¿Eliminar Aviso?</h5>
                        <p class="text-muted small px-2">
                            Estás a punto de eliminar <strong>"{{ postToDelete.title }}"</strong>. 
                        </p>
                    </div>
                    <div class="d-grid gap-2">
                        <button class="btn btn-danger py-2 fw-bold rounded-pill" @click="confirmDeletePost" :disabled="uploading">
                            {{ uploading ? 'Eliminando...' : 'Eliminar Aviso' }}
                        </button>
                        <button class="btn btn-light py-2 rounded-pill text-muted fw-bold" @click="postToDelete = null" :disabled="uploading">
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
const { profile, organizationId, fetchProfile } = useOrganization()
const { notifyNewAnnouncement } = usePushNotificationSender()
const supabase = useSupabaseClient()

// State
const posts = ref<any[]>([])
const loading = ref(true)
const uploading = ref(false)
const showPostModal = ref(false)
const activeMenu = ref<string | null>(null)
const postToDelete = ref<any>(null)

const postForm = reactive({
    id: null as string | null,
    title: '',
    body: '',
    audience_role: 'TODOS',
    priority: 'REGULAR',
    status: 'ACTIVO',
    imageFile: null as File | null,
    imageUrl: null as string | null,
    links: [] as { title: string, url: string }[]
})
const imagePreview = ref<string | null>(null)

const isAdmin = computed(() => profile.value?.role === 'ADMIN')

// Data Fetching
const fetchPosts = async () => {
    loading.value = true
    let query = supabase
        .from('announcements')
        .select('*')
        .order('priority', { ascending: false }) // URGENTE (Z) vs REGULAR (A)? No, need custom order or trick. 
        // Actually, 'URGENTE' > 'REGULAR'. So descending works ('U' > 'R').
        .order('created_at', { ascending: false })

    // If not Admin, filter ACTIVO
    if (!isAdmin.value) {
        query = query.eq('status', 'ACTIVO')
    }

    const { data } = await query
    posts.value = data || []
    loading.value = false
}

// Logic
const openPostModal = () => {
    // Reset Form
    Object.assign(postForm, {
        id: null,
        title: '',
        body: '',
        audience_role: 'TODOS',
        priority: 'REGULAR',
        status: 'ACTIVO',
        imageFile: null,
        imageUrl: null,
        links: []
    })
    imagePreview.value = null
    showPostModal.value = true
}

const editPost = (post: any) => {
    Object.assign(postForm, {
        id: post.id,
        title: post.title,
        body: post.body,
        audience_role: post.audience_role,
        priority: post.priority,
        status: post.status,
        imageFile: null,
        imageUrl: post.image_url,
        links: JSON.parse(JSON.stringify(post.related_links || []))
    })
    imagePreview.value = post.image_url
    showPostModal.value = true
}

const handleImageUpload = (event: Event) => {
    const input = event.target as HTMLInputElement
    if (input.files && input.files[0]) {
        postForm.imageFile = input.files[0]
        imagePreview.value = URL.createObjectURL(input.files[0])
    }
}

const removeImage = () => {
    postForm.imageFile = null
    imagePreview.value = null
}

const addLinkRow = () => {
    postForm.links.push({ title: '', url: '' })
}

const removeLinkRow = (idx: number) => {
    postForm.links.splice(idx, 1)
}

const savePost = async () => {
    if (!profile.value?.id || !organizationId.value) return
    uploading.value = true

    let imageUrl = postForm.imageUrl

    try {
        // Filter empty links
        const validLinks = postForm.links.filter(l => l.title.trim() !== '' && l.url.trim() !== '')

        // 1. Upload Image if exists
        if (postForm.imageFile) {
            const fileExt = postForm.imageFile.name.split('.').pop()
            const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`
            const filePath = `${fileName}`

            const { error: uploadError } = await supabase.storage
                .from('posts')
                .upload(filePath, postForm.imageFile)

            if (uploadError) throw uploadError

            const { data: publicData } = supabase.storage
                .from('posts')
                .getPublicUrl(filePath)
            imageUrl = publicData.publicUrl
        }

        // 2. Upsert Post
        const postData: any = {
            organization_id: organizationId.value,
            title: postForm.title,
            body: postForm.body,
            audience_role: postForm.audience_role,
            priority: postForm.priority,
            status: postForm.status,
            image_url: imageUrl,
            author_id: profile.value.id,
            related_links: validLinks
        }

        if (postForm.id) postData.id = postForm.id

        const { error } = await supabase.from('announcements').upsert(postData)

        if (error) throw error

        // 3. Notify if new post and active
        if (!postForm.id && postForm.status === 'ACTIVO') {
            await notifyNewAnnouncement(postForm.title)
        }

        showPostModal.value = false
        await fetchPosts()

    } catch (e: any) {
        alert('Error al publicar: ' + e.message)
    } finally {
        uploading.value = false
    }
}

const openDeletePostModal = (post: any) => {
    postToDelete.value = post
}

const confirmDeletePost = async () => {
    if (!postToDelete.value) return
    uploading.value = true
    try {
        const { error } = await supabase.from('announcements').delete().eq('id', postToDelete.value.id)
        if (error) throw error
        postToDelete.value = null
        await fetchPosts()
    } catch (e: any) {
        alert('Error: ' + e.message)
    } finally {
        uploading.value = false
    }
}

onMounted(async () => {
    if (!profile.value) await fetchProfile()
    await fetchPosts()
})
</script>
