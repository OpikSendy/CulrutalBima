// lib/views/screens/crud_budaya_screen.dart

import 'package:culturalbima/views/widgets/common/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/budaya_viewmodel.dart';
import '../../data/models/budaya_model.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import 'budaya_form_screen.dart';

class CrudBudayaScreen extends StatefulWidget {
  const CrudBudayaScreen({super.key});

  @override
  State<CrudBudayaScreen> createState() => _CrudBudayaScreenState();
}

class _CrudBudayaScreenState extends State<CrudBudayaScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudayaViewModel>().fetchAllBudaya();
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
        title: const Text('Kelola Budaya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BudayaViewModel>().refreshData();
            },
            tooltip: AppStrings.actionRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Action Buttons (Create / Update)
          _buildActionButtons(),

          // Search Bar
          _buildSearchBar(),

          // Category Filter
          _buildCategoryFilter(),

          // List
          Expanded(
            child: Consumer<BudayaViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return Column(
                    children: List.generate(5, (index) => const ShimmerCard()),
                  );
                }

                if (viewModel.hasError) {
                  return ErrorStateWidget(
                    message: viewModel.errorMessage ?? AppStrings.errorLoadData,
                    onRetry: () => viewModel.fetchAllBudaya(),
                  );
                }

                if (viewModel.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.budayaEmpty,
                    message: 'Gunakan tombol "Tambah Baru" untuk menambahkan data',
                    icon: Icons.museum_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.budayaList.length,
                    itemBuilder: (context, index) {
                      final budaya = viewModel.budayaList[index];
                      return _buildBudayaCard(budaya);
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
      color: const Color(0xFF4A7C59).withOpacity(0.05),
      child: Row(
        children: [
          // Tambah Baru Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BudayaFormScreen(mode: CrudMode.create),
                  ),
                );
                if (result == true && mounted) {
                  context.read<BudayaViewModel>().refreshData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A7C59),
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
                side: const BorderSide(color: Color(0xFF4A7C59), width: 2),
                foregroundColor: const Color(0xFF4A7C59),
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
        content: Text('Tap pada card budaya untuk mengedit atau menghapus'),
        backgroundColor: Color(0xFF4A7C59),
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
          context.read<BudayaViewModel>().searchBudaya(value);
        },
        decoration: InputDecoration(
          hintText: AppStrings.budayaSearchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<BudayaViewModel>().searchBudaya('');
            },
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<BudayaViewModel>(
      builder: (context, viewModel, child) {
        final categories = viewModel.getKategoriList();

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final kategori = categories[index];
              final isSelected = viewModel.selectedKategori == kategori;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(kategori),
                  selected: isSelected,
                  onSelected: (selected) {
                    viewModel.filterByKategori(kategori);
                  },
                  backgroundColor: const Color(0xFF6B9D7A).withOpacity(0.1),
                  selectedColor: const Color(0xFF4A7C59),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4A7C59),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBudayaCard(BudayaModel budaya) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showBudayaOptions(budaya),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  budaya.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFFF5F5F0),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFF8A998B),
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budaya.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E2D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B9D7A).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        budaya.kategori,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A7C59),
                        ),
                      ),
                    ),
                    if (budaya.asalDaerah != null) ...[
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
                              budaya.asalDaerah!,
                              style: const TextStyle(
                                color: Color(0xFF8A998B),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action icon
              const Icon(
                Icons.more_vert,
                color: Color(0xFF8A998B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudayaOptions(BudayaModel budaya) {
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
                  budaya.nama,
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
                leading: const Icon(Icons.edit, color: Color(0xFF4A7C59)),
                title: const Text('Edit Budaya'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudayaFormScreen(
                        mode: CrudMode.update,
                        budaya: budaya,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    context.read<BudayaViewModel>().refreshData();
                  }
                },
              ),

              // Delete option
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade400),
                title: Text(
                  'Hapus Budaya',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(budaya);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BudayaModel budaya) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Budaya'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${budaya.nama}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudaya(budaya);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudaya(BudayaModel budaya) async {
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

    final viewModel = context.read<BudayaViewModel>();
    final success = await viewModel.deleteBudaya(budaya.id, budaya.fotoPath);

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Budaya berhasil dihapus'
                : viewModel.errorMessage ?? 'Gagal menghapus budaya',
          ),
          backgroundColor: success ? const Color(0xFF4A7C59) : Colors.red,
        ),
      );
    }
  }
}