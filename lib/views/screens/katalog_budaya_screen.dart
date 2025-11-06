// lib/views/screens/katalog_budaya_screen.dart

import 'package:culturalbima/views/widgets/common/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/budaya_viewmodel.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/common/loading_widget.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/budaya/budaya_card.dart';
import 'budaya_detail_screen.dart';

class KatalogBudayaScreen extends StatefulWidget {
  const KatalogBudayaScreen({super.key});

  @override
  State<KatalogBudayaScreen> createState() => _KatalogBudayaScreenState();
}

class _KatalogBudayaScreenState extends State<KatalogBudayaScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch data saat screen pertama kali dibuka
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
        title: const Text(AppStrings.budayaTitle),
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
          // Search Bar
          _buildSearchBar(),

          // Category Filter Chips
          _buildCategoryFilter(),

          // Content (List/Loading/Error/Empty)
          Expanded(
            child: Consumer<BudayaViewModel>(
              builder: (context, viewModel, child) {
                // Loading State
                if (viewModel.isLoading) {
                  return Column(
                    children: List.generate(
                      5,
                          (index) => const ShimmerCard(),
                    ),
                  );
                }

                // Error State
                if (viewModel.hasError) {
                  return ErrorStateWidget(
                    message: viewModel.errorMessage ?? AppStrings.errorLoadData,
                    onRetry: () => viewModel.fetchAllBudaya(),
                  );
                }

                // Empty State
                if (viewModel.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.budayaEmpty,
                    message: AppStrings.budayaEmptyDesc,
                    icon: Icons.museum_outlined,
                  );
                }

                // Success - Show List
                return RefreshIndicator(
                  onRefresh: () => viewModel.refreshData(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: viewModel.budayaList.length,
                    itemBuilder: (context, index) {
                      final budaya = viewModel.budayaList[index];
                      return BudayaCard(
                        budaya: budaya,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BudayaDetailScreen(
                                budaya: budaya,
                              ),
                            ),
                          );
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: Color(0xFF4A7C59),
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
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF4A7C59),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF4A7C59)
                        : const Color(0xFF6B9D7A).withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}