// lib/core/config/supabase_config.dart

class SupabaseConfig {
  // PENTING: Ganti dengan credentials Supabase Anda
  static const String supabaseUrl = 'https://gaueorxmraghnconvsfv.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhdWVvcnhtcmFnaG5jb252c2Z2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNzUxODcsImV4cCI6MjA3Nzc1MTE4N30.vDkoshp7lQ0OgTHrQUMZvTu7QV9hnIHHNCUq8UJi3NU';

  // Storage bucket name
  static const String bucketName = 'budaya-images';

  // Table names
  static const String budayaTable = 'budaya';
  static const String wisataTable = 'wisata';

  // Folders in storage
  static const String budayaFolder = 'budaya';
  static const String wisataFolder = 'wisata';
}