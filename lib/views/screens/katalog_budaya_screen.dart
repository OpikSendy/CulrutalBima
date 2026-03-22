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

class _KatalogBudayaScreenState extends State<KatalogBudayaScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = false;

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
      backgroundColor: const Color(0xFFFAF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7C59),
        foregroundColor: Colors.white,
        title: const Text(
          AppStrings.budayaTitle,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          // Toggle List/Grid
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                key: ValueKey(_isGridView),
                color: Colors.white,
              ),
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<BudayaViewModel>().refreshData();
            },
            tooltip: AppStrings.actionRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: Consumer<BudayaViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        5,
                        (index) => const ShimmerCard(),
                      ),
                    ),
                  );
                }

                if (viewModel.hasError) {
                  return ErrorStateWidget(
                    message:
                        viewModel.errorMessage ?? AppStrings.errorLoadData,
                    onRetry: () => viewModel.fetchAllBudaya(),
                  );
                }

                if (viewModel.isEmpty) {
                  return EmptyStateWidget(
                    title: AppStrings.budayaEmpty,
                    message: AppStrings.budayaEmptyDesc,
                    icon: Icons.museum_outlined,
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF4A7C59),
                  onRefresh: () => viewModel.refreshData(),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _isGridView
                        ? _buildGridView(viewModel)
                        : _buildListView(viewModel),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BudayaViewModel viewModel) {
    return ListView.builder(
      key: const ValueKey('list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      itemCount: viewModel.budayaList.length,
      itemBuilder: (context, index) {
        final budaya = viewModel.budayaList[index];
        return _AnimatedListItem(
          index: index,
          child: BudayaCard(
            budaya: budaya,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudayaDetailScreen(budaya: budaya),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGridView(BudayaViewModel viewModel) {
    return GridView.builder(
      key: const ValueKey('grid'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: viewModel.budayaList.length,
      itemBuilder: (context, index) {
        final budaya = viewModel.budayaList[index];
        return _AnimatedListItem(
          index: index,
          child: _BudayaGridCard(
            budaya: budaya,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudayaDetailScreen(budaya: budaya),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<BudayaViewModel>().searchBudaya(value);
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: AppStrings.budayaSearchHint,
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF4A7C59)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF8A998B)),
                  onPressed: () {
                    _searchController.clear();
                    context.read<BudayaViewModel>().searchBudaya('');
                    setState(() {});
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
          color: Colors.white,
          child: SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final kategori = categories[index];
                final isSelected = viewModel.selectedKategori == kategori;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      kategori,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      viewModel.filterByKategori(kategori);
                    },
                    backgroundColor:
                        const Color(0xFF6B9D7A).withOpacity(0.1),
                    selectedColor: const Color(0xFF4A7C59),
                    checkmarkColor: Colors.white,
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
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4A7C59)
                          : const Color(0xFF6B9D7A).withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Animated List Item (Staggered Fade-In) ───────────────────────────────────

class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Staggered delay berdasarkan index
    Future.delayed(
      Duration(milliseconds: 60 * widget.index),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

// ─── Grid Card ────────────────────────────────────────────────────────────────

class _BudayaGridCard extends StatelessWidget {
  final dynamic budaya;
  final VoidCallback onTap;

  const _BudayaGridCard({
    required this.budaya,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image dominan
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      budaya.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF5F5F0),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Color(0xFF8A998B),
                            size: 36,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFFF0EDE6),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF4A7C59),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay bawah
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Chip kategori di atas gambar
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          budaya.kategori,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info bawah
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budaya.nama,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E2D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (budaya.asalDaerah != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Color(0xFF8B6F47),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              budaya.asalDaerah!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B6F47),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
      ),
    );
  }
}