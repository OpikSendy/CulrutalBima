<!-- src/components/DataTable.vue -->
<template>
  <div class="card">
    <!-- Toolbar Slot -->
    <div class="card-header">
      <div class="toolbar">
        <!-- Search -->
        <div class="search-input-wrap">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line>
          </svg>
          <input
            v-model="searchQuery"
            class="search-input"
            :placeholder="searchPlaceholder || 'Cari...'"
            @input="$emit('search', searchQuery)"
          />
        </div>

        <!-- Category Filter Slot -->
        <slot name="filters" />

        <div class="toolbar-right">
          <!-- Action Buttons Slot -->
          <slot name="actions" />
        </div>
      </div>
    </div>

    <!-- Table -->
    <div class="table-wrapper">
      <!-- Loading -->
      <div v-if="loading" class="loading-wrapper">
        <div class="spinner"></div>
        <span class="loading-text">Memuat data...</span>
      </div>

      <!-- Error -->
      <div v-else-if="error" class="empty-state">
        <div class="empty-state-icon" style="background: rgba(214,125,92,0.1)">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="color:#d67d5c">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
        </div>
        <div class="empty-state-title">Gagal Memuat Data</div>
        <div class="empty-state-desc">{{ error }}</div>
        <button class="btn btn-primary btn-sm" @click="$emit('retry')">Coba Lagi</button>
      </div>

      <!-- Empty -->
      <div v-else-if="!items || items.length === 0" class="empty-state">
        <div class="empty-state-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="3" y="3" width="18" height="18" rx="3"></rect>
            <path d="M3 9h18M9 21V9"></path>
          </svg>
        </div>
        <div class="empty-state-title">{{ emptyTitle || 'Belum Ada Data' }}</div>
        <div class="empty-state-desc">{{ emptyDesc || 'Data akan muncul di sini setelah ditambahkan.' }}</div>
      </div>

      <!-- Table -->
      <table v-else class="table">
        <thead>
          <tr>
            <slot name="headers" :sort="sortState" :onSort="onSort" />
          </tr>
        </thead>
        <tbody>
          <slot name="rows" :items="items" />
        </tbody>
      </table>
    </div>

    <!-- Footer: count -->
    <div v-if="items && items.length > 0" class="pagination">
      <span class="pagination-info">Menampilkan {{ items.length }} data</span>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  items: Array,
  loading: Boolean,
  error: String,
  searchPlaceholder: String,
  emptyTitle: String,
  emptyDesc: String,
})

const emit = defineEmits(['search', 'retry', 'sort'])

const searchQuery = ref('')

// Sort state
const sortState = ref({ key: null, dir: 'asc' })

function onSort(key) {
  if (sortState.value.key === key) {
    sortState.value.dir = sortState.value.dir === 'asc' ? 'desc' : 'asc'
  } else {
    sortState.value.key = key
    sortState.value.dir = 'asc'
  }
  emit('sort', { ...sortState.value })
}
</script>
