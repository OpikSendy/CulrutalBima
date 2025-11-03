// lib/views/widgets/wisata/wisata_card.dart

import 'package:flutter/material.dart';
import '../../../data/models/wisata_model.dart';
import 'package:url_launcher/url_launcher.dart';

class WisataCard extends StatelessWidget {
  final WisataModel wisata;
  final VoidCallback onTap;

  const WisataCard({
    super.key,
    required this.wisata,
    required this.onTap,
  });

  Future<void> _openMaps() async {
    final uri = Uri.parse(wisata.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto wisata
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Image.network(
                    wisata.imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: const Color(0xFFF5F5F0),
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Color(0xFF8A998B),
                          size: 60,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 180,
                        color: const Color(0xFFF5F5F0),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Location button overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _openMaps,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.map,
                              size: 16,
                              color: Color(0xFF4A7C59),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Buka Maps',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A7C59),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info wisata
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama wisata
                  Text(
                    wisata.nama,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E2D),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Alamat
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Color(0xFF8A998B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          wisata.alamatSingkat,
                          style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF8A998B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Koordinat
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 14,
                        color: Color(0xFF8A998B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        wisata.koordinat,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8A998B),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),

                  // Deskripsi singkat
                  if (wisata.deskripsi != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      wisata.deskripsi!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5A6C5B),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}