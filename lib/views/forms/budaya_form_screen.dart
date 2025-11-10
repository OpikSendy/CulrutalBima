// lib/views/screens/budaya_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/budaya_model.dart';
import '../../viewmodels/budaya_viewmodel.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/constants/app_strings.dart';

enum CrudMode { create, update }

class BudayaFormScreen extends StatefulWidget {
  final CrudMode mode;
  final BudayaModel? budaya; // Required jika mode = update

  const BudayaFormScreen({
    super.key,
    required this.mode,
    this.budaya,
  }) : assert(
  mode == CrudMode.create || (mode == CrudMode.update && budaya != null),
  'budaya is required when mode is update',
  );

  @override
  State<BudayaFormScreen> createState() => _BudayaFormScreenState();
}

class _BudayaFormScreenState extends State<BudayaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _asalDaerahController = TextEditingController();

  String _selectedKategori = 'Tarian';
  File? _selectedImage;
  bool _isLoading = false;

  final List<String> _kategoriList = [
    'Tarian',
    'Pakaian Adat',
    'Rumah Adat',
    'Kuliner',
    'Musik',
    'Kerajinan',
  ];

  @override
  void initState() {
    super.initState();
    // Jika edit mode, isi form dengan data existing
    if (widget.budaya != null) {
      _namaController.text = widget.budaya!.nama;
      _deskripsiController.text = widget.budaya!.deskripsi ?? '';
      _asalDaerahController.text = widget.budaya!.asalDaerah ?? '';
      _selectedKategori = widget.budaya!.kategori;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _asalDaerahController.dispose();
    super.dispose();
  }

  bool get isEditMode => widget.budaya != null;

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

    final viewModel = context.read<BudayaViewModel>();
    bool success = false;

    try {
      if (isEditMode) {
        // Update existing budaya
        success = await viewModel.updateBudaya(
          id: widget.budaya!.id,
          nama: _namaController.text.trim(),
          kategori: _selectedKategori,
          deskripsi: _deskripsiController.text.trim(),
          asalDaerah: _asalDaerahController.text.trim(),
          newFoto: _selectedImage,
          oldFotoPath: widget.budaya!.fotoPath,
        );
      } else {
        // Create new budaya
        success = await viewModel.createBudaya(
          nama: _namaController.text.trim(),
          kategori: _selectedKategori,
          deskripsi: _deskripsiController.text.trim(),
          asalDaerah: _asalDaerahController.text.trim(),
          foto: _selectedImage,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? 'Budaya berhasil diupdate'
                    : 'Budaya berhasil ditambahkan',
              ),
              backgroundColor: const Color(0xFF4A7C59),
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
        title: Text(isEditMode ? 'Edit Budaya' : 'Tambah Budaya'),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(constraints.maxWidth > 600 ? 32 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker
                      _buildImagePicker(constraints),
                      const SizedBox(height: 24),

                      // Nama
                      _buildTextField(
                        controller: _namaController,
                        label: 'Nama Budaya',
                        hint: 'Contoh: Tari Peresean',
                        icon: Icons.museum,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama budaya harus diisi';
                          }
                          if (value.trim().length < 3) {
                            return 'Nama budaya minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kategori Dropdown
                      _buildKategoriDropdown(),
                      const SizedBox(height: 16),

                      // Asal Daerah
                      _buildTextField(
                        controller: _asalDaerahController,
                        label: 'Asal Daerah',
                        hint: 'Contoh: Kabupaten Bima',
                        icon: Icons.location_on,
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      _buildTextField(
                        controller: _deskripsiController,
                        label: 'Deskripsi',
                        hint: 'Ceritakan tentang budaya ini...',
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
                      // Extra padding untuk scroll
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                    ],
                  ),
                );
              },
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

  Widget _buildImagePicker(BoxConstraints constraints) {
    // Responsive height untuk image picker
    final imageHeight = constraints.maxWidth > 600 ? 250.0 : 200.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Budaya',
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
            height: imageHeight,
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
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
                : widget.budaya?.fotoUrl != null
                ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.budaya!.fotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Color(0xFF8A998B),
                        ),
                      );
                    },
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
                : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: constraints.maxWidth > 600 ? 70 : 60,
                    color: const Color(0xFF8A998B),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap untuk pilih foto',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8A998B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Max 5MB (JPG, PNG, WebP)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8A998B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: Icon(icon, size: 22),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E2D),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedKategori,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category, size: 22),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
            ),
            items: _kategoriList.map((kategori) {
              return DropdownMenuItem(
                value: kategori,
                child: Text(
                  kategori,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedKategori = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }
}