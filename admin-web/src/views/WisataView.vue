<!-- src/views/WisataView.vue -->
<template>
  <div class="page-content">
    <div class="page-header">
      <div>
        <div class="page-title">Kelola Wisata</div>
        <div class="page-subtitle">Manajemen destinasi wisata Kabupaten Bima</div>
      </div>
    </div>

    <DataTable
      :items="filteredData" :loading="loading" :error="error"
      search-placeholder="Cari nama wisata..."
      empty-title="Belum Ada Data Wisata"
      empty-desc="Klik tombol Tambah Wisata untuk menambahkan destinasi pertama."
      @search="onSearch" @retry="loadData" @sort="onSort"
    >
      <template #filters>
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
          Tambah Wisata
        </button>
      </template>

      <template #headers="{ sort, onSort }">
        <th class="sortable" :class="{'sort-active':sort.key==='nama'}" @click="onSort('nama')">
          Foto &amp; Nama
          <span class="sort-icon">
            <svg v-if="sort.key==='nama'&&sort.dir==='asc'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="18 15 12 9 6 15"/></svg>
            <svg v-else-if="sort.key==='nama'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="6 9 12 15 18 9"/></svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:10px;height:10px;opacity:.5"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>
          </span>
        </th>
        <th>Alamat</th>
        <th>Koordinat</th>
        <th>Status</th>
        <th class="sortable" :class="{'sort-active':sort.key==='created_at'}" @click="onSort('created_at')">
          Tanggal
          <span class="sort-icon">
            <svg v-if="sort.key==='created_at'&&sort.dir==='asc'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="18 15 12 9 6 15"/></svg>
            <svg v-else-if="sort.key==='created_at'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" style="width:10px;height:10px;color:#4a7c59"><polyline points="6 9 12 15 18 9"/></svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:10px;height:10px;opacity:.5"><line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/></svg>
          </span>
        </th>
        <th>Aksi</th>
      </template>

      <template #rows="{ items }">
        <tr v-for="w in items" :key="w.id" :class="{'row-inactive': w.is_active===false}">
          <td>
            <div style="display:flex;align-items:center;gap:10px">
              <img v-if="w.foto_url" :src="w.foto_url" :alt="w.nama" class="table-img" @click="openPhoto(w)" />
              <div v-else class="table-img-placeholder">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
              </div>
              <div>
                <div class="table-name">{{ w.nama }}</div>
                <div class="table-sub" v-if="w.deskripsi">{{ w.deskripsi?.slice(0,50) }}...</div>
              </div>
            </div>
          </td>
          <td style="font-size:12px;color:#5a6c5b;max-width:160px" class="text-truncate">{{ w.alamat || '–' }}</td>
          <td>
            <div style="font-size:11px;font-family:monospace;color:#5a6c5b;line-height:1.6">
              <div>{{ w.latitude?.toFixed(5) }}</div>
              <div>{{ w.longitude?.toFixed(5) }}</div>
            </div>
          </td>
          <td>
            <div class="status-toggle-wrap">
              <label class="status-toggle">
                <input type="checkbox" :checked="w.is_active!==false" @change="toggleStatus(w)" />
                <span class="status-toggle-slider"></span>
              </label>
              <span class="status-toggle-label" :class="{active:w.is_active!==false}">{{ w.is_active!==false?'Aktif':'Nonaktif' }}</span>
            </div>
          </td>
          <td style="font-size:11px;color:#8a998b;white-space:nowrap">{{ formatDate(w.created_at) }}</td>
          <td>
            <div class="table-actions">
              <button class="btn btn-ghost btn-icon" @click="openEdit(w)" title="Edit">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><path d="M11 4H4a2 2 0 00-2 2v14h14v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
              </button>
              <button class="btn btn-ghost btn-icon" @click="confirmDelete(w)" title="Hapus" style="color:#d67d5c">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
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
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
            {{ editItem ? 'Edit Wisata' : 'Tambah Wisata' }}
          </div>
          <button class="modal-close" @click="closeModal">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">Nama <span class="required">*</span></label>
            <input v-model="form.nama" class="form-input" required placeholder="Nama destinasi wisata..." />
          </div>
          <div class="form-group">
            <label class="form-label">Alamat</label>
            <input v-model="form.alamat" class="form-input" placeholder="Alamat / lokasi..." />
          </div>
          <div class="form-group">
            <label class="form-label">Deskripsi</label>
            <textarea v-model="form.deskripsi" class="form-textarea" rows="3" placeholder="Deskripsi destinasi..."></textarea>
          </div>

          <!-- Koordinat -->
          <div class="form-group">
            <label class="form-label">Koordinat <span class="required">*</span></label>
            <div class="coord-inputs">
              <div>
                <input v-model.number="form.latitude" class="form-input" type="number" step="0.000001" placeholder="Latitude" @input="onCoordChange" />
                <div v-if="latError" class="form-error">{{ latError }}</div>
              </div>
              <div>
                <input v-model.number="form.longitude" class="form-input" type="number" step="0.000001" placeholder="Longitude" @input="onCoordChange" />
                <div v-if="lngError" class="form-error">{{ lngError }}</div>
              </div>
              <div class="coord-hint">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                Wilayah Kabupaten Bima: Lat -9.2 s/d -8.0, Lng 117.8 s/d 119.4
              </div>
            </div>
          </div>

          <!-- Mini Map Preview -->
          <div v-if="mapPreviewUrl" class="form-group">
            <label class="form-label">Pratinjau Peta</label>
            <div class="map-preview">
              <iframe :src="mapPreviewUrl" allowfullscreen loading="lazy" referrerpolicy="no-referrer-when-downgrade"></iframe>
            </div>
          </div>

          <!-- Foto -->
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

          <!-- ─── MULTIMEDIA SECTION ─── -->
          <div class="media-section">
            <div v-if="!editItem" class="media-add-note">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              💡 Multimedia (foto, video, audio) dapat ditambahkan setelah data disimpan melalui menu <strong>Edit</strong>.
            </div>

            <template v-else>
              <div class="media-section-header">
                <div class="media-section-title">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                  Multimedia
                  <span class="media-count-badge" v-if="mediaList.length > 0">{{ mediaList.length }}</span>
                </div>
              </div>

              <div class="media-tabs">
                <button v-for="tab in mediaTabs" :key="tab.key" class="media-tab-btn" :class="{ active: activeMediaTab === tab.key }" @click="activeMediaTab = tab.key">
                  {{ tab.icon }} {{ tab.label }}
                  <span class="tab-count" v-if="mediaCountByTab(tab.key) > 0">{{ mediaCountByTab(tab.key) }}</span>
                </button>
              </div>

              <div class="media-upload-area">
                <div class="form-group" style="margin-bottom:8px">
                  <label class="form-label" style="font-size:12px">Judul media (opsional)</label>
                  <input v-model="mediaJudul" class="form-input" style="font-size:13px" placeholder="Contoh: Pantai saat sunset..." />
                </div>
                <div v-if="activeMediaTab === 'gambar'" class="upload-zone upload-zone-sm" @click="$refs.mediaFileInput.click()" @dragover.prevent @drop.prevent="onMediaFileDrop">
                  <div class="upload-zone-icon" style="font-size:24px">🖼️</div>
                  <div class="upload-zone-text"><strong>Klik untuk upload foto</strong> atau drag &amp; drop<br><span>JPG, PNG maks. 5MB</span></div>
                </div>
                <div v-if="activeMediaTab === 'video'" class="upload-zone upload-zone-sm" @click="$refs.mediaFileInput.click()">
                  <div class="upload-zone-icon" style="font-size:24px">🎬</div>
                  <div class="upload-zone-text"><strong>Klik untuk upload video</strong><br><span>Format MP4, maks. 50MB</span></div>
                </div>
                <div v-if="activeMediaTab === 'audio'" class="upload-zone upload-zone-sm" @click="$refs.mediaFileInput.click()">
                  <div class="upload-zone-icon" style="font-size:24px">🎵</div>
                  <div class="upload-zone-text"><strong>Klik untuk upload audio</strong><br><span>Format MP3, maks. 10MB</span></div>
                </div>
                <input ref="mediaFileInput" type="file" style="display:none" :accept="mediaAccept" @change="onMediaFileChange" />
                <div v-if="mediaUploading" class="upload-progress-wrap">
                  <div class="upload-progress-label"><span>Mengupload...</span><span>{{ uploadProgress }}%</span></div>
                  <div class="upload-progress-bar"><div class="upload-progress-fill" :style="{ width: uploadProgress + '%' }"></div></div>
                </div>
              </div>

              <div v-if="mediaLoading" class="media-loading"><div class="spinner spinner-sm"></div><span>Memuat media...</span></div>
              <div v-else-if="filteredMediaList.length === 0" class="media-empty">
                <span>{{ activeMediaTab === 'gambar' ? '🖼️' : activeMediaTab === 'video' ? '🎬' : '🎵' }}</span>
                <p>Belum ada {{ activeMediaTab === 'gambar' ? 'foto' : activeMediaTab === 'video' ? 'video' : 'audio' }} untuk wisata ini.</p>
              </div>
              <div v-else class="media-list">
                <div v-for="item in filteredMediaList" :key="item.id" class="media-item">
                  <template v-if="item.jenis_media === 'gambar'">
                    <div class="media-item-thumb"><img :src="item.url_media" :alt="item.judul || 'Foto'" /></div>
                  </template>
                  <template v-else-if="item.jenis_media === 'video'">
                    <div class="media-item-thumb media-item-thumb-icon"><span>🎬</span></div>
                  </template>
                  <template v-else-if="item.jenis_media === 'audio'">
                    <div class="media-item-thumb media-item-thumb-icon"><span>🎵</span></div>
                  </template>
                  <div class="media-item-info">
                    <div class="media-item-title">{{ item.judul || (item.jenis_media === 'gambar' ? 'Foto' : item.jenis_media === 'video' ? 'Video' : 'Audio') }}</div>
                    <div class="media-item-meta">
                      <span class="badge" :class="mediaBadgeClass(item.jenis_media)">{{ item.jenis_media }}</span>
                      <span class="media-item-date">{{ formatDate(item.created_at) }}</span>
                    </div>
                    <audio v-if="item.jenis_media === 'audio'" :src="item.url_media" controls class="media-audio-player" preload="none"></audio>
                    <a v-if="item.jenis_media === 'video'" :href="item.url_media" target="_blank" rel="noopener noreferrer" class="media-video-link">Buka video ↗</a>
                  </div>
                  <button class="btn btn-danger-ghost btn-icon" :disabled="deletingMediaId === item.id" @click="confirmDeleteMedia(item)" title="Hapus media">
                    <div v-if="deletingMediaId === item.id" class="spinner spinner-sm"></div>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>
                  </button>
                </div>
              </div>
            </template>
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

    <!-- Confirm Delete Media -->
    <div class="modal-overlay" v-if="showConfirmMedia" @click.self="showConfirmMedia=false">
      <div class="modal modal-sm">
        <div class="modal-body" style="padding-top:28px">
          <div class="confirm-icon" style="background:rgba(214,125,92,0.1)">
            <svg viewBox="0 0 24 24" fill="none" stroke="#d67d5c" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
          </div>
          <div class="confirm-title">Hapus Media?</div>
          <div class="confirm-desc">"<strong>{{ deleteMediaTarget?.judul || 'Media ini' }}</strong>" akan dihapus permanen dari storage.</div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="showConfirmMedia=false">Batal</button>
          <button class="btn btn-danger" @click="doDeleteMedia">Hapus</button>
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
          <div class="confirm-title">Hapus Wisata?</div>
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
import { ref, computed, onMounted, watch } from 'vue'
import DataTable from '../components/DataTable.vue'
import PhotoViewer from '../components/PhotoViewer.vue'
import { wisataService, wisataMediaService } from '../services/supabaseService.js'
import { BIMA_BOUNDS } from '../config/supabaseConfig.js'

const allData = ref([])
const loading = ref(false)
const error = ref(null)
const saving = ref(false)
const searchTerm = ref('')
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
const latError = ref('')
const lngError = ref('')

const form = ref({ nama:'', deskripsi:'', latitude:null, longitude:null, alamat:'' })

// ─── Multimedia state ─────────────────────────────────────────────
const mediaList        = ref([])
const mediaLoading     = ref(false)
const mediaUploading   = ref(false)
const uploadProgress   = ref(0)
const activeMediaTab   = ref('gambar')
const mediaJudul       = ref('')
const deletingMediaId  = ref(null)
const showConfirmMedia = ref(false)
const deleteMediaTarget = ref(null)
const mediaFileInput   = ref(null)

const mediaTabs = [
  { key: 'gambar', label: 'Foto',  icon: '🖼️' },
  { key: 'video',  label: 'Video', icon: '🎬' },
  { key: 'audio',  label: 'Audio', icon: '🎵' },
]

// Mini map URL
const mapPreviewUrl = computed(() => {
  const lat = form.value.latitude, lng = form.value.longitude
  if (!lat || !lng || latError.value || lngError.value) return null
  if (!isInBimaBounds(lat, lng)) return null
  return `https://maps.google.com/maps?q=${lat},${lng}&z=13&output=embed`
})

const filteredData = computed(() => {
  let list = allData.value
  if (searchTerm.value) {
    const q = searchTerm.value.toLowerCase()
    list = list.filter(w => w.nama?.toLowerCase().includes(q) || w.alamat?.toLowerCase().includes(q))
  }
  if (filterStatus.value === 'active') list = list.filter(w => w.is_active !== false)
  else if (filterStatus.value === 'inactive') list = list.filter(w => w.is_active === false)
  if (sortKey.value) {
    list = [...list].sort((a, b) => {
      let av = a[sortKey.value]??'', bv = b[sortKey.value]??''
      if (typeof av==='string') av=av.toLowerCase()
      if (typeof bv==='string') bv=bv.toLowerCase()
      const cmp = av<bv?-1:av>bv?1:0
      return sortDir.value==='asc'?cmp:-cmp
    })
  }
  return list
})

const filteredMediaList = computed(() =>
  mediaList.value.filter(m => m.jenis_media === activeMediaTab.value)
)

const mediaAccept = computed(() => {
  if (activeMediaTab.value === 'gambar') return 'image/jpeg,image/png,image/webp'
  if (activeMediaTab.value === 'video')  return 'video/mp4'
  return 'audio/mpeg,audio/mp3'
})

// Watch: fetch media ketika modal edit terbuka
watch([showModal, editItem], ([isOpen, item]) => {
  if (isOpen && item) {
    fetchMedia(item.id)
  } else {
    mediaList.value = []
    mediaJudul.value = ''
    activeMediaTab.value = 'gambar'
  }
})

const bounds = BIMA_BOUNDS || { latMin:-9.0, latMax:-8.0, lngMin:118.0, lngMax:119.5 }

function isInBimaBounds(lat, lng) {
  return lat >= bounds.latMin && lat <= bounds.latMax && lng >= bounds.lngMin && lng <= bounds.lngMax
}

function onCoordChange() {
  const lat = form.value.latitude, lng = form.value.longitude
  latError.value = lat && (lat < bounds.latMin || lat > bounds.latMax) ? `Latitude harus antara ${bounds.latMin} dan ${bounds.latMax}` : ''
  lngError.value = lng && (lng < bounds.lngMin || lng > bounds.lngMax) ? `Longitude harus antara ${bounds.lngMin} dan ${bounds.lngMax}` : ''
}

async function loadData() {
  loading.value = true; error.value = null
  try { allData.value = await wisataService.getAll() }
  catch (e) { error.value = e.message }
  finally { loading.value = false }
}

function onSearch(v) { searchTerm.value = v }
function onSort({ key, dir }) { sortKey.value = key; sortDir.value = dir }

function openPhoto(w) { photoViewer.value = { visible:true, src:w.foto_url, name:w.nama, meta:w.alamat||'' } }

async function toggleStatus(w) {
  const newVal = !(w.is_active !== false)
  try {
    const updated = await wisataService.toggleIsActive(w.id, newVal)
    const idx = allData.value.findIndex(x => x.id===w.id)
    if (idx !== -1) allData.value[idx] = updated
    toast(newVal ? 'Wisata diaktifkan' : 'Wisata dinonaktifkan', 'success')
  } catch (e) { toast('Gagal ubah status', 'error') }
}

function exportCsv() {
  const rows = [['Nama','Alamat','Latitude','Longitude','Deskripsi','Status','Tanggal']]
  filteredData.value.forEach(w => rows.push([
    csvEscape(w.nama), csvEscape(w.alamat||''),
    w.latitude||'', w.longitude||'',
    csvEscape(w.deskripsi||''), w.is_active!==false?'Aktif':'Nonaktif', formatDate(w.created_at)
  ]))
  const csv = rows.map(r=>r.join(',')).join('\n')
  const blob = new Blob(['\uFEFF'+csv], {type:'text/csv;charset=utf-8;'})
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a'); a.href=url
  a.download=`wisata_export_${new Date().toISOString().slice(0,10)}.csv`; a.click()
  URL.revokeObjectURL(url); toast('Export CSV berhasil', 'success')
}
function csvEscape(v) { const s=String(v).replace(/"/g,'""'); return /[,"\n]/.test(s)?`"${s}"`:s }

function openAdd() {
  editItem.value = null
  form.value = { nama:'', deskripsi:'', latitude:null, longitude:null, alamat:'' }
  fotoFile.value = null; fotoPreview.value = null; latError.value=''; lngError.value=''
  showModal.value = true
}
function openEdit(w) {
  editItem.value = w
  form.value = { nama:w.nama, deskripsi:w.deskripsi||'', latitude:w.latitude, longitude:w.longitude, alamat:w.alamat||'' }
  fotoPreview.value = w.foto_url||null; fotoFile.value = null; latError.value=''; lngError.value=''
  showModal.value = true
}
function closeModal() { showModal.value = false; editItem.value = null }

async function saveItem() {
  if (!form.value.nama) { toast('Nama wajib diisi', 'error'); return }
  if (latError.value || lngError.value) { toast('Koordinat tidak valid', 'error'); return }
  saving.value = true
  try {
    let fotoPath = editItem.value?.foto_path||null, fotoUrl = editItem.value?.foto_url||null
    if (fotoFile.value) {
      const old = editItem.value?.foto_path
      if (old) await wisataService.deleteFoto(old)
      const res = await wisataService.uploadFoto(fotoFile.value)
      fotoPath = res.path; fotoUrl = res.url
    }
    const payload = {
      nama:form.value.nama, deskripsi:form.value.deskripsi||null,
      latitude:form.value.latitude, longitude:form.value.longitude,
      alamat:form.value.alamat||null, foto_path:fotoPath, foto_url:fotoUrl,
    }
    if (editItem.value) { await wisataService.update(editItem.value.id, payload); toast('Berhasil diperbarui','success') }
    else { await wisataService.create(payload); toast('Berhasil ditambahkan','success') }
    closeModal(); await loadData()
  } catch (e) { toast('Gagal menyimpan: '+e.message, 'error') }
  finally { saving.value = false }
}

function confirmDelete(w) { deleteTarget.value=w; showConfirm.value=true }

async function doDelete() {
  saving.value = true
  try {
    await wisataMediaService.deleteAllByWisataId(deleteTarget.value.id)
    if (deleteTarget.value.foto_path) await wisataService.deleteFoto(deleteTarget.value.foto_path)
    await wisataService.delete(deleteTarget.value.id)
    toast('Berhasil dihapus', 'success')
    showConfirm.value = false
    await loadData()
  } catch (e) { toast('Gagal menghapus', 'error') }
  finally { saving.value = false }
}

// ─── MULTIMEDIA FUNCTIONS ─────────────────────────────────────────
async function fetchMedia(wisataId) {
  mediaLoading.value = true
  try {
    mediaList.value = await wisataMediaService.getByWisataId(wisataId)
  } catch(e) {
    toast('Gagal memuat media: ' + e.message, 'error')
  } finally {
    mediaLoading.value = false
  }
}

function mediaCountByTab(tabKey) {
  return mediaList.value.filter(m => m.jenis_media === tabKey).length
}

function mediaBadgeClass(jenisMedia) {
  if (jenisMedia === 'gambar') return 'badge-green'
  if (jenisMedia === 'video')  return 'badge-blue'
  return 'badge-purple'
}

function onMediaFileChange(e) {
  const file = e.target.files[0]
  if (file) uploadMedia(file)
  e.target.value = ''
}

function onMediaFileDrop(e) {
  const file = e.dataTransfer.files[0]
  if (file) uploadMedia(file)
}

async function uploadMedia(file) {
  if (!editItem.value) return
  mediaUploading.value = true
  uploadProgress.value = 10
  try {
    let result
    const tab = activeMediaTab.value
    const progressTimer = setInterval(() => {
      if (uploadProgress.value < 85) uploadProgress.value += 10
    }, 300)

    if (tab === 'gambar') result = await wisataMediaService.uploadGambar(file)
    else if (tab === 'video') result = await wisataMediaService.uploadVideo(file)
    else result = await wisataMediaService.uploadAudio(file)

    clearInterval(progressTimer)
    uploadProgress.value = 95

    const urutan = mediaList.value.filter(m => m.jenis_media === tab).length
    await wisataMediaService.addMedia({
      wisataId: editItem.value.id,  // ← wisataId bukan budayaId
      jenisMedia: tab,
      urlMedia: result.url,
      storagePath: result.path,
      judul: mediaJudul.value.trim() || null,
      urutan,
    })

    uploadProgress.value = 100
    mediaJudul.value = ''
    toast('Media berhasil diupload', 'success')
    await fetchMedia(editItem.value.id)
  } catch(e) {
    toast('Gagal upload: ' + e.message, 'error')
  } finally {
    setTimeout(() => { mediaUploading.value = false; uploadProgress.value = 0 }, 600)
  }
}

function confirmDeleteMedia(item) {
  deleteMediaTarget.value = item
  showConfirmMedia.value = true
}

async function doDeleteMedia() {
  if (!deleteMediaTarget.value) return
  const item = deleteMediaTarget.value
  deletingMediaId.value = item.id
  showConfirmMedia.value = false
  try {
    await wisataMediaService.deleteMedia(item.id, item.storage_path, item.jenis_media)
    toast('Media berhasil dihapus', 'success')
    await fetchMedia(editItem.value.id)
  } catch(e) {
    toast('Gagal hapus media: ' + e.message, 'error')
  } finally {
    deletingMediaId.value = null
    deleteMediaTarget.value = null
  }
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

<style scoped>
.modal-wide { max-width: 760px; width: 95vw; }
.media-section { margin-top: 24px; border-top: 1px solid rgba(139,111,71,0.15); padding-top: 20px; }
.media-add-note { display:flex; align-items:flex-start; gap:10px; background:rgba(139,111,71,0.06); border:1px solid rgba(139,111,71,0.2); border-radius:10px; padding:14px 16px; font-size:13px; color:#6b5a3e; line-height:1.5; }
.media-add-note svg { width:16px; height:16px; flex-shrink:0; margin-top:2px; stroke:#8b6f47; }
.media-section-header { display:flex; align-items:center; justify-content:space-between; margin-bottom:14px; }
.media-section-title { display:flex; align-items:center; gap:8px; font-size:14px; font-weight:700; color:#2c3e2d; }
.media-section-title svg { width:16px; height:16px; stroke:#8b6f47; }
.media-count-badge { background:#8b6f47; color:#fff; font-size:11px; font-weight:700; border-radius:20px; padding:1px 7px; min-width:20px; text-align:center; }
.media-tabs { display:flex; gap:6px; margin-bottom:14px; background:rgba(139,111,71,0.06); border-radius:10px; padding:4px; }
.media-tab-btn { flex:1; display:flex; align-items:center; justify-content:center; gap:6px; padding:8px 10px; border:none; border-radius:7px; background:transparent; color:#6b5a3e; font-size:13px; font-weight:500; cursor:pointer; transition:all 0.2s; }
.media-tab-btn.active { background:#fff; color:#2c3e2d; font-weight:700; box-shadow:0 1px 4px rgba(0,0,0,0.08); }
.tab-count { background:#8b6f47; color:#fff; font-size:10px; font-weight:700; border-radius:20px; padding:1px 5px; }
.upload-zone-sm { padding:16px 20px !important; }
.upload-zone-sm .upload-zone-icon { font-size:24px; margin-bottom:6px; }
.upload-progress-wrap { margin-top:10px; }
.upload-progress-label { display:flex; justify-content:space-between; font-size:12px; color:#6b5a3e; margin-bottom:4px; }
.upload-progress-bar { height:6px; background:rgba(139,111,71,0.15); border-radius:3px; overflow:hidden; }
.upload-progress-fill { height:100%; background:#8b6f47; border-radius:3px; transition:width 0.3s; }
.media-loading { display:flex; align-items:center; gap:10px; padding:16px; color:#8a998b; font-size:13px; }
.media-empty { text-align:center; padding:24px; color:#8a998b; }
.media-empty span { font-size:32px; display:block; margin-bottom:8px; }
.media-empty p { font-size:13px; }
.media-upload-area { margin-bottom:16px; }
.media-list { display:flex; flex-direction:column; gap:8px; }
.media-item { display:flex; align-items:center; gap:12px; padding:10px 12px; border:1px solid rgba(139,111,71,0.15); border-radius:10px; background:#faf8f3; }
.media-item-thumb { width:52px; height:52px; border-radius:8px; overflow:hidden; flex-shrink:0; background:rgba(139,111,71,0.1); display:flex; align-items:center; justify-content:center; }
.media-item-thumb img { width:100%; height:100%; object-fit:cover; }
.media-item-thumb-icon { font-size:22px; }
.media-item-info { flex:1; min-width:0; }
.media-item-title { font-size:13px; font-weight:600; color:#2c3e2d; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.media-item-meta { display:flex; align-items:center; gap:6px; margin-top:3px; }
.media-item-date { font-size:11px; color:#8a998b; }
.media-audio-player { width:100%; margin-top:6px; height:28px; }
.media-video-link { font-size:12px; color:#8b6f47; text-decoration:underline; margin-top:4px; display:inline-block; }
.btn-danger-ghost { color:#d67d5c; background:transparent; border:none; cursor:pointer; border-radius:6px; padding:4px; }
.btn-danger-ghost:hover { background:rgba(214,125,92,0.1); }
.badge-blue { background:rgba(74,130,180,0.12); color:#3a7fba; }
.badge-purple { background:rgba(130,74,180,0.12); color:#7a3aba; }
</style>
