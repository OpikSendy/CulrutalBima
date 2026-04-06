<template>
  <!-- ─── DESKTOP: Sidebar kiri ─── -->
  <aside v-if="!mobile" class="sidebar sidebar-desktop">
    <SidebarContent />
  </aside>

  <!-- ─── MOBILE: Drawer + Floating Bottom Bar ─── -->
  <template v-else>
    <!-- Drawer slide dari kiri (saat hamburger diklik) -->
    <aside :class="['sidebar sidebar-drawer', { open }]">
      <div class="sidebar-drawer-header">
        <span class="sidebar-brand-name">Cultural Bima</span>
        <button class="drawer-close-btn" @click="$emit('close')">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
            <line x1="18" y1="6" x2="6" y2="18"/>
            <line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
        </button>
      </div>
      <SidebarContent @navigate="$emit('close')" />
    </aside>

    <!-- Floating Bottom Bar -->
    <nav class="floating-bar">
      <router-link to="/" class="floating-bar-item" @click="$emit('close')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="22" height="22">
          <rect x="3" y="3" width="7" height="7" rx="1"/>
          <rect x="14" y="3" width="7" height="7" rx="1"/>
          <rect x="3" y="14" width="7" height="7" rx="1"/>
          <rect x="14" y="14" width="7" height="7" rx="1"/>
        </svg>
        <span>Dashboard</span>
      </router-link>

      <router-link to="/budaya" class="floating-bar-item" @click="$emit('close')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="22" height="22">
          <path d="M12 2L2 7l10 5 10-5-10-5z"/>
          <path d="M2 17l10 5 10-5"/>
          <path d="M2 12l10 5 10-5"/>
        </svg>
        <span>Budaya</span>
      </router-link>

      <router-link to="/wisata" class="floating-bar-item" @click="$emit('close')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="22" height="22">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
        <span>Wisata</span>
      </router-link>
    </nav>
  </template>
</template>

<script setup>
import SidebarContent from './SidebarContent.vue'

defineProps({
  open: Boolean,
  mobile: Boolean,
})

defineEmits(['close'])
</script>

<style scoped>
/* ─── DESKTOP SIDEBAR ─────────────────────────────── */
.sidebar-desktop {
  width: 220px;
  min-height: 100vh;
  flex-shrink: 0;
  background: #1C2B1E;
  display: flex;
  flex-direction: column;
}

/* ─── MOBILE DRAWER ───────────────────────────────── */
.sidebar-drawer {
  position: fixed;
  top: 0;
  left: 0;
  height: 100%;
  width: 260px;
  background: #1C2B1E;
  z-index: 1100;
  transform: translateX(-100%);
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  display: flex;
  flex-direction: column;
  box-shadow: 4px 0 24px rgba(0,0,0,0.4);
}

.sidebar-drawer.open {
  transform: translateX(0);
}

.sidebar-drawer-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 16px 12px;
  border-bottom: 1px solid rgba(255,255,255,0.08);
}

.sidebar-brand-name {
  color: #FAF8F3;
  font-weight: 700;
  font-size: 16px;
}

.drawer-close-btn {
  background: none;
  border: none;
  color: rgba(255,255,255,0.6);
  cursor: pointer;
  padding: 4px;
  display: flex;
  align-items: center;
  border-radius: 6px;
  transition: background 0.2s;
}

.drawer-close-btn:hover {
  background: rgba(255,255,255,0.1);
}

/* ─── FLOATING BOTTOM BAR ─────────────────────────── */
.floating-bar {
  position: fixed;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 1000;
  display: flex;
  align-items: center;
  gap: 4px;
  background: rgba(28, 43, 30, 0.92);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border: 1px solid rgba(74, 124, 89, 0.3);
  border-radius: 100px;
  padding: 8px 12px;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.3),
    0 2px 8px rgba(0, 0, 0, 0.2),
    inset 0 1px 0 rgba(255,255,255,0.06);
}

.floating-bar-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 8px 16px;
  border-radius: 100px;
  text-decoration: none;
  color: rgba(255, 255, 255, 0.55);
  font-size: 10px;
  font-weight: 500;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.floating-bar-item:hover {
  color: rgba(255, 255, 255, 0.9);
  background: rgba(74, 124, 89, 0.2);
}

.floating-bar-item.router-link-active,
.floating-bar-item.router-link-exact-active {
  color: #FAF8F3;
  background: #4A7C59;
  box-shadow: 0 2px 8px rgba(74, 124, 89, 0.4);
}

.floating-bar-item svg {
  flex-shrink: 0;
}
</style>