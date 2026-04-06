<template>
  <div class="sidebar-inner">
    <div class="sidebar-brand">
      <div class="sidebar-brand-icon">
        <svg viewBox="0 0 24 24" fill="none" stroke="#4A7C59" stroke-width="2" width="24" height="24">
          <path d="M12 2L2 7l10 5 10-5-10-5z"/>
          <path d="M2 17l10 5 10-5"/>
          <path d="M2 12l10 5 10-5"/>
        </svg>
      </div>
      <div class="sidebar-brand-text">
        <div class="sidebar-brand-name">Cultural Bima</div>
        <div class="sidebar-brand-sub">Admin Panel</div>
      </div>
    </div>

    <nav class="sidebar-nav">
      <div class="sidebar-nav-label">Menu Utama</div>
      <router-link to="/" class="nav-item" @click="$emit('navigate')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
          <rect x="3" y="3" width="7" height="7" rx="1"/>
          <rect x="14" y="3" width="7" height="7" rx="1"/>
          <rect x="3" y="14" width="7" height="7" rx="1"/>
          <rect x="14" y="14" width="7" height="7" rx="1"/>
        </svg>
        Dashboard
      </router-link>

      <div class="sidebar-nav-label">Data Management</div>
      <router-link to="/budaya" class="nav-item" @click="$emit('navigate')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
          <path d="M12 2L2 7l10 5 10-5-10-5z"/>
          <path d="M2 17l10 5 10-5"/>
          <path d="M2 12l10 5 10-5"/>
        </svg>
        Kelola Budaya
      </router-link>

      <router-link to="/wisata" class="nav-item" @click="$emit('navigate')">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
        Kelola Wisata
      </router-link>
    </nav>

    <div class="sidebar-footer" style="color: #999999;">Cultural Bima &copy; 2025</div>
  </div>
</template>

<script setup>
defineEmits(['navigate'])
</script>