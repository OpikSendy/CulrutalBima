// lib/views/screens/wisata_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/wisata_model.dart';
import '../../viewmodels/wisata_viewmodel.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../core/constants/app_strings.dart';

enum CrudMode { create, update }

// ─── Konstanta wilayah Kabupaten Bima ─────────────────────────────
class _BimaRegion {
  static const double latMin = -9.0;
  static const double latMax = -8.0;
  static const double lngMin = 118.0;
  static const double lngMax = 119.5;

  // Polygon Kabupaten Bima [lat, lng]
  static const List<List<double>> polygon = [
    [-8.15, 118.10],
    [-8.05, 118.45],
    [-8.10, 118.75],
    [-8.20, 119.05],
    [-8.40, 119.20],
    [-8.65, 119.10],
    [-8.85, 118.90],
    [-8.90, 118.60],
    [-8.80, 118.30],
    [-8.55, 118.10],
    [-8.35, 118.05],
    [-8.15, 118.10], // tutup polygon
  ];

  /// Bounding box check (cepat)
  static bool isInBounds(double lat, double lng) {
    return lat >= latMin && lat <= latMax && lng >= lngMin && lng <= lngMax;
  }

  /// Ray casting algorithm — point in polygon
  static bool isInsidePolygon(double lat, double lng) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final double yi = polygon[i][0];
      final double xi = polygon[i][1];
      final double yj = polygon[j][0];
      final double xj = polygon[j][1];

      final bool intersect =
          (yi > lat) != (yj > lat) &&
          lng < (xj - xi) * (lat - yi) / (yj - yi) + xi;

      if (intersect) inside = !inside;
      j = i;
    }

    return inside;
  }

  /// Validasi lengkap: bounds + polygon
  static String? validate(double lat, double lng) {
    if (!isInBounds(lat, lng)) {
      return 'Koordinat jauh di luar wilayah Kabupaten Bima\n'
          '(Lat: $latMin ~ $latMax, Lng: $lngMin ~ $lngMax)';
    }
    if (!isInsidePolygon(lat, lng)) {
      return 'Koordinat berada di luar batas wilayah Kabupaten Bima';
    }
    return null; // valid
  }
}

class WisataFormScreen extends StatefulWidget {
  final CrudMode mode;
  final WisataModel? wisata;

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
  String? _coordWarning; // peringatan validasi wilayah

  @override
  void initState() {
    super.initState();
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

  // ─── Validasi koordinat wilayah Bima ────────────────────────────
  void _validateBimaCoords() {
    final lat = double.tryParse(_latitudeController.text.trim());
    final lng = double.tryParse(_longitudeController.text.trim());

    if (lat == null || lng == null) {
      setState(() => _coordWarning = null);
      return;
    }

    setState(() {
      _coordWarning = _BimaRegion.validate(lat, lng);
    });
  }

  // ─── Buka Google Maps preview ────────────────────────────────────
  Future<void> _openGoogleMaps() async {
    final lat = _latitudeController.text.trim();
    final lng = _longitudeController.text.trim();

    if (lat.isEmpty || lng.isEmpty) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka Google Maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final image = await ImagePickerHelper.pickImage(context);
    if (image != null) {
      final error = ImagePickerHelper.validateImage(image);
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
        return;
      }
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Blokir jika ada peringatan wilayah
    if (_coordWarning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_coordWarning!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = context.read<WisataViewModel>();
    bool success = false;

    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());

      if (isEditMode) {
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
              backgroundColor: const Color(0xFF4A7C59),
            ),
          );
          Navigator.pop(context, true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7C59),
        foregroundColor: Colors.white,
        title: Text(
          isEditMode ? 'Edit Wisata' : 'Tambah Wisata',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                  hint: "Contoh: Hu'u, Dompu, Nusa Tenggara Barat",
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // ─── Koordinat Section ───────────────────────────
                _buildKoordinatSection(),
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
                      backgroundColor: const Color(0xFF4A7C59),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isEditMode ? AppStrings.actionSave : AppStrings.actionAdd,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                        CircularProgressIndicator(
                          color: Color(0xFF4A7C59),
                        ),
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

  // ─── Widget: Koordinat Section ─────────────────────────────────
  Widget _buildKoordinatSection() {
    final hasValidCoords =
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty &&
        _coordWarning == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                onChanged: (_) => _validateBimaCoords(),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  hintText: '-8.5348',
                  prefixIcon: const Icon(Icons.my_location),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A7C59),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Latitude harus diisi';
                  }
                  final lat = double.tryParse(value.trim());
                  if (lat == null) return 'Format tidak valid';
                  if (lat < -90 || lat > 90) return 'Range: -90 to 90';
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
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                onChanged: (_) => _validateBimaCoords(),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  hintText: '118.3707',
                  prefixIcon: const Icon(Icons.explore),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A7C59),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Longitude harus diisi';
                  }
                  final lng = double.tryParse(value.trim());
                  if (lng == null) return 'Format tidak valid';
                  if (lng < -180 || lng > 180) return 'Range: -180 to 180';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Info batas wilayah
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4A7C59).withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF4A7C59).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Color(0xFF4A7C59),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Wilayah Kabupaten Bima: Lat -9.0 ~ -8.0 | Lng 118.0 ~ 119.5',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4A7C59),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Peringatan koordinat di luar wilayah
        if (_coordWarning != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _coordWarning!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Tombol preview Google Maps (hanya muncul jika koordinat valid)
        if (hasValidCoords) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openGoogleMaps,
              icon: const Icon(
                Icons.map_outlined,
                size: 16,
                color: Color(0xFF4A7C59),
              ),
              label: const Text(
                'Preview di Google Maps',
                style: TextStyle(
                  color: Color(0xFF4A7C59),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4A7C59)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ],
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
              ),
            ),
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 20),
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
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate,
                              size: 60,
                              color: const Color(0xFF8A998B)),
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