<template>
  <div class="app-shell">
    <Sidebar :open="sidebarOpen" :mobile="isMobile" @close="sidebarOpen = false" />

    <!-- Overlay saat mobile sidebar terbuka -->
    <div v-if="isMobile && sidebarOpen" class="overlay" @click="sidebarOpen = false" />

    <!-- ─── MAIN ─── -->
    <main :class="['main-content', { 'main-mobile': isMobile }]">
      <!-- Header -->
      <header class="app-header">
        <div class="header-left">
          <!-- Tombol hamburger hanya di mobile -->
          <!-- <button v-if="isMobile" class="menu-btn" @click="toggleSidebar">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="20" height="20">
              <line x1="3" y1="6" x2="21" y2="6"/>
              <line x1="3" y1="12" x2="21" y2="12"/>
              <line x1="3" y1="18" x2="21" y2="18"/>
            </svg>
          </button> -->
          <div>
            <div class="header-page-title">{{ pageTitle }}</div>
            <div class="header-breadcrumb">Cultural Bima / {{ pageTitle }}</div>
          </div>
        </div>
        <div class="header-right">
          <div class="header-avatar">CB</div>
        </div>
      </header>

      <!-- Routed Pages -->
      <router-view v-slot="{ Component }">
        <Transition name="fade" mode="out-in">
          <component :is="Component" :key="$route.path" />
        </Transition>
      </router-view>

      <!-- Spacer agar konten tidak tertutup floating bar -->
      <div v-if="isMobile" style="height: 80px;" />
    </main>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import Sidebar from './components/Sidebar.vue'

const route = useRoute()
const pageTitle = computed(() => {
  const map = {
    '/': 'Dashboard',
    '/budaya': 'Kelola Budaya',
    '/wisata': 'Kelola Wisata',
  }
  return map[route.path] || 'Panel Admin'
})

const isMobile = ref(false)
const sidebarOpen = ref(false)

const checkScreen = () => {
  isMobile.value = window.innerWidth < 768
  if (!isMobile.value) sidebarOpen.value = true
  else sidebarOpen.value = false
}

const toggleSidebar = () => {
  sidebarOpen.value = !sidebarOpen.value
}

onMounted(() => {
  checkScreen()
  window.addEventListener('resize', checkScreen)
})

onUnmounted(() => {
  window.removeEventListener('resize', checkScreen)
})
</script>