<template>
  <Transition name="fade">
    <div v-if="show" class="modal-overlay" @click.self="$emit('cancel')">
      <div class="modal modal-sm">
        <div class="modal-body" style="text-align: center; padding: 36px 28px 20px;">
          <div class="confirm-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="3 6 5 6 21 6"></polyline>
              <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"></path>
              <path d="M10 11v6M14 11v6"></path>
              <path d="M9 6V4a1 1 0 011-1h4a1 1 0 011 1v2"></path>
            </svg>
          </div>
          <p class="confirm-title">{{ title }}</p>
          <p class="confirm-desc">{{ description }}</p>
        </div>
        <div class="modal-footer" style="justify-content: center; gap: 12px;">
          <button class="btn btn-secondary" @click="$emit('cancel')" :disabled="loading">
            Batal
          </button>
          <button class="btn btn-danger" @click="$emit('confirm')" :disabled="loading">
            <span v-if="loading" class="spinner spinner-sm"></span>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="3 6 5 6 21 6"></polyline>
              <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"></path>
            </svg>
            {{ loading ? 'Menghapus...' : confirmLabel }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
defineProps({
  show: { type: Boolean, default: false },
  title: { type: String, default: 'Yakin ingin menghapus?' },
  description: { type: String, default: 'Data yang dihapus tidak dapat dikembalikan.' },
  confirmLabel: { type: String, default: 'Hapus' },
  loading: { type: Boolean, default: false },
})

defineEmits(['confirm', 'cancel'])
</script>
