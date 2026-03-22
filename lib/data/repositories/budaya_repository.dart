// lib/data/repositories/budaya_repository.dart

import 'dart:io';
import '../models/budaya_model.dart';
import '../services/supabase_service.dart';

class BudayaRepository {
  final SupabaseService _supabaseService;
  static const String _tableName = 'budaya';
  static const String _bucketName = 'budaya-images';
  static const String _folderName = 'budaya';

  BudayaRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get semua budaya
  Future<List<BudayaModel>> getAllBudaya() async {
    try {
      final response = await _supabaseService.select(
        table: _tableName,
        orderBy: 'created_at',
        ascending: false,
      );

      return response.map((json) => BudayaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data budaya: $e');
    }
  }

  /// Get budaya by kategori
  Future<List<BudayaModel>> getBudayaByKategori(String kategori) async {
    try {
      final response = await _supabaseService.select(
        table: _tableName,
        column: 'kategori',
        value: kategori,
        orderBy: 'nama',
        ascending: true,
      );

      return response.map((json) => BudayaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil budaya kategori $kategori: $e');
    }
  }

  /// Get single budaya by ID
  Future<BudayaModel> getBudayaById(String id) async {
    try {
      final response = await _supabaseService.getById(
        table: _tableName,
        id: id,
      );

      return BudayaModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil detail budaya: $e');
    }
  }

  /// Search budaya by nama
  Future<List<BudayaModel>> searchBudaya(String searchTerm) async {
    try {
      final response = await _supabaseService.search(
        table: _tableName,
        column: 'nama',
        searchTerm: searchTerm,
        orderBy: 'nama',
      );

      return response.map((json) => BudayaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mencari budaya: $e');
    }
  }

  /// Get kategori unik (untuk filter)
  Future<List<String>> getKategoriList() async {
    try {
      final allBudaya = await getAllBudaya();
      final kategoriSet = allBudaya.map((b) => b.kategori).toSet();
      return kategoriSet.toList()..sort();
    } catch (e) {
      throw Exception('Gagal mengambil daftar kategori: $e');
    }
  }

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  /// Create budaya baru (dengan foto)
  Future<BudayaModel> createBudaya({
    required String nama,
    required String kategori,
    String? deskripsi,
    String? asalDaerah,
    File? foto,
  }) async {
    try {
      String? fotoPath;

      // Upload foto jika ada
      if (foto != null) {
        fotoPath = await _uploadFoto(foto);
      }

      // Insert ke database
      final data = {
        'nama': nama,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'asal_daerah': asalDaerah,
        'foto_path': fotoPath,
        // Simpan foto_url langsung saat insert agar tersimpan di database
        'foto_url': fotoPath != null ? getFotoUrl(fotoPath) : null,
      };

      final response = await _supabaseService.insert(
        table: _tableName,
        data: data,
      );

      return BudayaModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah budaya baru: $e');
    }
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update budaya (dengan opsi ganti foto)
  Future<BudayaModel> updateBudaya({
    required String id,
    required String nama,
    required String kategori,
    String? deskripsi,
    String? asalDaerah,
    File? newFoto,
    String? oldFotoPath,
  }) async {
    try {
      String? fotoPath = oldFotoPath;

      // Jika ada foto baru
      if (newFoto != null) {
        // Upload foto baru
        fotoPath = await _uploadFoto(newFoto);

        // Hapus foto lama jika ada
        if (oldFotoPath != null && oldFotoPath.isNotEmpty) {
          await _deleteFoto(oldFotoPath);
        }
      }

      // Update database
      final data = {
        'nama': nama,
        'kategori': kategori,
        'deskripsi': deskripsi,
        'asal_daerah': asalDaerah,
        'foto_path': fotoPath,
        // Selalu perbarui foto_url agar sinkron dengan foto_path
        'foto_url': fotoPath != null && fotoPath.isNotEmpty
            ? getFotoUrl(fotoPath)
            : null,
      };

      final response = await _supabaseService.update(
        table: _tableName,
        id: id,
        data: data,
      );

      return BudayaModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengupdate budaya: $e');
    }
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete budaya (dengan foto)
  Future<void> deleteBudaya(String id, String? fotoPath) async {
    try {
      // Hapus foto jika ada
      if (fotoPath != null && fotoPath.isNotEmpty) {
        await _deleteFoto(fotoPath);
      }

      // Hapus dari database
      await _supabaseService.delete(
        table: _tableName,
        id: id,
      );
    } catch (e) {
      throw Exception('Gagal menghapus budaya: $e');
    }
  }

  // ============================================
  // PRIVATE HELPER METHODS (STORAGE)
  // ============================================

  /// Upload foto ke storage
  Future<String> _uploadFoto(File foto) async {
    try {
      final filename = _supabaseService.generateFilename(foto.path);
      final path = '$_folderName/$filename';

      await _supabaseService.uploadFile(
        bucket: _bucketName,
        path: path,
        file: foto,
      );

      return path;
    } catch (e) {
      throw Exception('Gagal upload foto: $e');
    }
  }

  /// Delete foto dari storage
  Future<void> _deleteFoto(String path) async {
    try {
      await _supabaseService.deleteFile(
        bucket: _bucketName,
        path: path,
      );
    } catch (e) {
      // Log error tapi jangan throw, agar delete record tetap jalan
      print('Warning: Gagal menghapus foto $path - $e');
    }
  }

  /// Get public URL foto
  String getFotoUrl(String path) {
    return _supabaseService.getPublicUrl(
      bucket: _bucketName,
      path: path,
    );
  }
}