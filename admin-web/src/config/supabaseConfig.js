// src/config/supabaseConfig.js
// ============================================================
// KONFIGURASI SUPABASE - Isi dengan kredensial proyek Anda
// ============================================================

export const SUPABASE_URL = 'https://gaueorxmraghnconvsfv.supabase.co'
export const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhdWVvcnhtcmFnaG5jb252c2Z2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNzUxODcsImV4cCI6MjA3Nzc1MTE4N30.vDkoshp7lQ0OgTHrQUMZvTu7QV9hnIHHNCUq8UJi3NU'

// Nama bucket storage
export const STORAGE_BUCKET = 'budaya-images'

// Folder dalam bucket
export const STORAGE_FOLDER_BUDAYA = 'budaya'
export const STORAGE_FOLDER_WISATA = 'wisata'

// Nama tabel database
export const TABLE_BUDAYA = 'budaya'
export const TABLE_WISATA = 'wisata'

// Kategori budaya
export const KATEGORI_BUDAYA = [
  'Tarian',
  'Pakaian Adat',
  'Rumah Adat',
  'Kuliner',
  'Musik',
  'Kerajinan',
  'Tradisi',
]

// Batas koordinat wilayah Kabupaten Bima (validasi geografis)
export const BIMA_BOUNDS = {
  latMin: -9.0,
  latMax: -8.0,
  lngMin: 118.0,
  lngMax: 119.5,
}

export const BIMA_POLYGON = [
  [118.10, -8.15],
  [118.45, -8.05],
  [118.75, -8.10],
  [119.05, -8.20],
  [119.20, -8.40],
  [119.10, -8.65],
  [118.90, -8.85],
  [118.60, -8.90],
  [118.30, -8.80],
  [118.10, -8.55],
  [118.05, -8.35],
  [118.10, -8.15],
]

export function isInsideBima(lat, lng) {
  const polygon = BIMA_POLYGON
  let inside = false
  const x = lng, y = lat

  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i][0], yi = polygon[i][1]
    const xj = polygon[j][0], yj = polygon[j][1]
    const intersect =
      yi > y !== yj > y &&
      x < ((xj - xi) * (y - yi)) / (yj - yi) + xi
    if (intersect) inside = !inside
  }

  return inside
}

// Bucket untuk video dan audio
export const STORAGE_BUCKET_VIDEO = 'budaya-videos'
export const STORAGE_BUCKET_AUDIO = 'budaya-audio'

// Nama tabel media
export const TABLE_BUDAYA_MEDIA = 'budaya_media'