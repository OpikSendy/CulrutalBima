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

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- Modal Form                                                      -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div class="modal-overlay" v-if="showModal" @click.self="closeModal">
      <div class="modal modal-wide">
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
          <!-- ─── BASIC FORM FIELDS ─── -->
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
  <label class="form-label">Foto Utama</label>

  <!-- Tampilkan jika ada foto existing ATAU preview file baru -->
  <div v-if="existingFotoUrl || fotoPreview" class="upload-preview" style="margin-bottom:8px">
    <img
      :src="fotoPreview || existingFotoUrl"
      alt="Preview foto"
      @error="(e) => e.target.style.opacity = '0.3'"
    />
    <button type="button" class="upload-preview-remove" @click="removePhoto">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <line x1="18" y1="6" x2="6" y2="18"/>
        <line x1="6" y1="6" x2="18" y2="18"/>
      </svg>
    </button>
  </div>

  <!-- Upload zone hanya jika tidak ada foto sama sekali -->
  <div
    v-else
    class="upload-zone"
    :class="{'drag-over': isDragOver}"
    @click="$refs.fileInput.click()"
    @dragover.prevent="isDragOver = true"
    @dragleave="isDragOver = false"
    @drop.prevent="onFileDrop"
  >
    <div class="upload-zone-icon">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <rect x="3" y="3" width="18" height="18" rx="3"/>
        <circle cx="8.5" cy="8.5" r="1.5"/>
        <polyline points="21 15 16 10 5 21"/>
      </svg>
    </div>
    <div class="upload-zone-text">
      <strong>Klik untuk upload</strong> atau drag &amp; drop<br>
      <span>JPG, PNG maks. 5MB</span>
    </div>
  </div>

  <input ref="fileInput" type="file" accept="image/*" style="display:none" @change="onFileChange" />
</div>

          <!-- ─── MULTIMEDIA SECTION ─── -->
          <div class="media-section">
            <!-- Jika mode Tambah -->
            <div v-if="!editItem" class="media-add-note">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              💡 Multimedia (foto, video, audio) dapat ditambahkan setelah data disimpan melalui menu <strong>Edit</strong>.
            </div>

            <!-- Jika mode Edit -->
            <template v-else>
              <div class="media-section-header">
                <div class="media-section-title">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                  Multimedia
                  <span class="media-count-badge" v-if="mediaList.length > 0">{{ mediaList.length }}</span>
                </div>
              </div>

              <!-- Tab selector -->
              <div class="media-tabs">
                <button
                  v-for="tab in mediaTabs" :key="tab.key"
                  class="media-tab-btn"
                  :class="{ active: activeMediaTab === tab.key }"
                  @click="activeMediaTab = tab.key"
                >
                  {{ tab.icon }} {{ tab.label }}
                  <span class="tab-count" v-if="mediaCountByTab(tab.key) > 0">{{ mediaCountByTab(tab.key) }}</span>
                </button>
              </div>

              <!-- Upload area -->
              <div class="media-upload-area">
                <div class="form-group" style="margin-bottom:8px">
                  <label class="form-label" style="font-size:12px">Judul media (opsional)</label>
                  <input v-model="mediaJudul" class="form-input" style="font-size:13px" placeholder="Contoh: Tarian pembuka..." />
                </div>

                <!-- Foto upload -->
                <div v-if="activeMediaTab === 'gambar'" class="upload-zone upload-zone-sm" @click="$refs.mediaFileInput.click()" @dragover.prevent @drop.prevent="onMediaFileDrop">
                  <div class="upload-zone-icon" style="font-size:24px">🖼️</div>
                  <div class="upload-zone-text"><strong>Klik untuk upload foto</strong> atau drag &amp; drop<br><span>JPG, PNG maks. 5MB</span></div>
                </div>

                <!-- Video upload -->
                <div v-if="activeMediaTab === 'video'" class="upload-zone upload-zone-sm" @click="$refs.mediaFileInput.click()">
                  <div class="upload-zone-icon" style="font-size:24px">🎬</div>
                  <div class="upload-zone-text"><strong>Klik untuk upload video</strong><br><span>Format MP4, maks. 50MB</span></div>
                </div>

                <!-- Audio upload -->
                <div v-if="activeMediaTab === 'audio'" class="upload-zone upload-zone-sm" @click="$refs.mediaFileInput.click()">
                  <div class="upload-zone-icon" style="font-size:24px">🎵</div>
                  <div class="upload-zone-text"><strong>Klik untuk upload audio</strong><br><span>Format MP3, maks. 10MB</span></div>
                </div>

                <!-- Hidden file input (accept varies by tab) -->
                <input
                  ref="mediaFileInput"
                  type="file"
                  style="display:none"
                  :accept="mediaAccept"
                  @change="onMediaFileChange"
                />

                <!-- Progress bar -->
                <div v-if="mediaUploading" class="upload-progress-wrap">
                  <div class="upload-progress-label">
                    <span>Mengupload...</span>
                    <span>{{ uploadProgress }}%</span>
                  </div>
                  <div class="upload-progress-bar">
                    <div class="upload-progress-fill" :style="{ width: uploadProgress + '%' }"></div>
                  </div>
                </div>
              </div>

              <!-- Media list -->
              <div v-if="mediaLoading" class="media-loading">
                <div class="spinner spinner-sm"></div>
                <span>Memuat media...</span>
              </div>

              <div v-else-if="filteredMediaList.length === 0" class="media-empty">
                <span>{{ activeMediaTab === 'gambar' ? '🖼️' : activeMediaTab === 'video' ? '🎬' : '🎵' }}</span>
                <p>Belum ada {{ activeMediaTab === 'gambar' ? 'foto' : activeMediaTab === 'video' ? 'video' : 'audio' }} untuk budaya ini.</p>
              </div>

              <div v-else class="media-list">
                <div
                  v-for="item in filteredMediaList"
                  :key="item.id"
                  class="media-item"
                >
                  <!-- Foto thumbnail -->
                  <template v-if="item.jenis_media === 'gambar'">
                    <div class="media-item-thumb">
                      <img :src="item.url_media" :alt="item.judul || 'Foto'" />
                    </div>
                  </template>

                  <!-- Video icon -->
                  <template v-else-if="item.jenis_media === 'video'">
                    <div class="media-item-thumb media-item-thumb-icon">
                      <span>🎬</span>
                    </div>
                  </template>

                  <!-- Audio icon + player -->
                  <template v-else-if="item.jenis_media === 'audio'">
                    <div class="media-item-thumb media-item-thumb-icon">
                      <span>🎵</span>
                    </div>
                  </template>

                  <div class="media-item-info">
                    <div class="media-item-title">{{ item.judul || (item.jenis_media === 'gambar' ? 'Foto' : item.jenis_media === 'video' ? 'Video' : 'Audio') }}</div>
                    <div class="media-item-meta">
                      <span class="badge" :class="mediaBadgeClass(item.jenis_media)">{{ item.jenis_media }}</span>
                      <span class="media-item-date">{{ formatDate(item.created_at) }}</span>
                    </div>

                    <!-- Audio player inline -->
                    <audio
                      v-if="item.jenis_media === 'audio'"
                      :src="item.url_media"
                      controls
                      class="media-audio-player"
                      preload="none"
                    ></audio>

                    <!-- Video link -->
                    <a
                      v-if="item.jenis_media === 'video'"
                      :href="item.url_media"
                      target="_blank"
                      rel="noopener noreferrer"
                      class="media-video-link"
                    >Buka video ↗</a>
                  </div>

                  <button
                    class="btn btn-danger-ghost btn-icon"
                    :disabled="deletingMediaId === item.id"
                    @click="confirmDeleteMedia(item)"
                    title="Hapus media"
                  >
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

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- Confirm Delete Budaya                                           -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div class="modal-overlay" v-if="showConfirm" @click.self="showConfirm=false">
      <div class="modal modal-sm">
        <div class="modal-body" style="padding-top:28px">
          <div class="confirm-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
          </div>
          <div class="confirm-title">Hapus Budaya?</div>
          <div class="confirm-desc">Data "<strong>{{ deleteTarget?.nama }}</strong>" beserta semua medianya akan dihapus permanen.</div>
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

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- Confirm Delete Media                                            -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div class="modal-overlay" v-if="showConfirmMedia" @click.self="showConfirmMedia=false">
      <div class="modal modal-sm">
        <div class="modal-body" style="padding-top:28px">
          <div class="confirm-icon" style="background:rgba(214,125,92,0.1)">
            <svg viewBox="0 0 24 24" fill="none" stroke="#d67d5c" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></svg>
          </div>
          <div class="confirm-title">Hapus Media?</div>
          <div class="confirm-desc">
            {{ deleteMediaTarget?.jenis_media === 'gambar' ? '🖼️' : deleteMediaTarget?.jenis_media === 'video' ? '🎬' : '🎵' }}
            "<strong>{{ deleteMediaTarget?.judul || 'Media ini' }}</strong>" akan dihapus permanen dari storage.
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="showConfirmMedia=false">Batal</button>
          <button class="btn btn-danger" @click="doDeleteMedia">Hapus</button>
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
import { budayaService, mediaService } from '../services/supabaseService.js'
import { KATEGORI_BUDAYA } from '../config/supabaseConfig.js'

// ─── Basic state ──────────────────────────────────────────────────────────────
const allData       = ref([])
const loading       = ref(false)
const error         = ref(null)
const saving        = ref(false)
const searchTerm    = ref('')
const filterKategori = ref('')
const filterStatus  = ref('')
const sortKey       = ref(null)
const sortDir       = ref('asc')
const showModal     = ref(false)
const editItem      = ref(null)
const showConfirm   = ref(false)
const deleteTarget  = ref(null)
const isDragOver    = ref(false)
const fotoFile      = ref(null)
const existingFotoUrl = ref(null)  
const fotoPreview     = ref(null)  
const fileInput     = ref(null)
const toasts        = ref([])
const photoViewer   = ref({ visible: false, src: null, name: '', meta: '' })
const kategoriOptions = KATEGORI_BUDAYA || ['Tarian','Pakaian Adat','Rumah Adat','Kuliner','Musik','Kerajinan','Tradisi']
const form          = ref({ nama: '', kategori: '', deskripsi: '', asal_daerah: '' })

// ─── Multimedia state ─────────────────────────────────────────────────────────
const mediaList         = ref([])
const mediaLoading      = ref(false)
const mediaUploading    = ref(false)
const uploadProgress    = ref(0)
const activeMediaTab    = ref('gambar')
const mediaJudul        = ref('')
const deletingMediaId   = ref(null)
const showConfirmMedia  = ref(false)
const deleteMediaTarget = ref(null)
const mediaFileInput    = ref(null)

const mediaTabs = [
  { key: 'gambar', label: 'Foto',  icon: '🖼️' },
  { key: 'video',  label: 'Video', icon: '🎬' },
  { key: 'audio',  label: 'Audio', icon: '🎵' },
]

// ─── Computed ─────────────────────────────────────────────────────────────────
const filteredData = computed(() => {
  let list = allData.value
  if (searchTerm.value) {
    const q = searchTerm.value.toLowerCase()
    list = list.filter(b => b.nama?.toLowerCase().includes(q) || b.kategori?.toLowerCase().includes(q))
  }
  if (filterKategori.value) list = list.filter(b => b.kategori === filterKategori.value)
  if (filterStatus.value === 'active')   list = list.filter(b => b.is_active !== false)
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

const filteredMediaList = computed(() =>
  mediaList.value.filter(m => m.jenis_media === activeMediaTab.value)
)

const mediaAccept = computed(() => {
  if (activeMediaTab.value === 'gambar') return 'image/jpeg,image/png,image/webp'
  if (activeMediaTab.value === 'video')  return 'video/mp4'
  return 'audio/mpeg,audio/mp3'
})

// ─── Watch: fetch media when modal opens in edit mode ─────────────────────────
watch(
  [showModal, editItem],
  ([isOpen, item]) => {
    if (isOpen && item) {
      fetchMedia(item.id)
    } else {
      mediaList.value = []
      mediaJudul.value = ''
      activeMediaTab.value = 'gambar'
    }
  }
)

// ─── Data loading ─────────────────────────────────────────────────────────────
async function loadData() {
  loading.value = true; error.value = null
  try { allData.value = await budayaService.getAll() }
  catch (e) { error.value = e.message }
  finally { loading.value = false }
}

function onSearch(v) { searchTerm.value = v }
function onSort({ key, dir }) { sortKey.value = key; sortDir.value = dir }
function openPhoto(b) { photoViewer.value = { visible: true, src: b.foto_url, name: b.nama, meta: b.kategori } }

// ─── Status toggle ────────────────────────────────────────────────────────────
async function toggleStatus(b) {
  const newVal = !(b.is_active !== false)
  try {
    const updated = await budayaService.toggleIsActive(b.id, newVal)
    const idx = allData.value.findIndex(x => x.id === b.id)
    if (idx !== -1) allData.value[idx] = updated
    toast(newVal ? 'Budaya diaktifkan' : 'Budaya dinonaktifkan', 'success')
  } catch (e) { toast('Gagal ubah status', 'error') }
}

// ─── Export CSV ───────────────────────────────────────────────────────────────
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

// ─── Modal open/close ─────────────────────────────────────────────────────────
function openAdd() {
  editItem.value = null
  form.value = { nama:'', kategori:'', deskripsi:'', asal_daerah:'' }
  fotoFile.value = null
  fotoPreview.value = null
  existingFotoUrl.value = null   // ← tambah ini
  showModal.value = true
}

function openEdit(b) {
  editItem.value = b
  form.value = { nama:b.nama, kategori:b.kategori, deskripsi:b.deskripsi||'', asal_daerah:b.asal_daerah||'' }
  existingFotoUrl.value = b.foto_url || null  // ← simpan URL existing
  fotoPreview.value = null                    // ← reset preview file baru
  fotoFile.value = null
  showModal.value = true
}
function closeModal() { showModal.value = false; editItem.value = null }

// ─── Save budaya ──────────────────────────────────────────────────────────────
async function saveItem() {
  if (!form.value.nama || !form.value.kategori) {
    toast('Nama dan kategori wajib diisi', 'error'); return
  }
  saving.value = true
  try {
    // Gunakan existingFotoUrl sebagai fallback
    let fotoPath = editItem.value?.foto_path || null
    let fotoUrl  = existingFotoUrl.value || editItem.value?.foto_url || null

    if (fotoFile.value) {
      const old = editItem.value?.foto_path
      if (old) await budayaService.deleteFoto(old)
      const res = await budayaService.uploadFoto(fotoFile.value)
      fotoPath = res.path
      fotoUrl  = res.url
    }

    const payload = {
      nama: form.value.nama,
      kategori: form.value.kategori,
      deskripsi: form.value.deskripsi || null,
      asal_daerah: form.value.asal_daerah || null,
      foto_path: fotoPath,
      foto_url: fotoUrl,
    }

    if (editItem.value) {
      await budayaService.update(editItem.value.id, payload)
      toast('Berhasil diperbarui', 'success')
    } else {
      await budayaService.create(payload)
      toast('Berhasil ditambahkan', 'success')
    }
    closeModal(); await loadData()
  } catch (e) { toast('Gagal menyimpan: ' + e.message, 'error') }
  finally { saving.value = false }
}

// ─── Delete budaya (+ all media) ──────────────────────────────────────────────
function confirmDelete(b) { deleteTarget.value=b; showConfirm.value=true }
async function doDelete() {
  saving.value = true
  try {
    // hapus semua media terkait terlebih dahulu
    await mediaService.deleteAllByBudayaId(deleteTarget.value.id)
    if (deleteTarget.value.foto_path) await budayaService.deleteFoto(deleteTarget.value.foto_path)
    await budayaService.delete(deleteTarget.value.id)
    toast('Berhasil dihapus','success'); showConfirm.value=false; await loadData()
  } catch(e) { toast('Gagal menghapus','error') }
  finally { saving.value = false }
}

// ─── Main foto upload ─────────────────────────────────────────────────────────
function onFileChange(e) { handleFile(e.target.files[0]) }
function onFileDrop(e) { isDragOver.value=false; handleFile(e.dataTransfer.files[0]) }
function handleFile(f) {
  if (!f) return
  fotoFile.value = f
  fotoPreview.value = URL.createObjectURL(f)
}

function removePhoto() {
  // Hapus keduanya
  fotoFile.value = null
  fotoPreview.value = null
  existingFotoUrl.value = null
}

// ─── MULTIMEDIA FUNCTIONS ─────────────────────────────────────────────────────

async function fetchMedia(budayaId) {
  mediaLoading.value = true
  try {
    mediaList.value = await mediaService.getByBudayaId(budayaId)
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
  // reset input so same file can be re-selected
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

    // Simulate progress (real SDK doesn't expose upload progress)
    const progressTimer = setInterval(() => {
      if (uploadProgress.value < 85) uploadProgress.value += 10
    }, 300)

    if (tab === 'gambar') {
      result = await mediaService.uploadGambar(file)
    } else if (tab === 'video') {
      result = await mediaService.uploadVideo(file)
    } else {
      result = await mediaService.uploadAudio(file)
    }

    clearInterval(progressTimer)
    uploadProgress.value = 95

    const urutan = mediaList.value.filter(m => m.jenis_media === tab).length
    await mediaService.addMedia({
      budayaId: editItem.value.id,
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
    setTimeout(() => {
      mediaUploading.value = false
      uploadProgress.value = 0
    }, 600)
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
    await mediaService.deleteMedia(item.id, item.storage_path, item.jenis_media)
    toast('Media berhasil dihapus', 'success')
    await fetchMedia(editItem.value.id)
  } catch(e) {
    toast('Gagal hapus media: ' + e.message, 'error')
  } finally {
    deletingMediaId.value = null
    deleteMediaTarget.value = null
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function formatDate(s) { if(!s)return'–'; return new Date(s).toLocaleDateString('id-ID',{day:'numeric',month:'short',year:'numeric'}) }
function toast(message, type='success') {
  const id=Date.now(); toasts.value.push({id,message,type})
  setTimeout(()=>{toasts.value=toasts.value.filter(t=>t.id!==id)},3500)
}

onMounted(loadData)
</script>

<style scoped>
/* ─── Modal wide (for edit with media) ─────────────────────────────────── */
.modal-wide {
  max-width: 760px;
  width: 95vw;
}

/* ─── Media Section ─────────────────────────────────────────────────────── */
.media-section {
  margin-top: 24px;
  border-top: 1px solid rgba(74, 124, 89, 0.15);
  padding-top: 20px;
}

.media-add-note {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: rgba(74, 124, 89, 0.06);
  border: 1px solid rgba(74, 124, 89, 0.2);
  border-radius: 10px;
  padding: 14px 16px;
  font-size: 13px;
  color: #4a6c50;
  line-height: 1.5;
}
.media-add-note svg {
  width: 16px; height: 16px; flex-shrink: 0; margin-top: 2px;
  stroke: #4a7c59;
}

.media-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}
.media-section-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  font-weight: 700;
  color: #2c3e2d;
}
.media-section-title svg {
  width: 16px; height: 16px; stroke: #4a7c59;
}
.media-count-badge {
  background: #4a7c59;
  color: #fff;
  font-size: 11px;
  font-weight: 700;
  border-radius: 20px;
  padding: 1px 7px;
  min-width: 20px;
  text-align: center;
}

/* ─── Tabs ──────────────────────────────────────────────────────────────── */
.media-tabs {
  display: flex;
  gap: 6px;
  margin-bottom: 14px;
  background: rgba(74, 124, 89, 0.06);
  border-radius: 10px;
  padding: 4px;
}
.media-tab-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 8px 10px;
  border: none;
  border-radius: 7px;
  background: transparent;
  color: #5a7a60;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.media-tab-btn.active {
  background: #fff;
  color: #2c3e2d;
  font-weight: 700;
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
}
.tab-count {
  background: #4a7c59;
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  border-radius: 20px;
  padding: 1px 5px;
}

/* ─── Upload area (small variant) ──────────────────────────────────────── */
.upload-zone-sm {
  padding: 16px 20px !important;
}
.upload-zone-sm .upload-zone-icon {
  font-size: 24px;
  margin-bottom: 6px;
}

/* ─── Progress bar ──────────────────────────────────────────────────────── */
.upload-progress-wrap {
  margin-top: 10px;
}
.upload-progress-label {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #5a7a60;
  margin-bottom: 4px;
}
.upload-progress-bar {
  height: 6px;
  background: rgba(74, 124, 89, 0.15);
  border-radius: 999px;
  overflow: hidden;
}
.upload-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #4a7c59, #68a97a);
  border-radius: 999px;
  transition: width 0.25s ease;
}

/* ─── Media list ────────────────────────────────────────────────────────── */
.media-loading {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 20px 0;
  color: #7a998a;
  font-size: 13px;
}
.media-empty {
  text-align: center;
  padding: 24px 0;
  color: #9aaa9b;
  font-size: 13px;
}
.media-empty span { font-size: 28px; display: block; margin-bottom: 8px; }
.media-empty p { margin: 0; }

.media-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  max-height: 300px;
  overflow-y: auto;
  padding-right: 4px;
}
.media-item {
  display: flex;
  align-items: center;
  gap: 12px;
  background: #f8faf8;
  border: 1px solid rgba(74, 124, 89, 0.12);
  border-radius: 10px;
  padding: 10px 12px;
  transition: border-color 0.2s;
}
.media-item:hover { border-color: rgba(74, 124, 89, 0.3); }

.media-item-thumb {
  width: 52px;
  height: 52px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
  background: #eef2ee;
}
.media-item-thumb img {
  width: 100%; height: 100%; object-fit: cover;
}
.media-item-thumb-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
}

.media-item-info {
  flex: 1;
  min-width: 0;
}
.media-item-title {
  font-size: 13px;
  font-weight: 600;
  color: #2c3e2d;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.media-item-meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
}
.media-item-date {
  font-size: 11px;
  color: #8a998b;
}

/* Badge colors for media types */
.badge-blue { background: rgba(74, 124, 200, 0.1); color: #3a6cb0; }
.badge-purple { background: rgba(120, 74, 180, 0.1); color: #784ab4; }

.media-audio-player {
  width: 100%;
  height: 32px;
  margin-top: 6px;
  border-radius: 6px;
  accent-color: #4a7c59;
}

.media-video-link {
  display: inline-block;
  margin-top: 4px;
  font-size: 12px;
  color: #4a7c59;
  font-weight: 600;
  text-decoration: none;
}
.media-video-link:hover { text-decoration: underline; }

/* ─── Danger ghost button for delete media ─────────────────────────────── */
.btn-danger-ghost {
  background: transparent;
  border: 1px solid rgba(214, 125, 92, 0.3);
  color: #d67d5c;
  border-radius: 8px;
  padding: 6px 8px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.btn-danger-ghost:hover {
  background: rgba(214, 125, 92, 0.08);
  border-color: #d67d5c;
}
.btn-danger-ghost:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
