// lib/views/screens/home_screen.dart

import 'package:culturalbima/views/admin/admin_panel_screen.dart';
import 'package:culturalbima/views/screens/katalog_budaya_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import 'peta_wisata_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(context),
                const SizedBox(height: 32),

                // Menu Cards
                _buildMenuCard(
                  context: context,
                  title: AppStrings.budayaTitle,
                  subtitle: AppStrings.budayaSubtitle,
                  icon: Icons.museum_outlined,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6B9D7A), Color(0xFF4A7C59)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KatalogBudayaScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildMenuCard(
                  context: context,
                  title: AppStrings.wisataTitle,
                  subtitle: AppStrings.wisataSubtitle,
                  icon: Icons.location_on_outlined,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFC4A57B), Color(0xFF8B6F47)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PetaWisataScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                _buildMenuCard(
                  context: context,
                  title: AppStrings.adminPanelTitle,
                  subtitle: AppStrings.adminPanelSubtitle,
                  icon: Icons.admin_panel_settings_outlined,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9E7CE3), Color(0xFF6B49C8)],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminPanelScreen(),
                        )
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Info Section
                _buildInfoSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.homeWelcome,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF2C3E2D),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.homeSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF5A6C5B),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B9D7A).withOpacity(0.2),
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
                'Tentang Aplikasi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2C3E2D),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cultural Bima adalah aplikasi digital untuk melestarikan dan mengenalkan kekayaan budaya serta destinasi wisata Kabupaten Bima, Nusa Tenggara Barat.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5A6C5B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}