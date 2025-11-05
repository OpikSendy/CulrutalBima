// lib/views/screens/budaya_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/budaya_model.dart';
import '../../viewmodels/budaya_viewmodel.dart';
import '../../core/constants/app_strings.dart';
import 'package:culturalbima/views/forms/budaya_form_screen.dart';

class BudayaDetailScreen extends StatelessWidget {
  final BudayaModel budaya;

  const BudayaDetailScreen({
    super.key,
    required this.budaya,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar dengan Image
          _buildSliverAppBar(context),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Budaya
                  Text(
                    budaya.nama,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: const Color(0xFF2C3E2D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kategori & Daerah Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.category_outlined,
                        label: budaya.kategori,
                        color: const Color(0xFF4A7C59),
                      ),
                      if (budaya.asalDaerah != null)
                        _buildInfoChip(
                          icon: Icons.location_on,
                          label: budaya.asalDaerah!,
                          color: const Color(0xFF8B6F47),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Deskripsi Section
                  Text(
                    AppStrings.detailDeskripsi,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF2C3E2D),
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (budaya.deskripsi != null)
                    Text(
                      budaya.deskripsi!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF5A6C5B),
                        height: 1.8,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.justify,
                    )
                  else
                    Text(
                      'Deskripsi tidak tersedia',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8A998B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Info Card
                  _buildInfoCard(context),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF4A7C59),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              budaya.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF5F5F0),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Color(0xFF8A998B),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6B9D7A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B9D7A).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF4A7C59),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Tambahan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2C3E2D),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.category,
            label: 'Kategori',
            value: budaya.kategori,
          ),
          if (budaya.asalDaerah != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.location_city,
              label: 'Asal Daerah',
              value: budaya.asalDaerah!,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Ditambahkan',
            value: _formatDate(budaya.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF4A7C59),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A998B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E2D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}