<template>
  <div class="app-shell">
    <!-- ─── SIDEBAR ─── -->
    <aside class="sidebar">
      <!-- Brand -->
      <div class="sidebar-brand">
        <div class="sidebar-brand-icon">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 2L2 7l10 5 10-5-10-5z"></path>
            <path d="M2 17l10 5 10-5M2 12l10 5 10-5"></path>
          </svg>
        </div>
        <div class="sidebar-brand-text">
          <div class="sidebar-brand-name">Cultural Bima</div>
          <div class="sidebar-brand-sub">Admin Panel</div>
        </div>
      </div>

      <!-- Navigation -->
      <nav class="sidebar-nav">
        <div class="sidebar-nav-label">Menu Utama</div>

        <router-link to="/" class="nav-item" :class="{ active: $route.path === '/' }">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="3" width="7" height="7"></rect>
            <rect x="14" y="3" width="7" height="7"></rect>
            <rect x="14" y="14" width="7" height="7"></rect>
            <rect x="3" y="14" width="7" height="7"></rect>
          </svg>
          Dashboard
        </router-link>

        <div class="sidebar-nav-label">Data Management</div>

        <router-link to="/budaya" class="nav-item" :class="{ active: $route.path === '/budaya' }">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"></path>
            <polyline points="9 22 9 12 15 12 15 22"></polyline>
          </svg>
          Kelola Budaya
        </router-link>

        <router-link to="/wisata" class="nav-item" :class="{ active: $route.path === '/wisata' }">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"></path>
            <circle cx="12" cy="10" r="3"></circle>
          </svg>
          Kelola Wisata
        </router-link>
      </nav>

      <!-- Footer -->
      <div class="sidebar-footer">
        <p class="sidebar-footer-text">Cultural Bima © 2026</p>
      </div>
    </aside>

    <!-- ─── MAIN ─── -->
    <main class="main-content">
      <!-- Header -->
      <header class="app-header">
        <div class="header-left">
          <div class="header-page-title">{{ pageTitle }}</div>
          <div class="header-breadcrumb">Cultural Bima / {{ pageTitle }}</div>
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
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const pageTitle = computed(() => {
  const map = {
    '/': 'Dashboard',
    '/budaya': 'Kelola Budaya',
    '/wisata': 'Kelola Wisata',
  }
  return map[route.path] || 'Panel Admin'
})
</script>
