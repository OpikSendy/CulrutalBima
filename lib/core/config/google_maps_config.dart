// lib/core/config/google_maps_config.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsConfig {

  // Default map settings
  static const double defaultZoom = 11.0;
  static const double detailZoom = 15.0;
  static const double myLocationZoom = 14.0;
  static const double listViewZoom = 13.0;

  // Bima region center
  static const double bimaLatitude = -8.4606;
  static const double bimaLongitude = 118.7250;

  static const LatLng bimaCenter = LatLng(bimaLatitude, bimaLongitude);

  // Map padding
  static const double mapBoundsPadding = 50.0;
  static const double markerPadding = 80.0;

  // Map styles
  static const CameraPosition initialPosition = CameraPosition(
    target: bimaCenter,
    zoom: defaultZoom,
  );

  // Marker colors
  static const double userLocationHue = BitmapDescriptor.hueAzure;
  static const double wisataMarkerHue = BitmapDescriptor.hueRed;
  static const double selectedMarkerHue = BitmapDescriptor.hueOrange;
}