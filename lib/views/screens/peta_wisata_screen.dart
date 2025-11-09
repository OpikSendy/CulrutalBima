// lib/views/screens/peta_wisata_screen.dart

import 'package:culturalbima/views/maps/peta_wisata_maps_screen.dart';
import 'package:culturalbima/views/widgets/common/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../viewmodels/wisata_viewmodel.dart';
import '../../data/models/wisata_model.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/wisata/wisata_card.dart';

class PetaWisataScreen extends StatefulWidget {
  const PetaWisataScreen({super.key});

  @override
  State<PetaWisataScreen> createState() => _PetaWisataScreenState();
}

class _PetaWisataScreenState extends State<PetaWisataScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch data saat screen pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WisataViewModel>().fetchAllWisata();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Navigasi ke Interactive Maps Screen
  void _openInteractiveMaps() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PetaWisataMapsScreen(),
      ),
    );
  }

  Future<void> _openAllInMaps(List<WisataModel> wisataList) async {
    if (wisataList.isEmpty) return;

    // Jika hanya 1 wisata, buka langsung
    if (wisataList.length == 1) {
      final uri = Uri.parse(wisataList.first.googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Jika lebih dari 1, buka Google Maps dengan multiple markers
    final coordinates = wisataList
        .map((w) => '${w.latitude},${w.longitude}')
        .join('|');

    final mapsUrl = 'https://www.google.com/maps/dir/?api=1&waypoints=$coordinates';
    final uri = Uri.parse(mapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.wisataTitle),
        actions: [
          // Button ke Interactive Maps
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _openInteractiveMaps,
            tooltip: 'Peta Interaktif',
          ),
          Consumer<WisataViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.wisataList.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openAllInMaps(viewModel.wisataList),
                  tooltip: 'Buka di Google Maps',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WisataViewModel>().refreshData();
            },
            tooltip: AppStrings.actionRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Stats Bar with Maps Button
          _buildStatsBar(),

          // Content (List/Loading/Error/Empty)
          Expanded(
            child: Consumer<WisataViewModel>(
              builder: (context, viewModel, child) {
                // Loading State
                if (viewModel.isLoading) {
                  return Column(
                    children: List.generate(
                      3,
                          (index) => const ShimmerCard(),
                    ),
                  );
                }

                // Error State
                if (viewModel.hasError) {
                  return ErrorStateWidget(
                    message: viewModel.errorMessage ?? AppStrings.errorLoadData,
                    onRetry: () => viewModel.fetchAllWisata(),
                  );
                }

                // Empty State
                if (viewModel.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.wisataEmpty,
                    message: AppStrings.wisataEmptyDesc,
                    icon: Icons.location_off_outlined,
                  );
                }

                // Success - Show List
                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.wisataList.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final wisata = viewModel.wisataList[index];
                      return WisataCard(
                        wisata: wisata,
                        onTap: () {
                          _showWisataDetail(context, wisata);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating Action Button untuk Quick Access ke Maps
      floatingActionButton: Consumer<WisataViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.wisataList.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: _openInteractiveMaps,
              backgroundColor: const Color(0xFF8B6F47),
              icon: const Icon(Icons.map),
              label: const Text('Lihat Peta'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<WisataViewModel>().searchWisata(value);
        },
        decoration: InputDecoration(
          hintText: AppStrings.wisataSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<WisataViewModel>().searchWisata('');
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF8A998B).withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF8A998B).withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF8B6F47),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: const Color(0xFFFAF8F3),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<WisataViewModel>(
      builder: (context, viewModel, child) {
        return InkWell(
          onTap: viewModel.wisataList.isNotEmpty ? _openInteractiveMaps : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF8B6F47).withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: const Color(0xFF8B6F47),
                ),
                const SizedBox(width: 8),
                Text(
                  'Total ${viewModel.wisataList.length} Destinasi Wisata',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8B6F47),
                  ),
                ),
                const Spacer(),
                if (viewModel.wisataList.isNotEmpty)
                  Row(
                    children: const [
                      Text(
                        'Lihat Peta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B6F47),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Color(0xFF8B6F47),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWisataDetail(BuildContext context, WisataModel wisata) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A998B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            wisata.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: const Color(0xFFF5F5F0),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Color(0xFF8A998B),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nama
                        Text(
                          wisata.nama,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E2D),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Alamat
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Color(0xFF8B6F47),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                wisata.alamat ?? wisata.alamatSingkat,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5A6C5B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Koordinat
                        Row(
                          children: [
                            const Icon(
                              Icons.my_location,
                              size: 16,
                              color: Color(0xFF8A998B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              wisata.koordinat,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A998B),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),

                        // Deskripsi
                        if (wisata.deskripsi != null) ...[
                          const Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E2D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            wisata.deskripsi!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5A6C5B),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Action Buttons
                        Row(
                          children: [
                            // Google Maps Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.parse(wisata.googleMapsUrl);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B6F47),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Interactive Map Button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _openInteractiveMaps();
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('Peta Lokal'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(
                                    color: Color(0xFF8B6F47),
                                    width: 2,
                                  ),
                                  foregroundColor: const Color(0xFF8B6F47),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}