// src/services/supabaseService.js

import { createClient } from '@supabase/supabase-js'
import {
  SUPABASE_URL,
  SUPABASE_ANON_KEY,
  STORAGE_BUCKET,
  STORAGE_BUCKET_VIDEO,
  STORAGE_BUCKET_AUDIO,
  STORAGE_FOLDER_BUDAYA,
  STORAGE_FOLDER_WISATA,
  TABLE_BUDAYA,
  TABLE_WISATA,
  TABLE_BUDAYA_MEDIA,
  TABLE_WISATA_MEDIA,
} from '../config/supabaseConfig'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)

export function getStorageUrl(bucket, path) {
  if (!path) return null
  const base = SUPABASE_URL.replace(/\/$/, '')
  return `${base}/storage/v1/object/public/${bucket}/${path}`
}

// ─── HELPER: Generate nama file unik ──────────────────────────────
function generateFilename(originalName) {
  const timestamp = Date.now()
  const ext = originalName.split('.').pop()
  return `${timestamp}_${Math.random().toString(36).substring(2, 9)}.${ext}`
}

// ─── HELPER: Validasi ukuran file ─────────────────────────────────
function validateFileSize(file, maxMB) {
  const maxBytes = maxMB * 1024 * 1024
  if (file.size > maxBytes) {
    throw new Error(`Ukuran file maksimal ${maxMB}MB`)
  }
}

// ============================================================
// BUDAYA SERVICE
// ============================================================
export const budayaService = {
  async getAll() {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA)
      .select('*')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },

  async getById(id) {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA)
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(payload) {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA)
      .insert(payload)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id, payload) {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA)
      .update({
        ...payload,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async delete(id) {
    const { error } = await supabase.from(TABLE_BUDAYA).delete().eq('id', id)
    if (error) throw error
  },

  async getStats() {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA)
      .select('kategori')
    if (error) throw error
    const total = data.length
    const byKategori = data.reduce((acc, item) => {
      acc[item.kategori] = (acc[item.kategori] || 0) + 1
      return acc
    }, {})
    return { total, byKategori }
  },

  async uploadFoto(file) {
    validateFileSize(file, 5)
    const filename = generateFilename(file.name)
    const path = `${STORAGE_FOLDER_BUDAYA}/${filename}`

    const { error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(path, file, { upsert: false })
    if (error) throw error

    // ✅ Kembalikan hanya path, URL di-generate di frontend
    return { path }
  },

  async deleteFoto(path) {
    if (!path) return
    const { error } = await supabase.storage.from(STORAGE_BUCKET).remove([path])
    if (error) console.warn('Gagal hapus foto:', error)
  },

  async toggleIsActive(id, isActive) {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA)
      .update({ is_active: isActive, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },
}

// ============================================================
// WISATA SERVICE
// ============================================================
export const wisataService = {
  async getAll() {
    const { data, error } = await supabase
      .from(TABLE_WISATA)
      .select('*')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data
  },

  async getById(id) {
    const { data, error } = await supabase
      .from(TABLE_WISATA)
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data
  },

  async create(payload) {
    const { data, error } = await supabase
      .from(TABLE_WISATA)
      .insert(payload)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async update(id, payload) {
    const { data, error } = await supabase
      .from(TABLE_WISATA)
      .update({ ...payload, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },

  async delete(id) {
    const { error } = await supabase.from(TABLE_WISATA).delete().eq('id', id)
    if (error) throw error
  },

  async getStats() {
    const { count, error } = await supabase
      .from(TABLE_WISATA)
      .select('*', { count: 'exact', head: true })
    if (error) throw error
    return { total: count }
  },

  async uploadFoto(file) {
    validateFileSize(file, 5)
    const filename = generateFilename(file.name)
    const path = `${STORAGE_FOLDER_WISATA}/${filename}`

    const { error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(path, file, { upsert: false })
    if (error) throw error

    // ✅ Kembalikan hanya path, URL di-generate di frontend
    return { path }
  },

  async deleteFoto(path) {
    if (!path) return
    const { error } = await supabase.storage.from(STORAGE_BUCKET).remove([path])
    if (error) console.warn('Gagal hapus foto:', error)
  },

  async toggleIsActive(id, isActive) {
    const { data, error } = await supabase
      .from(TABLE_WISATA)
      .update({ is_active: isActive, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  },
}

// ============================================================
// BUDAYA MEDIA SERVICE
// ============================================================
export const mediaService = {

  async getByBudayaId(budayaId) {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA_MEDIA)
      .select('*')
      .eq('budaya_id', budayaId)
      .order('urutan', { ascending: true })
      .order('created_at', { ascending: true })
    if (error) throw error
    return data
  },

  async addMedia({ budayaId, jenisMedia, urlMedia, storagePath, judul, urutan = 0 }) {
    const { data, error } = await supabase
      .from(TABLE_BUDAYA_MEDIA)
      .insert({
        budaya_id: budayaId,
        jenis_media: jenisMedia,
        url_media: urlMedia,
        storage_path: storagePath,
        judul: judul || null,
        urutan,
      })
      .select()
      .single()
    if (error) throw error
    return data
  },

  async deleteMedia(id, storagePath, jenisMedia) {
    if (storagePath) {
      const bucket = jenisMedia === 'video'
        ? STORAGE_BUCKET_VIDEO
        : jenisMedia === 'audio'
          ? STORAGE_BUCKET_AUDIO
          : STORAGE_BUCKET

      const { error: storageError } = await supabase.storage
        .from(bucket)
        .remove([storagePath])
      if (storageError) console.warn('Gagal hapus file storage:', storageError)
    }

    const { error } = await supabase
      .from(TABLE_BUDAYA_MEDIA)
      .delete()
      .eq('id', id)
    if (error) throw error
  },

  async deleteAllByBudayaId(budayaId) {
    const mediaList = await this.getByBudayaId(budayaId)
    for (const media of mediaList) {
      await this.deleteMedia(media.id, media.storage_path, media.jenis_media)
    }
  },

  async uploadGambar(file) {
    validateFileSize(file, 5)
    if (!file.type.startsWith('image/')) {
      throw new Error('File harus berupa gambar (JPG, PNG, WebP)')
    }

    const filename = generateFilename(file.name)
    const path = `${STORAGE_FOLDER_BUDAYA}/media/${filename}`

    const { error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(path, file, { upsert: false })
    if (error) throw error

    // ✅ Gunakan SDK resmi
    const url = getPublicUrl(STORAGE_BUCKET, path)
    return { path, url }
  },

  async uploadVideo(file) {
    validateFileSize(file, 50)
    if (file.type !== 'video/mp4') {
      throw new Error('Format video harus MP4')
    }

    const filename = generateFilename(file.name)
    const path = `budaya/${filename}`

    const { error } = await supabase.storage
      .from(STORAGE_BUCKET_VIDEO)
      .upload(path, file, {
        upsert: false,
        contentType: 'video/mp4',
      })
    if (error) throw error

    // ✅ Gunakan SDK resmi
    const url = getPublicUrl(STORAGE_BUCKET_VIDEO, path)
    return { path, url }
  },

  async uploadAudio(file) {
    validateFileSize(file, 10)
    const allowedTypes = ['audio/mpeg', 'audio/mp3']
    if (!allowedTypes.includes(file.type)) {
      throw new Error('Format audio harus MP3')
    }

    const filename = generateFilename(file.name)
    const path = `budaya/${filename}`

    const { error } = await supabase.storage
      .from(STORAGE_BUCKET_AUDIO)
      .upload(path, file, {
        upsert: false,
        contentType: 'audio/mpeg',
      })
    if (error) throw error

    // ✅ Gunakan SDK resmi
    const url = getPublicUrl(STORAGE_BUCKET_AUDIO, path)
    return { path, url }
  },

  async updateUrutan(id, urutan) {
    const { error } = await supabase
      .from(TABLE_BUDAYA_MEDIA)
      .update({ urutan })
      .eq('id', id)
    if (error) throw error
  },
}

// ============================================================
// WISATA MEDIA SERVICE
// ============================================================
export const wisataMediaService = {

  async getByWisataId(wisataId) {
    const { data, error } = await supabase
      .from(TABLE_WISATA_MEDIA)
      .select('*')
      .eq('wisata_id', wisataId)
      .order('urutan', { ascending: true })
      .order('created_at', { ascending: true })
    if (error) throw error
    return data
  },

  async addMedia({ wisataId, jenisMedia, urlMedia, storagePath, judul, urutan = 0 }) {
    const { data, error } = await supabase
      .from(TABLE_WISATA_MEDIA)
      .insert({
        wisata_id: wisataId,       // ← pakai wisata_id bukan budaya_id
        jenis_media: jenisMedia,
        url_media: urlMedia,
        storage_path: storagePath,
        judul: judul || null,
        urutan,
      })
      .select()
      .single()
    if (error) throw error
    return data
  },

  async deleteMedia(id, storagePath, jenisMedia) {
    if (storagePath) {
      const bucket = jenisMedia === 'video'
        ? STORAGE_BUCKET_VIDEO
        : jenisMedia === 'audio'
          ? STORAGE_BUCKET_AUDIO
          : STORAGE_BUCKET

      const { error: storageError } = await supabase.storage
        .from(bucket)
        .remove([storagePath])
      if (storageError) console.warn('Gagal hapus file storage:', storageError)
    }

    const { error } = await supabase
      .from(TABLE_WISATA_MEDIA)
      .delete()
      .eq('id', id)
    if (error) throw error
  },

  async deleteAllByWisataId(wisataId) {
    const mediaList = await this.getByWisataId(wisataId)
    for (const media of mediaList) {
      await this.deleteMedia(media.id, media.storage_path, media.jenis_media)
    }
  },

  async uploadGambar(file) {
    validateFileSize(file, 5)
    if (!file.type.startsWith('image/')) {
      throw new Error('File harus berupa gambar (JPG, PNG, WebP)')
    }
    const filename = generateFilename(file.name)
    const path = `wisata/media/${filename}`
    const { error } = await supabase.storage
      .from(STORAGE_BUCKET)
      .upload(path, file, { upsert: false })
    if (error) throw error
    const url = getPublicUrl(STORAGE_BUCKET, path)
    return { path, url }
  },

  async uploadVideo(file) {
    validateFileSize(file, 50)
    if (file.type !== 'video/mp4') throw new Error('Format video harus MP4')
    const filename = generateFilename(file.name)
    const path = `wisata/${filename}`
    const { error } = await supabase.storage
      .from(STORAGE_BUCKET_VIDEO)
      .upload(path, file, { upsert: false, contentType: 'video/mp4' })
    if (error) throw error
    const url = getPublicUrl(STORAGE_BUCKET_VIDEO, path)
    return { path, url }
  },

  async uploadAudio(file) {
    validateFileSize(file, 10)
    const allowedTypes = ['audio/mpeg', 'audio/mp3']
    if (!allowedTypes.includes(file.type)) throw new Error('Format audio harus MP3')
    const filename = generateFilename(file.name)
    const path = `wisata/${filename}`
    const { error } = await supabase.storage
      .from(STORAGE_BUCKET_AUDIO)
      .upload(path, file, { upsert: false, contentType: 'audio/mpeg' })
    if (error) throw error
    const url = getPublicUrl(STORAGE_BUCKET_AUDIO, path)
    return { path, url }
  },
}