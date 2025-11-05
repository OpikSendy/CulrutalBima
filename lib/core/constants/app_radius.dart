
import 'package:flutter/material.dart';

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 999.0; // Fully rounded

  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(12.0),
  );

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(12.0),
  );

  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(20.0),
  );
}