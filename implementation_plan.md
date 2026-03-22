# Cultural Bima — Implementation Plan

## Background

Proyek **Cultural Bima** adalah aplikasi Flutter Android sebagai pusat informasi budaya & wisata Kabupaten Bima. Backend sudah menggunakan **Supabase** (PostgreSQL + Storage) dengan dua tabel utama: `wisata` dan `budaya`.

Tugas ini meliputi dua hal utama:
1. **Web Admin Panel** — panel manajemen data berbasis web (HTML/CSS/JS) yang terhubung langsung ke Supabase
2. **Peningkatan UI Flutter Mobile** — mempercantik tampilan layar-layar utama aplikasi

---

## User Review Required

> [!IMPORTANT]
> **Konfigurasi Supabase diperlukan sebelum Web Admin Panel bisa berjalan.**  
> File `admin-web/js/config.js` akan menyediakan placeholder `SUPABASE_URL` dan `SUPABASE_ANON_KEY` yang harus diisi dengan kredensial Supabase proyek Anda. Pastikan nilai ini tersedia sebelum menjalankan panel admin.

> [!NOTE]
> Web Admin Panel akan dibuat sebagai **folder terpisah** (`admin-web/`) di root proyek Flutter (`c:\Capstone\CulrutalBima\admin-web\`). Panel ini bisa dibuka langsung sebagai file HTML di browser, atau di-serve menggunakan Live Server di VS Code.

---

## Proposed Changes

### 1. Web Admin Panel (NEW)

Panel admin berbasis web standalone menggunakan **HTML + Vanilla CSS + Vanilla JS** tanpa framework tambahan. Menggunakan **Supabase JS SDK** (via CDN) untuk koneksi langsung ke database.

**Fitur utama:**
- Dashboard dengan statistik data (total budaya, wisata, breakdown per kategori)
- Kelola Budaya: list, tambah, edit, hapus, upload foto
- Kelola Wisata: list, tambah, edit, hapus, upload foto, koordinat peta
- Preview foto langsung dari Supabase Storage
- Filter & pencarian data
- Konfirmasi hapus dengan modal dialog

**Desain:** Mengikuti palet warna yang sama dengan Flutter app (sage green `#4A7C59`, brown `#8B6F47`, cream `#FAF8F3`), dark sidebar navigation, card-based layout, glassmorphism accents.

---

#### [NEW] [config.js](file:///c:/Capstone/CulrutalBima/admin-web/js/config.js)
Menyimpan konfigurasi Supabase URL & anon key (placeholder, diisi oleh developer).

#### [NEW] [supabase-client.js](file:///c:/Capstone/CulrutalBima/admin-web/js/supabase-client.js)
Wrapper untuk Supabase JS SDK: CRUD operations, storage upload/delete, public URL.

#### [NEW] [budaya.js](file:///c:/Capstone/CulrutalBima/admin-web/js/budaya.js)
Logika halaman Kelola Budaya: fetch list, render table, form create/edit, delete dengan konfirmasi.

#### [NEW] [wisata.js](file:///c:/Capstone/CulrutalBima/admin-web/js/wisata.js)
Logika halaman Kelola Wisata: fetch list, render table, form create/edit, koordinat latitude/longitude, delete.

#### [NEW] [dashboard.js](file:///c:/Capstone/CulrutalBima/admin-web/js/dashboard.js)
Statistik dashboard: total budaya, wisata, budaya per kategori, wisata terbaru.

#### [NEW] [app.js](file:///c:/Capstone/CulrutalBima/admin-web/js/app.js)
Entry point: routing SPA sederhana (hash-based), inisialisasi Supabase client.

#### [NEW] [styles.css](file:///c:/Capstone/CulrutalBima/admin-web/css/styles.css)
Design system lengkap: CSS variables, dark sidebar, responsive layout, card components, form styles, modal, table, toast notifications, loading states, animations.

#### [NEW] [index.html](file:///c:/Capstone/CulrutalBima/admin-web/index.html)
Shell HTML utama dengan sidebar navigasi, header, dan content area. Semua halaman di-render secara dinamis via JS.

---

### 2. Flutter Mobile UI Improvements

Meningkatkan kualitas visual layar-layar utama Flutter. Tidak ada perubahan logika atau arsitektur.

---

#### [MODIFY] [splash_screen.dart](file:///c:/Capstone/CulrutalBima/lib/views/screens/splash_screen.dart)
- Animasi lebih dinamis: particle effects, gradient background bergerak
- Logo lebih premium dengan glow effect
- Loading bar animated

#### [MODIFY] [home_screen.dart](file:///c:/Capstone/CulrutalBima/lib/views/screens/home_screen.dart)
- Header section dengan gradient hero banner
- Stats row (total budaya & wisata) yang live dari Supabase
- Menu cards lebih tinggi dengan subtle patterns
- Bottom section dengan info app lebih menarik

#### [MODIFY] [katalog_budaya_screen.dart](file:///c:/Capstone/CulrutalBima/lib/views/screens/katalog_budaya_screen.dart)
- Grid view option di samping list view
- Budaya cards lebih besar dengan foto prominent
- Animasi masuk staggered

#### [MODIFY] [budaya_detail_screen.dart](file:///c:/Capstone/CulrutalBima/lib/views/screens/budaya_detail_screen.dart)
- Hero image lebih besar (350→400px)
- Info chips lebih stylish
- Deskripsi dengan typography yang lebih baik
- Share button di AppBar

#### [MODIFY] [admin_panel_screen.dart](file:///c:/Capstone/CulrutalBima/lib/views/admin/admin_panel_screen.dart)
- Stats mini cards (total budaya/wisata)
- Quick action buttons
- More polished header section

---

## Verification Plan

### Browser Testing — Web Admin Panel
1. Buka `admin-web/index.html` di browser (langsung double-click atau gunakan VS Code Live Server)
2. Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `admin-web/js/config.js`
3. Verifikasi dashboard tampil dengan statistik yang benar
4. Buka menu **Kelola Budaya** → verifikasi list data muncul dari Supabase
5. Klik **Tambah Budaya** → isi form → submit → verifikasi data tersimpan di Supabase
6. Klik tombol **Edit** pada satu data → ubah → simpan → verifikasi perubahan tersimpan
7. Klik tombol **Hapus** → konfirmasi → verifikasi data terhapus dari Supabase
8. Repeat langkah 4-7 untuk menu **Kelola Wisata**
9. Test upload foto: pilih gambar di form → submit → verifikasi foto muncul di Supabase Storage

### Flutter Build Verification
```powershell
cd c:\Capstone\CulrutalBima
flutter analyze
flutter pub get
```
Tidak ada compile error yang harus muncul setelah perubahan UI.

### Manual Testing — Flutter App
Jalankan di emulator/device Android:
```powershell
cd c:\Capstone\CulrutalBima
flutter run
```
Verifikasi:
- Splash screen animasi berjalan mulus
- Home screen tampil dengan benar
- Navigasi ke Katalog Budaya dan Peta Wisata berfungsi
- Admin Panel dapat diakses dan CRUD berfungsi
