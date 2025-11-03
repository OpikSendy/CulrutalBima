// lib/viewmodels/budaya_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'dart:io';
import '../data/models/budaya_model.dart';
import '../data/repositories/budaya_repository.dart';

enum BudayaState { idle, loading, success, error, empty }

class BudayaViewModel extends ChangeNotifier {
  final BudayaRepository _repository;

  BudayaViewModel({BudayaRepository? repository})
      : _repository = repository ?? BudayaRepository();

  // State management
  BudayaState _state = BudayaState.idle;
  List<BudayaModel> _budayaList = [];
  List<BudayaModel> _filteredList = [];
  String? _errorMessage;
  String _selectedKategori = 'Semua';
  String _searchQuery = '';

  // Getters
  BudayaState get state => _state;
  List<BudayaModel> get budayaList => _filteredList;
  String? get errorMessage => _errorMessage;
  String get selectedKategori => _selectedKategori;
  bool get isLoading => _state == BudayaState.loading;
  bool get isEmpty => _state == BudayaState.empty;
  bool get hasError => _state == BudayaState.error;

  // ============================================
  // FETCH DATA
  // ============================================

  /// Fetch semua budaya
  Future<void> fetchAllBudaya() async {
    _setState(BudayaState.loading);

    try {
      _budayaList = await _repository.getAllBudaya();
      _applyFilters();

      if (_budayaList.isEmpty) {
        _setState(BudayaState.empty);
      } else {
        _setState(BudayaState.success);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(BudayaState.error);
    }
  }

  /// Refresh data
  Future<void> refreshData() async {
    await fetchAllBudaya();
  }

  // ============================================
  // FILTER & SEARCH
  // ============================================

  /// Filter by kategori
  void filterByKategori(String kategori) {
    _selectedKategori = kategori;
    _applyFilters();
  }

  /// Search by nama
  void searchBudaya(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Apply filters (kategori + search)
  void _applyFilters() {
    _filteredList = _budayaList.where((budaya) {
      // Filter kategori
      final matchKategori = _selectedKategori == 'Semua' ||
          budaya.kategori == _selectedKategori;

      // Filter search
      final matchSearch = _searchQuery.isEmpty ||
          budaya.nama.toLowerCase().contains(_searchQuery);

      return matchKategori && matchSearch;
    }).toList();

    // Update state
    if (_filteredList.isEmpty && _budayaList.isNotEmpty) {
      _setState(BudayaState.empty);
    } else if (_filteredList.isNotEmpty) {
      _setState(BudayaState.success);
    }

    notifyListeners();
  }

  /// Get unique kategori list
  List<String> getKategoriList() {
    final kategoriSet = _budayaList.map((b) => b.kategori).toSet();
    return ['Semua', ...kategoriSet.toList()..sort()];
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Create budaya baru
  Future<bool> createBudaya({
    required String nama,
    required String kategori,
    String? deskripsi,
    String? asalDaerah,
    File? foto,
  }) async {
    try {
      final newBudaya = await _repository.createBudaya(
        nama: nama,
        kategori: kategori,
        deskripsi: deskripsi,
        asalDaerah: asalDaerah,
        foto: foto,
      );

      // Add to list
      _budayaList.insert(0, newBudaya);
      _applyFilters();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Update budaya
  Future<bool> updateBudaya({
    required String id,
    required String nama,
    required String kategori,
    String? deskripsi,
    String? asalDaerah,
    File? newFoto,
    String? oldFotoPath,
  }) async {
    try {
      final updatedBudaya = await _repository.updateBudaya(
        id: id,
        nama: nama,
        kategori: kategori,
        deskripsi: deskripsi,
        asalDaerah: asalDaerah,
        newFoto: newFoto,
        oldFotoPath: oldFotoPath,
      );

      // Update in list
      final index = _budayaList.indexWhere((b) => b.id == id);
      if (index != -1) {
        _budayaList[index] = updatedBudaya;
        _applyFilters();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Delete budaya
  Future<bool> deleteBudaya(String id, String? fotoPath) async {
    try {
      await _repository.deleteBudaya(id, fotoPath);

      // Remove from list
      _budayaList.removeWhere((b) => b.id == id);
      _applyFilters();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get budaya by ID dari local list
  BudayaModel? getBudayaById(String id) {
    try {
      return _budayaList.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get count by kategori
  Map<String, int> getKategoriCount() {
    final Map<String, int> counts = {};
    for (var budaya in _budayaList) {
      counts[budaya.kategori] = (counts[budaya.kategori] ?? 0) + 1;
    }
    return counts;
  }

  /// Clear filters
  void clearFilters() {
    _selectedKategori = 'Semua';
    _searchQuery = '';
    _applyFilters();
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  void _setState(BudayaState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}