<template>
  <Transition name="fade">
    <div v-if="show" class="modal-overlay" @click.self="handleClose">
      <div class="modal">
        <div class="modal-header">
          <h3 class="modal-title">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path v-if="isEdit" d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"></path>
              <path v-if="isEdit" d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"></path>
              <template v-else>
                <line x1="12" y1="5" x2="12" y2="19"></line>
                <line x1="5" y1="12" x2="19" y2="12"></line>
              </template>
            </svg>
            {{ title }}
          </h3>
          <button class="modal-close" @click="handleClose">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        <div class="modal-body">
          <slot />
        </div>

        <div class="modal-footer">
          <button class="btn btn-secondary" @click="handleClose" :disabled="loading">
            Batal
          </button>
          <button class="btn btn-primary" @click="$emit('submit')" :disabled="loading">
            <span v-if="loading" class="spinner spinner-sm" style="border-color: rgba(255,255,255,0.3); border-top-color: white;"></span>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
              <polyline points="20 6 9 17 4 12"></polyline>
            </svg>
            {{ loading ? 'Menyimpan...' : (isEdit ? 'Simpan Perubahan' : 'Simpan Data') }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
const props = defineProps({
  show: { type: Boolean, default: false },
  title: { type: String, required: true },
  isEdit: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
})

const emit = defineEmits(['close', 'submit'])

function handleClose() {
  if (!props.loading) emit('close')
}
</script>
