<!-- src/views/DashboardView.vue -->
<template>
  <div class="page-content">
    <!-- Header -->
    <div class="page-header">
      <div>
        <div class="page-title">Dashboard Overview</div>
        <div class="page-subtitle">Ringkasan data Cultural Bima</div>
      </div>
      <button class="btn btn-secondary btn-sm" @click="loadAll">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px">
          <polyline points="23 4 23 10 17 10"></polyline>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
        </svg>
        Refresh
      </button>
    </div>

    <!-- Stat Cards -->
    <div class="stats-grid stats-grid-4">
      <div class="stat-card green">
        <div class="stat-icon green">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"></path>
            <polyline points="9 22 9 12 15 12 15 22"></polyline>
          </svg>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ loading ? '–' : stats.totalBudaya }}</div>
          <div class="stat-label">Total Budaya</div>
        </div>
      </div>

      <div class="stat-card brown">
        <div class="stat-icon brown">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"></path>
            <circle cx="12" cy="10" r="3"></circle>
          </svg>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ loading ? '–' : stats.totalWisata }}</div>
          <div class="stat-label">Destinasi Wisata</div>
        </div>
      </div>

      <div class="stat-card gold">
        <div class="stat-icon gold">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"></path>
            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"></path>
          </svg>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ loading ? '–' : stats.totalKategori }}</div>
          <div class="stat-label">Kategori Budaya</div>
        </div>
      </div>

      <div class="stat-card blue">
        <div class="stat-icon blue">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <polyline points="12 6 12 12 16 14"></polyline>
          </svg>
        </div>
        <div class="stat-info">
          <div class="stat-value">{{ todayStr }}</div>
          <div class="stat-label">Tanggal Hari Ini</div>
        </div>
      </div>
    </div>

    <!-- Main Content: 2 columns -->
    <div style="display:grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px;">

      <!-- Kategori Budaya Chart -->
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="20" x2="18" y2="10"></line>
              <line x1="12" y1="20" x2="12" y2="4"></line>
              <line x1="6" y1="20" x2="6" y2="14"></line>
            </svg>
            Distribusi Kategori Budaya
          </div>
        </div>
        <div class="card-body">
          <div v-if="loading" class="loading-wrapper" style="padding:28px">
            <div class="spinner"></div>
          </div>
          <div v-else-if="Object.keys(stats.byKategori).length === 0" class="text-muted" style="font-size:13px;text-align:center;padding:24px 0">
            Belum ada data kategori
          </div>
          <div v-else class="kategori-list">
            <div
              v-for="(count, kat) in stats.byKategori"
              :key="kat"
              class="kategori-item"
            >
              <span class="kategori-label">{{ kat }}</span>
              <div class="kategori-bar-wrap">
                <div
                  class="kategori-bar"
                  :style="{ width: Math.round((count / stats.totalBudaya) * 100) + '%' }"
                ></div>
              </div>
              <span class="kategori-count">{{ count }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Recent Budaya -->
      <div class="card">
        <div class="card-header">
          <div class="card-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"></circle>
              <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            Budaya Terbaru
          </div>
        </div>
        <div class="card-body" style="padding: 8px 20px;">
          <div v-if="loading" class="loading-wrapper" style="padding:28px"><div class="spinner"></div></div>
          <div v-else-if="recentBudaya.length === 0" class="text-muted" style="font-size:13px;text-align:center;padding:24px 0">Belum ada data</div>
          <div v-else>
            <div v-for="item in recentBudaya" :key="item.id" class="recent-item">
              <img v-if="item.foto_url" :src="item.foto_url" :alt="item.nama" class="recent-img" />
              <div v-else style="width:36px;height:36px;border-radius:6px;background:#f0ede6;flex-shrink:0;display:flex;align-items:center;justify-content:center;">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="width:16px;height:16px;color:#8a998b">
                  <rect x="3" y="3" width="18" height="18" rx="3"></rect>
                  <circle cx="8.5" cy="8.5" r="1.5"></circle>
                  <polyline points="21 15 16 10 5 21"></polyline>
                </svg>
              </div>
              <div class="recent-info">
                <div class="recent-name">{{ item.nama }}</div>
                <div class="recent-meta">{{ item.kategori }}</div>
              </div>
              <span class="badge badge-green" style="font-size:10px">{{ item.kategori }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Wisata -->
    <div class="card">
      <div class="card-header">
        <div class="card-title">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"></path>
            <circle cx="12" cy="10" r="3"></circle>
          </svg>
          Wisata Terbaru
        </div>
      </div>
      <div class="table-wrapper">
        <div v-if="loading" class="loading-wrapper" style="padding:24px"><div class="spinner"></div></div>
        <table v-else-if="recentWisata.length > 0" class="table">
          <thead>
            <tr>
              <th>Nama</th>
              <th>Alamat</th>
              <th>Koordinat</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in recentWisata" :key="item.id">
              <td>
                <div class="table-name">{{ item.nama }}</div>
              </td>
              <td class="table-desc">{{ item.alamat || '–' }}</td>
              <td style="font-size:11px;color:#8a998b;font-family:monospace">
                {{ item.latitude?.toFixed(4) }}, {{ item.longitude?.toFixed(4) }}
              </td>
              <td>
                <span
                  class="badge"
                  :class="item.is_active !== false ? 'badge-green' : 'badge-default'"
                >
                  {{ item.is_active !== false ? 'Aktif' : 'Nonaktif' }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-else class="empty-state" style="padding:32px">
          <div class="empty-state-desc">Belum ada data wisata</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { budayaService, wisataService } from '../services/supabaseService.js'

const loading = ref(false)
const stats = ref({ totalBudaya: 0, totalWisata: 0, totalKategori: 0, byKategori: {} })
const recentBudaya = ref([])
const recentWisata = ref([])

const todayStr = new Date().toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })

async function loadAll() {
  loading.value = true
  try {
    const [budayaStats, wisataStats, allBudaya, allWisata] = await Promise.all([
      budayaService.getStats(),
      wisataService.getStats(),
      budayaService.getAll(),
      wisataService.getAll(),
    ])
    stats.value = {
      totalBudaya: budayaStats.total,
      totalWisata: wisataStats.total,
      totalKategori: Object.keys(budayaStats.byKategori).length,
      byKategori: budayaStats.byKategori,
    }
    recentBudaya.value = allBudaya.slice(0, 5)
    recentWisata.value = allWisata.slice(0, 6)
  } catch (e) {
    console.error('Dashboard load error:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadAll)
</script>
