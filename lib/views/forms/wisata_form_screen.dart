// lib/views/screens/wisata_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/wisata_model.dart';
import '../../viewmodels/wisata_viewmodel.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/constants/app_strings.dart';

enum CrudMode { create, update }

class WisataFormScreen extends StatefulWidget {
  final CrudMode mode;
  final WisataModel? wisata; // Required jika mode = update

  const WisataFormScreen({
    super.key,
    required this.mode,
    this.wisata,
  }) : assert(
  mode == CrudMode.create || (mode == CrudMode.update && wisata != null),
  'wisata is required when mode is update',
  );

  @override
  State<WisataFormScreen> createState() => _WisataFormScreenState();
}

class _WisataFormScreenState extends State<WisataFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _alamatController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Jika edit mode, isi form dengan data existing
    if (widget.wisata != null) {
      _namaController.text = widget.wisata!.nama;
      _deskripsiController.text = widget.wisata!.deskripsi ?? '';
      _alamatController.text = widget.wisata!.alamat ?? '';
      _latitudeController.text = widget.wisata!.latitude.toString();
      _longitudeController.text = widget.wisata!.longitude.toString();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _alamatController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  bool get isEditMode => widget.wisata != null;

  Future<void> _pickImage() async {
    final image = await ImagePickerHelper.pickImage(context);
    if (image != null) {
      // Validate image
      final error = ImagePickerHelper.validateImage(image);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final viewModel = context.read<WisataViewModel>();
    bool success = false;

    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      if (isEditMode) {
        // Update existing wisata
        success = await viewModel.updateWisata(
          id: widget.wisata!.id,
          nama: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          alamat: _alamatController.text.trim(),
          newFoto: _selectedImage,
          oldFotoPath: widget.wisata!.fotoPath,
        );
      } else {
        // Create new wisata
        success = await viewModel.createWisata(
          nama: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          latitude: latitude,
          longitude: longitude,
          alamat: _alamatController.text.trim(),
          foto: _selectedImage,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Wisata berhasil diupdate'
                    : 'Wisata berhasil ditambahkan',
              ),
              backgroundColor: const Color(0xFF8B6F47),
            ),
          );
          Navigator.pop(context, true); // Return true = success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage ?? 'Terjadi kesalahan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Format koordinat tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Wisata' : 'Tambah Wisata'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Image Picker
                _buildImagePicker(),
                const SizedBox(height: 24),

                // Nama
                _buildTextField(
                  controller: _namaController,
                  label: 'Nama Wisata',
                  hint: 'Contoh: Pantai Lakey',
                  icon: Icons.place,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wisata harus diisi';
                    }
                    if (value.trim().length < 3) {
                      return 'Nama wisata minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Alamat
                _buildTextField(
                  controller: _alamatController,
                  label: 'Alamat',
                  hint: 'Contoh: Hu\'u, Dompu, Nusa Tenggara Barat',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Koordinat Section
                const Text(
                  'Koordinat Lokasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E2D),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Latitude
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                          hintText: '-8.5348',
                          prefixIcon: Icon(Icons.my_location),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Latitude harus diisi';
                          }
                          final lat = double.tryParse(value.trim());
                          if (lat == null) {
                            return 'Format tidak valid';
                          }
                          if (lat < -90 || lat > 90) {
                            return 'Range: -90 to 90';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Longitude
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^-?\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                          hintText: '118.3707',
                          prefixIcon: Icon(Icons.explore),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Longitude harus diisi';
                          }
                          final lng = double.tryParse(value.trim());
                          if (lng == null) {
                            return 'Format tidak valid';
                          }
                          if (lng < -180 || lng > 180) {
                            return 'Range: -180 to 180';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF87CEEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF87CEEB).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: const Color(0xFF87CEEB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Buka Google Maps, tap & hold lokasi, copy koordinat',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF5A6C5B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Deskripsi
                _buildTextField(
                  controller: _deskripsiController,
                  label: 'Deskripsi',
                  hint: 'Ceritakan tentang tempat wisata ini...',
                  icon: Icons.description,
                  maxLines: 5,
                  validator: (value) {
                    if (value != null && value.trim().length > 1000) {
                      return 'Deskripsi maksimal 1000 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B6F47),
                    ),
                    child: Text(
                      isEditMode
                          ? AppStrings.actionSave
                          : AppStrings.actionAdd,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Menyimpan data...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Wisata',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E2D),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8A998B).withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _selectedImage != null
                ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            )
                : widget.wisata?.fotoUrl != null
                ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.wisata!.fotoUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  size: 60,
                  color: const Color(0xFF8A998B),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap untuk pilih foto',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A998B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Max 5MB (JPG, PNG, WebP)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A998B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E2D),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        ),
      ],
    );
  }
}