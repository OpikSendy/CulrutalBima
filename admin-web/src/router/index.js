// src/router/index.js
import { createRouter, createWebHashHistory } from 'vue-router'
import DashboardView from '../views/DashboardView.vue'
import BudayaView from '../views/BudayaView.vue'
import WisataView from '../views/WisataView.vue'

const routes = [
  {
    path: '/',
    name: 'Dashboard',
    component: DashboardView,
  },
  {
    path: '/budaya',
    name: 'Budaya',
    component: BudayaView,
  },
  {
    path: '/wisata',
    name: 'Wisata',
    component: WisataView,
  },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

export default router
