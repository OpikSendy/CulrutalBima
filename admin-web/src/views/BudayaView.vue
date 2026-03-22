<!-- src/views/BudayaView.vue -->
<template>
  <div class="page-content">
    <div class="page-header">
      <div>
        <div class="page-title">Kelola Budaya</div>
        <div class="page-subtitle">Manajemen data budaya Kabupaten Bima</div>
      </div>
    </div>

    <DataTable
      :items="filteredData" :loading="loading" :error="error"
      search-placeholder="Cari nama budaya..."
      empty-title="Belum Ada Data Budaya"
      empty-desc="Klik tombol Tambah Budaya untuk menambahkan data pertama."
      @search="onSearch" @retry="loadData" @sort="onSort"
    >
      <template #filters>
        <select class="filter-select" v-model="filterKategori">
          <option value="">Semua Kategori</option>
          <option v-for="k in kategoriOptions" :key="k" :value="k">{{ k }}</option>
        </select>
        <select class="filter-select" v-model="filterStatus">
          <option value="">Semua Status</option>
          <option value="active">Aktif</option>
          <option value="inactive">Nonaktif</option>
        </select>
      </template>

      <template #actions>
        <button class="btn btn-export btn-sm" @click="exportCsv">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
          Export CSV
        </button>
        <button class="btn btn-primary btn-sm" @click="openAdd">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
          Tambah Budaya
        </button>
      </template>

      <template #headers="{ sort, onSort }">
        <th class="sortable" :class="{'sort-active':sort.key==='nama'}" @click="onSort('nama')">
          Foto &amp; Nama <span class="sort-icon">
            <svg v-if="sort.key==='nama' && sort.dir==='asc'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="18 15 12 9 6 15"/></svg>
            <svg v-else-if="sort.key==='nama'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="6 9 12 15 18 9"/></svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:10px;height:10px"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>
          </span>
        </th>
        <th>Kategori</th><th>Asal Daerah</th><th>Deskripsi</th><th>Status</th>
        <th class="sortable" :class="{'sort-active':sort.key==='created_at'}" @click="onSort('created_at')">
          Tanggal <span class="sort-icon">
            <svg v-if="sort.key==='created_at' && sort.dir==='asc'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="18 15 12 9 6 15"/></svg>
            <svg v-else-if="sort.key==='created_at'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="6 9 12 15 18 9"/></svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:10px;height:10px"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>
          </span>
        </th>
        <th>Aksi</th>
      </template>

      <template #rows="{ items }">
        <tr v-for="b in items" :key="b.id" :class="{'row-inactive': b.is_active === false}">
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <img v-if="b.foto_url" :src="b.foto_url" :alt="b.nama" class="table-img" @click="openPhoto(b)" />
              <div v-else class="table-img-placeholder">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
              </div>
              <div class="table-name">{{ b.nama }}</div>
            </div>
          </td>
          <td><span class="badge badge-green">{{ b.kategori }}</span></td>
          <td style="font-size:12px;color:#5a6c5b">{{ b.asal_daerah || '–' }}</td>
          <td><div class="table-desc">{{ b.deskripsi || '–' }}</div></td>
          <td>
            <div class="status-toggle-wrap">
              <label class="status-toggle">
                <input type="checkbox" :checked="b.is_active !== false" @change="toggleStatus(b)" />
                <span class="status-toggle-slider"></span>
              </label>
              <span class="status-toggle-label" :class="{active: b.is_active !== false}">{{ b.is_active !== false ? 'Aktif' : 'Nonaktif' }}</span>
            </div>
          </td>
          <td style="font-size:11px;color:#8a998b;white-space:nowrap">{{ formatDate(b.created_at) }}</td>
          <td>
            <div class="table-actions">
              <button class="btn btn-ghost btn-icon" @click="openEdit(b)" title="Edit">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><path d="M11 4H4a2 2 0 00-2 2v14h14v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              </button>
              <button class="btn btn-ghost btn-icon" @click="confirmDelete(b)" title="Hapus" style="color:#d67d5c">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>
              </button>
            </div>
          </td>
        </tr>
      </template>
    </DataTable>

    <!-- Modal Form -->
    <div class="modal-overlay" v-if="showModal" @click.self="closeModal">
      <div class="modal">
        <div class="modal-header">
          <div class="modal-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>
            {{ editItem ? 'Edit Budaya' : 'Tambah Budaya' }}
          </div>
          <button class="modal-close" @click="closeModal">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">Nama <span class="required">*</span></label>
            <input v-model="form.nama" class="form-input" required placeholder="Nama budaya..." />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Kategori <span class="required">*</span></label>
              <select v-model="form.kategori" class="form-select" required>
                <option value="">Pilih kategori</option>
                <option v-for="k in kategoriOptions" :key="k" :value="k">{{ k }}</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">Asal Daerah</label>
              <input v-model="form.asal_daerah" class="form-input" placeholder="Misal: Bima, NTB" />
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Deskripsi</label>
            <textarea v-model="form.deskripsi" class="form-textarea" rows="3" placeholder="Deskripsi budaya..."></textarea>
          </div>
          <div class="form-group">
            <label class="form-label">Foto</label>
            <div v-if="fotoPreview" class="upload-preview" style="margin-bottom:8px">
              <img :src="fotoPreview" alt="Preview" />
              <button type="button" class="upload-preview-remove" @click="removePhoto">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
              </button>
            </div>
            <div v-else class="upload-zone" :class="{'drag-over':isDragOver}" @click="$refs.fileInput.click()" @dragover.prevent="isDragOver=true" @dragleave="isDragOver=false" @drop.prevent="onFileDrop">
              <div class="upload-zone-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
              </div>
              <div class="upload-zone-text"><strong>Klik untuk upload</strong> atau drag &amp; drop<br><span>JPG, PNG maks. 5MB</span></div>
            </div>
            <input ref="fileInput" type="file" accept="image/*" style="display:none" @change="onFileChange" />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="closeModal">Batal</button>
          <button class="btn btn-primary" :disabled="saving" @click="saveItem">
            <div v-if="saving" class="spinner spinner-sm"></div>
            {{ saving ? 'Menyimpan...' : 'Simpan' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Confirm Delete -->
    <div class="modal-overlay" v-if="showConfirm" @click.self="showConfirm=false">
      <div class="modal modal-sm">
        <div class="modal-body" style="padding-top:28px">
          <div class="confirm-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
          </div>
          <div class="confirm-title">Hapus Budaya?</div>
          <div class="confirm-desc">Data "<strong>{{ deleteTarget?.nama }}</strong>" akan dihapus permanen.</div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="showConfirm=false">Batal</button>
          <button class="btn btn-danger" :disabled="saving" @click="doDelete">
            <div v-if="saving" class="spinner spinner-sm"></div>
            {{ saving ? 'Menghapus...' : 'Hapus' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Photo Viewer -->
    <PhotoViewer :visible="photoViewer.visible" :src="photoViewer.src" :name="photoViewer.name" :meta="photoViewer.meta" @close="photoViewer.visible=false" />

    <!-- Toasts -->
    <div class="toast-container">
      <div v-for="t in toasts" :key="t.id" class="toast" :class="t.type">
        <svg v-if="t.type==='success'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
        <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        {{ t.message }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import DataTable from '../components/DataTable.vue'
import PhotoViewer from '../components/PhotoViewer.vue'
import { budayaService } from '../services/supabaseService.js'
import { KATEGORI_BUDAYA } from '../config/supabaseConfig.js'

const allData = ref([])
const loading = ref(false)
const error = ref(null)
const saving = ref(false)
const searchTerm = ref('')
const filterKategori = ref('')
const filterStatus = ref('')
const sortKey = ref(null)
const sortDir = ref('asc')
const showModal = ref(false)
const editItem = ref(null)
const showConfirm = ref(false)
const deleteTarget = ref(null)
const isDragOver = ref(false)
const fotoFile = ref(null)
const fotoPreview = ref(null)
const fileInput = ref(null)
const toasts = ref([])
const photoViewer = ref({ visible: false, src: null, name: '', meta: '' })
const kategoriOptions = KATEGORI_BUDAYA || ['Tarian','Pakaian Adat','Rumah Adat','Kuliner','Musik','Kerajinan','Tradisi']
const form = ref({ nama: '', kategori: '', deskripsi: '', asal_daerah: '' })

const filteredData = computed(() => {
  let list = allData.value
  if (searchTerm.value) {
    const q = searchTerm.value.toLowerCase()
    list = list.filter(b => b.nama?.toLowerCase().includes(q) || b.kategori?.toLowerCase().includes(q))
  }
  if (filterKategori.value) list = list.filter(b => b.kategori === filterKategori.value)
  if (filterStatus.value === 'active') list = list.filter(b => b.is_active !== false)
  else if (filterStatus.value === 'inactive') list = list.filter(b => b.is_active === false)
  if (sortKey.value) {
    list = [...list].sort((a, b) => {
      let av = a[sortKey.value] ?? '', bv = b[sortKey.value] ?? ''
      if (typeof av === 'string') av = av.toLowerCase()
      if (typeof bv === 'string') bv = bv.toLowerCase()
      const cmp = av < bv ? -1 : av > bv ? 1 : 0
      return sortDir.value === 'asc' ? cmp : -cmp
    })
  }
  return list
})

async function loadData() {
  loading.value = true; error.value = null
  try { allData.value = await budayaService.getAll() }
  catch (e) { error.value = e.message }
  finally { loading.value = false }
}

function onSearch(v) { searchTerm.value = v }
function onSort({ key, dir }) { sortKey.value = key; sortDir.value = dir }

function openPhoto(b) { photoViewer.value = { visible: true, src: b.foto_url, name: b.nama, meta: b.kategori } }

async function toggleStatus(b) {
  const newVal = !(b.is_active !== false)
  try {
    const updated = await budayaService.toggleIsActive(b.id, newVal)
    const idx = allData.value.findIndex(x => x.id === b.id)
    if (idx !== -1) allData.value[idx] = updated
    toast(newVal ? 'Budaya diaktifkan' : 'Budaya dinonaktifkan', 'success')
  } catch (e) { toast('Gagal ubah status', 'error') }
}

function exportCsv() {
  const rows = [['Nama','Kategori','Asal Daerah','Deskripsi','Status','Tanggal']]
  filteredData.value.forEach(b => rows.push([
    csvEscape(b.nama), csvEscape(b.kategori), csvEscape(b.asal_daerah||''),
    csvEscape(b.deskripsi||''), b.is_active!==false?'Aktif':'Nonaktif', formatDate(b.created_at)
  ]))
  const csv = rows.map(r=>r.join(',')).join('\n')
  const blob = new Blob(['\uFEFF'+csv], {type:'text/csv;charset=utf-8;'})
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a'); a.href=url
  a.download=`budaya_export_${new Date().toISOString().slice(0,10)}.csv`; a.click()
  URL.revokeObjectURL(url); toast('Export CSV berhasil','success')
}
function csvEscape(v) { const s=String(v).replace(/"/g,'""'); return /[,"\n]/.test(s)?`"${s}"`:s }

function openAdd() {
  editItem.value = null
  form.value = { nama:'', kategori:'', deskripsi:'', asal_daerah:'' }
  fotoFile.value = null; fotoPreview.value = null; showModal.value = true
}
function openEdit(b) {
  editItem.value = b
  form.value = { nama:b.nama, kategori:b.kategori, deskripsi:b.deskripsi||'', asal_daerah:b.asal_daerah||'' }
  fotoPreview.value = b.foto_url||null; fotoFile.value = null; showModal.value = true
}
function closeModal() { showModal.value = false }

async function saveItem() {
  if (!form.value.nama || !form.value.kategori) { toast('Nama dan kategori wajib diisi','error'); return }
  saving.value = true
  try {
    let fotoPath = editItem.value?.foto_path||null, fotoUrl = editItem.value?.foto_url||null
    if (fotoFile.value) {
      const old = editItem.value?.foto_path
      if (old) await budayaService.deleteFoto(old)
      const res = await budayaService.uploadFoto(fotoFile.value)
      fotoPath = res.path; fotoUrl = res.url
    }
    const payload = { nama:form.value.nama, kategori:form.value.kategori, deskripsi:form.value.deskripsi||null, asal_daerah:form.value.asal_daerah||null, foto_path:fotoPath, foto_url:fotoUrl }
    if (editItem.value) { await budayaService.update(editItem.value.id, payload); toast('Berhasil diperbarui','success') }
    else { await budayaService.create(payload); toast('Berhasil ditambahkan','success') }
    closeModal(); await loadData()
  } catch (e) { toast('Gagal menyimpan: '+e.message,'error') }
  finally { saving.value = false }
}

function confirmDelete(b) { deleteTarget.value=b; showConfirm.value=true }
async function doDelete() {
  saving.value = true
  try {
    if (deleteTarget.value.foto_path) await budayaService.deleteFoto(deleteTarget.value.foto_path)
    await budayaService.delete(deleteTarget.value.id)
    toast('Berhasil dihapus','success'); showConfirm.value=false; await loadData()
  } catch(e) { toast('Gagal menghapus','error') }
  finally { saving.value = false }
}

function onFileChange(e) { handleFile(e.target.files[0]) }
function onFileDrop(e) { isDragOver.value=false; handleFile(e.dataTransfer.files[0]) }
function handleFile(f) { if(!f)return; fotoFile.value=f; fotoPreview.value=URL.createObjectURL(f) }
function removePhoto() { fotoFile.value=null; fotoPreview.value=null }

function formatDate(s) { if(!s)return'–'; return new Date(s).toLocaleDateString('id-ID',{day:'numeric',month:'short',year:'numeric'}) }
function toast(message, type='success') {
  const id=Date.now(); toasts.value.push({id,message,type})
  setTimeout(()=>{toasts.value=toasts.value.filter(t=>t.id!==id)},3500)
}

onMounted(loadData)
</script>
