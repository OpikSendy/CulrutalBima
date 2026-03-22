<!-- src/components/PhotoViewer.vue -->
<!-- Reusable lightbox component for fullscreen photo viewing -->
<template>
  <Teleport to="body">
    <Transition name="lightbox-fade">
      <div
        v-if="visible"
        class="lightbox-overlay"
        @click.self="close"
        @keydown.esc="close"
      >
        <!-- Close button -->
        <button class="lightbox-close" @click="close" aria-label="Tutup">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
          </svg>
        </button>

        <!-- Content -->
        <div class="lightbox-inner">
          <!-- Image -->
          <div v-if="src" class="flex-center">
            <img
              :src="src"
              :alt="name || 'Foto'"
              class="lightbox-img"
              @error="onImgError"
            />
          </div>

          <!-- No image fallback -->
          <div v-else class="lightbox-no-img">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <rect x="3" y="3" width="18" height="18" rx="3"></rect>
              <circle cx="8.5" cy="8.5" r="1.5"></circle>
              <polyline points="21 15 16 10 5 21"></polyline>
            </svg>
            <span>Foto tidak tersedia</span>
          </div>

          <!-- Info -->
          <div class="lightbox-info" v-if="name || meta">
            <div class="lightbox-info-name" v-if="name">{{ name }}</div>
            <div class="lightbox-info-meta" v-if="meta">{{ meta }}</div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, watch, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  visible: { type: Boolean, default: false },
  src: { type: String, default: null },
  name: { type: String, default: '' },
  meta: { type: String, default: '' },
})

const emit = defineEmits(['close'])

function close() {
  emit('close')
}

function onImgError(e) {
  e.target.style.display = 'none'
}

// Keyboard: Escape to close
function onKeydown(e) {
  if (e.key === 'Escape' && props.visible) close()
}

onMounted(() => window.addEventListener('keydown', onKeydown))
onUnmounted(() => window.removeEventListener('keydown', onKeydown))

// Prevent body scroll when open
watch(() => props.visible, (val) => {
  document.body.style.overflow = val ? 'hidden' : ''
})
</script>

<style scoped>
.lightbox-fade-enter-active,
.lightbox-fade-leave-active { transition: opacity 0.2s ease; }
.lightbox-fade-enter-from,
.lightbox-fade-leave-to { opacity: 0; }
</style>
