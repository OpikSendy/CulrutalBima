// lib/data/services/supabase_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;

  SupabaseService._internal() {
    _client = Supabase.instance.client;
  }

  factory SupabaseService() {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  // Getter untuk client
  SupabaseClient get client => _client;

  // ============================================
  // DATABASE OPERATIONS
  // ============================================

  /// Select data dari tabel
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String? column,
    dynamic value,
    String? orderBy,
    bool ascending = false,
  }) async {
    try {
      dynamic query = _client.from(table).select();

      // Filter by column
      if (column != null && value != null) {
        query = query.eq(column, value);
      }

      // Order by
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error selecting from $table: $e');
    }
  }

  /// Search data (ILIKE)
  Future<List<Map<String, dynamic>>> search({
    required String table,
    required String column,
    required String searchTerm,
    String? orderBy,
  }) async {
    try {
      dynamic query = _client.from(table).select().ilike(column, '%$searchTerm%');

      if (orderBy != null) {
        query = query.order(orderBy, ascending: true);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching $table: $e');
    }
  }

  /// Insert data ke tabel
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Error inserting to $table: $e');
    }
  }

  /// Update data di tabel
  Future<Map<String, dynamic>> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error updating $table: $e');
    }
  }

  /// Delete data dari tabel
  Future<void> delete({
    required String table,
    required String id,
  }) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting from $table: $e');
    }
  }

  /// Get single record by ID
  Future<Map<String, dynamic>> getById({
    required String table,
    required String id,
  }) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      throw Exception('Error getting $table by id: $e');
    }
  }

  // ============================================
  // STORAGE OPERATIONS
  // ============================================

  /// Upload file ke storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      final String fullPath = await _client.storage
          .from(bucket)
          .upload(path, file);

      return fullPath;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Update file di storage (replace)
  Future<String> updateFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      // Update akan otomatis replace file yang ada
      final String fullPath = await _client.storage
          .from(bucket)
          .update(path, file);

      return fullPath;
    } catch (e) {
      throw Exception('Error updating file: $e');
    }
  }

  /// Delete file dari storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  /// Get public URL dari file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// List files in storage folder
  Future<List<FileObject>> listFiles({
    required String bucket,
    String? path,
  }) async {
    try {
      final files = await _client.storage.from(bucket).list(path: path);
      return files;
    } catch (e) {
      throw Exception('Error listing files: $e');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Check koneksi ke Supabase
  Future<bool> checkConnection() async {
    try {
      await _client.from('budaya').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate unique filename untuk upload
  String generateFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalFilename.split('.').last;
    final uuid = _client.auth.currentUser?.id ?? 'anonymous';
    return '${uuid}_$timestamp.$extension';
  }
}