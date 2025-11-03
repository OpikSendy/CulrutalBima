// lib/viewmodels/wisata_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'dart:io';
import '../data/models/wisata_model.dart';
import '../data/repositories/wisata_repository.dart';

enum WisataState { idle, loading, success, error, empty }

class WisataViewModel extends ChangeNotifier {
  final WisataRepository _repository;

  WisataViewModel({WisataRepository? repository})
      : _repository = repository ?? WisataRepository();

  // State management
  WisataState _state = WisataState.idle;
  List<WisataModel> _wisataList = [];
  List<WisataModel> _filteredList = [];
  String? _errorMessage;
  String _searchQuery = '';

  // Getters
  WisataState get state => _state;
  List<WisataModel> get wisataList => _filteredList;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == WisataState.loading;
  bool get isEmpty => _state == WisataState.empty;
  bool get hasError => _state == WisataState.error;

  // ============================================
  // FETCH DATA
  // ============================================

  /// Fetch semua wisata
  Future<void> fetchAllWisata() async {
    _setState(WisataState.loading);

    try {
      _wisataList = await _repository.getAllWisata();
      _filteredList = List.from(_wisataList);

      if (_wisataList.isEmpty) {
        _setState(WisataState.empty);
      } else {
        _setState(WisataState.success);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(WisataState.error);
    }
  }

  /// Refresh data
  Future<void> refreshData() async {
    await fetchAllWisata();
  }

  // ============================================
  // SEARCH
  // ============================================

  /// Search wisata by nama
  void searchWisata(String query) {
    _searchQuery = query.toLowerCase();
    _applySearch();
  }

  /// Apply search filter
  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredList = List.from(_wisataList);
    } else {
      _filteredList = _wisataList.where((wisata) {
        return wisata.nama.toLowerCase().contains(_searchQuery) ||
            (wisata.alamat?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Update state
    if (_filteredList.isEmpty && _wisataList.isNotEmpty) {
      _setState(WisataState.empty);
    } else if (_filteredList.isNotEmpty) {
      _setState(WisataState.success);
    }

    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _applySearch();
  }

  // ============================================
  // CRUD OPERATIONS
  // ============================================

  /// Create wisata baru
  Future<bool> createWisata({
    required String nama,
    String? deskripsi,
    required double latitude,
    required double longitude,
    String? alamat,
    File? foto,
  }) async {
    try {
      final newWisata = await _repository.createWisata(
        nama: nama,
        deskripsi: deskripsi,
        latitude: latitude,
        longitude: longitude,
        alamat: alamat,
        foto: foto,
      );

      // Add to list
      _wisataList.insert(0, newWisata);
      _applySearch();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Update wisata
  Future<bool> updateWisata({
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
      final updatedWisata = await _repository.updateWisata(
        id: id,
        nama: nama,
        deskripsi: deskripsi,
        latitude: latitude,
        longitude: longitude,
        alamat: alamat,
        newFoto: newFoto,
        oldFotoPath: oldFotoPath,
      );

      // Update in list
      final index = _wisataList.indexWhere((w) => w.id == id);
      if (index != -1) {
        _wisataList[index] = updatedWisata;
        _applySearch();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Delete wisata
  Future<bool> deleteWisata(String id, String? fotoPath) async {
    try {
      await _repository.deleteWisata(id, fotoPath);

      // Remove from list
      _wisataList.removeWhere((w) => w.id == id);
      _applySearch();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get wisata by ID dari local list
  WisataModel? getWisataById(String id) {
    try {
      return _wisataList.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get total count
  int get totalWisata => _wisataList.length;

  /// Sort by nama
  void sortByNama({bool ascending = true}) {
    _filteredList.sort((a, b) {
      return ascending
          ? a.nama.compareTo(b.nama)
          : b.nama.compareTo(a.nama);
    });
    notifyListeners();
  }

  /// Sort by created date
  void sortByDate({bool newest = true}) {
    _filteredList.sort((a, b) {
      return newest
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
    });
    notifyListeners();
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  void _setState(WisataState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}