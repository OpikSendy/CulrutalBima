
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryLight,
      AppColors.primaryGreen,
    ],
  );

  static const LinearGradient earthGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.secondaryTan,
      AppColors.secondaryBrown,
    ],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.accentTerracotta,
      AppColors.accentGold,
    ],
  );

  static LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.backgroundGray,
      AppColors.backgroundWhite,
      AppColors.backgroundGray,
    ],
  );
}