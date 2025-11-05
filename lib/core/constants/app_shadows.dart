
import 'package:flutter/material.dart';

class AppShadows {
  static const BoxShadow soft = BoxShadow(
    color: Color(0x0F000000), // 6% opacity
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x14000000), // 8% opacity
    blurRadius: 16,
    offset: Offset(0, 6),
  );

  static const BoxShadow strong = BoxShadow(
    color: Color(0x1F000000), // 12% opacity
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  // Card Shadow (natural elevation)
  static List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
    const BoxShadow(
      color: Color(0x05000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];
}