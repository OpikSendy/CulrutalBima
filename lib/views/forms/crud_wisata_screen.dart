// lib/views/screens/crud_wisata_screen.dart

import 'package:culturalbima/views/widgets/common/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/wisata_viewmodel.dart';
import '../../data/models/wisata_model.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import 'wisata_form_screen.dart';

class CrudWisataScreen extends StatefulWidget {
  const CrudWisataScreen({super.key});

  @override
  State<CrudWisataScreen> createState() => _CrudWisataScreenState();
}

class _CrudWisataScreenState extends State<CrudWisataScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WisataViewModel>().fetchAllWisata();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Wisata'),
        actions: [
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
          // Action Buttons
          _buildActionButtons(),

          // Search Bar
          _buildSearchBar(),

          // Stats
          _buildStatsBar(),

          // List
          Expanded(
            child: Consumer<WisataViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return Column(
                    children: List.generate(3, (index) => const ShimmerCard()),
                  );
                }

                if (viewModel.hasError) {
                  return ErrorStateWidget(
                    message: viewModel.errorMessage ?? AppStrings.errorLoadData,
                    onRetry: () => viewModel.fetchAllWisata(),
                  );
                }

                if (viewModel.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.wisataEmpty,
                    message: 'Gunakan tombol "Tambah Baru" untuk menambahkan data',
                    icon: Icons.location_off_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.wisataList.length,
                    itemBuilder: (context, index) {
                      final wisata = viewModel.wisataList[index];
                      return _buildWisataCard(wisata);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF8B6F47).withOpacity(0.05),
      child: Row(
        children: [
          // Tambah Baru Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WisataFormScreen(mode: CrudMode.create),
                  ),
                );
                if (result == true && mounted) {
                  context.read<WisataViewModel>().refreshData();
                }
              },
              icon: const Icon(Icons.add_location),
              label: const Text('Tambah Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B6F47),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Update Existing Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _showUpdateModeInfo();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Update Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
                foregroundColor: const Color(0xFF8B6F47),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateModeInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap pada card wisata untuk mengedit atau menghapus'),
        backgroundColor: Color(0xFF8B6F47),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<WisataViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF8B6F47).withOpacity(0.1),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: Color(0xFF8B6F47),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildWisataCard(WisataModel wisata) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showWisataOptions(wisata),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                wisata.imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 150,
                    color: const Color(0xFFF5F5F0),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Color(0xFF8A998B),
                    ),
                  );
                },
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          wisata.nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E2D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.more_vert,
                        color: Color(0xFF8A998B),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Color(0xFF8A998B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          wisata.alamatSingkat,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A998B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 12,
                        color: Color(0xFF8A998B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        wisata.koordinat,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A998B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWisataOptions(WisataModel wisata) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  wisata.nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E2D),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),

              // Edit option
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF8B6F47)),
                title: const Text('Edit Wisata'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WisataFormScreen(
                        mode: CrudMode.update,
                        wisata: wisata,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    context.read<WisataViewModel>().refreshData();
                  }
                },
              ),

              // Delete option
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade400),
                title: Text(
                  'Hapus Wisata',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(wisata);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(WisataModel wisata) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Wisata'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${wisata.nama}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteWisata(wisata);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWisata(WisataModel wisata) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menghapus data...'),
              ],
            ),
          ),
        ),
      ),
    );

    final viewModel = context.read<WisataViewModel>();
    final success = await viewModel.deleteWisata(wisata.id, wisata.fotoPath);

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Wisata berhasil dihapus'
                : viewModel.errorMessage ?? 'Gagal menghapus wisata',
          ),
          backgroundColor: success ? const Color(0xFF8B6F47) : Colors.red,
        ),
      );
    }
  }
}