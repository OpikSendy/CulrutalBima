// lib/core/utils/image_picker_helper.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Show dialog untuk pilih sumber gambar (Camera/Gallery)
  static Future<File?> pickImage(BuildContext context) async {
    return showModalBottomSheet<File?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'Pilih Sumber Gambar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E2D),
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Camera option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7C59).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF4A7C59),
                    ),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil foto baru'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await _pickFromCamera();
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  },
                ),

                // Gallery option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7C59).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: Color(0xFF4A7C59),
                    ),
                  ),
                  title: const Text('Galeri'),
                  subtitle: const Text('Pilih dari galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await _pickFromGallery();
                    if (context.mounted) {
                      Navigator.pop(context, file);
                    }
                  },
                ),

                const SizedBox(height: 8),

                // Cancel
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8A998B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF8A998B),
                    ),
                  ),
                  title: const Text('Batal'),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pick image dari camera
  static Future<File?> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Pick image dari gallery
  static Future<File?> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  /// Validate image file
  static String? validateImage(File? file) {
    if (file == null) return null;

    // Check file size (max 5MB)
    final fileSizeInBytes = file.lengthSync();
    final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

    if (fileSizeInMB > 5) {
      return 'Ukuran file terlalu besar (max 5MB)';
    }

    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      return 'Format file tidak didukung (gunakan JPG, PNG, atau WebP)';
    }

    return null;
  }
}