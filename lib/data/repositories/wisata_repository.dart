// lib/data/repositories/wisata_repository.dart

import 'dart:io';
import '../models/wisata_model.dart';
import '../services/supabase_service.dart';

class WisataRepository {
  final SupabaseService _supabaseService;
  static const String _tableName = 'wisata';
  static const String _bucketName = 'budaya-images';
  static const String _folderName = 'wisata';

  WisataRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  // ============================================
  // READ OPERATIONS
  // ============================================

  /// Get semua wisata
  Future<List<WisataModel>> getAllWisata() async {
    try {
      final response = await _supabaseService.select(
        table: _tableName,
        orderBy: 'created_at',
        ascending: false,
      );

      return response.map((json) => WisataModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mengambil data wisata: $e');
    }
  }

  /// Get single wisata by ID
  Future<WisataModel> getWisataById(String id) async {
    try {
      final response = await _supabaseService.getById(
        table: _tableName,
        id: id,
      );

      return WisataModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengambil detail wisata: $e');
    }
  }

  /// Search wisata by nama
  Future<List<WisataModel>> searchWisata(String searchTerm) async {
    try {
      final response = await _supabaseService.search(
        table: _tableName,
        column: 'nama',
        searchTerm: searchTerm,
        orderBy: 'nama',
      );

      return response.map((json) => WisataModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Gagal mencari wisata: $e');
    }
  }

  // ============================================
  // CREATE OPERATIONS
  // ============================================

  /// Create wisata baru (dengan foto)
  Future<WisataModel> createWisata({
    required String nama,
    String? deskripsi,
    required double latitude,
    required double longitude,
    String? alamat,
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
        'deskripsi': deskripsi,
        'latitude': latitude,
        'longitude': longitude,
        'alamat': alamat,
        'foto_path': fotoPath,
      };

      final response = await _supabaseService.insert(
        table: _tableName,
        data: data,
      );

      return WisataModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal menambah wisata baru: $e');
    }
  }

  // ============================================
  // UPDATE OPERATIONS
  // ============================================

  /// Update wisata (dengan opsi ganti foto)
  Future<WisataModel> updateWisata({
    required String id,
    required String nama,
    String? deskripsi,
    required double latitude,
    required double longitude,
    String? alamat,
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
        'deskripsi': deskripsi,
        'latitude': latitude,
        'longitude': longitude,
        'alamat': alamat,
        'foto_path': fotoPath,
      };

      final response = await _supabaseService.update(
        table: _tableName,
        id: id,
        data: data,
      );

      return WisataModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal mengupdate wisata: $e');
    }
  }

  // ============================================
  // DELETE OPERATIONS
  // ============================================

  /// Delete wisata (dengan foto)
  Future<void> deleteWisata(String id, String? fotoPath) async {
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
      throw Exception('Gagal menghapus wisata: $e');
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