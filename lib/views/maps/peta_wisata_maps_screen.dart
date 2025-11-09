// lib/views/screens/peta_wisata_maps_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../viewmodels/wisata_viewmodel.dart';
import '../../data/models/wisata_model.dart';
import '../../core/config/google_maps_config.dart';
import '../widgets/common/loading_widget.dart';

class PetaWisataMapsScreen extends StatefulWidget {
  const PetaWisataMapsScreen({super.key});

  @override
  State<PetaWisataMapsScreen> createState() => _PetaWisataMapsScreenState();
}

class _PetaWisataMapsScreenState extends State<PetaWisataMapsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  Set<Marker> _markers = {};
  WisataModel? _selectedWisata;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WisataViewModel>().fetchAllWisata();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _createMarkers(List<WisataModel> wisataList) {
    _markers.clear();

    // Add user location marker if available - using config
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            GoogleMapsConfig.userLocationHue,
          ),
          infoWindow: const InfoWindow(
            title: 'Lokasi Anda',
            snippet: 'Posisi saat ini',
          ),
        ),
      );
    }

    // Add wisata markers - using config
    for (var wisata in wisataList) {
      _markers.add(
        Marker(
          markerId: MarkerId(wisata.id),
          position: LatLng(wisata.latitude, wisata.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _selectedWisata?.id == wisata.id
                ? GoogleMapsConfig.selectedMarkerHue
                : GoogleMapsConfig.wisataMarkerHue,
          ),
          infoWindow: InfoWindow(
            title: wisata.nama,
            snippet: _getTruncatedDescription(wisata.deskripsi),
            onTap: () {
              _showWisataDetails(wisata);
            },
          ),
          onTap: () {
            setState(() {
              _selectedWisata = wisata;
            });
            _showWisataDetails(wisata);
          },
        ),
      );
    }
  }

  String _getTruncatedDescription(String? description) {
    if (description == null || description.isEmpty) {
      return 'Tap untuk detail';
    }
    if (description.length > 50) {
      return '${description.substring(0, 50)}...';
    }
    return description;
  }

  void _showWisataDetails(WisataModel wisata) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A998B).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      wisata.imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 180,
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
                  const SizedBox(height: 16),

                  // Nama
                  Text(
                    wisata.nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E2D),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Distance from user
                  if (_currentPosition != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF87CEEB).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation,
                            size: 16,
                            color: Color(0xFF87CEEB),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _calculateDistance(wisata),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF87CEEB),
                            ),
                          ),
                        ],
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

                  if (wisata.deskripsi != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E2D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wisata.deskripsi!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF5A6C5B),
                        height: 1.6,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      // Navigate button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToWisata(wisata),
                          icon: const Icon(Icons.directions),
                          label: const Text('Navigasi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B6F47),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Focus on map button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _focusOnWisata(wisata);
                          },
                          icon: const Icon(Icons.center_focus_strong),
                          label: const Text('Fokus'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
          );
        },
      ),
    );
  }

  String _calculateDistance(WisataModel wisata) {
    if (_currentPosition == null) return 'Jarak tidak tersedia';

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      wisata.latitude,
      wisata.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m dari Anda';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km dari Anda';
    }
  }

  Future<void> _navigateToWisata(WisataModel wisata) async {
    // Use Google Maps navigation
    String origin = _currentPosition != null
        ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
        : '';

    String destination = '${wisata.latitude},${wisata.longitude}';

    String url = origin.isNotEmpty
        ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving'
        : 'https://www.google.com/maps/search/?api=1&query=$destination';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _focusOnWisata(WisataModel wisata) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(wisata.latitude, wisata.longitude),
          zoom: GoogleMapsConfig.detailZoom,
          tilt: 45,
        ),
      ),
    );
  }

  void _goToMyLocation() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: GoogleMapsConfig.myLocationZoom,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi Anda tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showAllWisata() {
    final viewModel = context.read<WisataViewModel>();
    if (viewModel.wisataList.isEmpty) return;

    // Calculate bounds to show all markers
    double minLat = viewModel.wisataList.first.latitude;
    double maxLat = viewModel.wisataList.first.latitude;
    double minLng = viewModel.wisataList.first.longitude;
    double maxLng = viewModel.wisataList.first.longitude;

    for (var wisata in viewModel.wisataList) {
      if (wisata.latitude < minLat) minLat = wisata.latitude;
      if (wisata.latitude > maxLat) maxLat = wisata.latitude;
      if (wisata.longitude < minLng) minLng = wisata.longitude;
      if (wisata.longitude > maxLng) maxLng = wisata.longitude;
    }

    // Include user location if available
    if (_currentPosition != null) {
      if (_currentPosition!.latitude < minLat) {
        minLat = _currentPosition!.latitude;
      }
      if (_currentPosition!.latitude > maxLat) {
        maxLat = _currentPosition!.latitude;
      }
      if (_currentPosition!.longitude < minLng) {
        minLng = _currentPosition!.longitude;
      }
      if (_currentPosition!.longitude > maxLng) {
        maxLng = _currentPosition!.longitude;
      }
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        GoogleMapsConfig.mapBoundsPadding,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Wisata Bima'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<WisataViewModel>().refreshData();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<WisataViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.wisataList.isEmpty) {
            return const Center(
              child: LoadingWidget(message: 'Memuat peta wisata...'),
            );
          }

          // Create markers from wisata list
          if (viewModel.wisataList.isNotEmpty) {
            _createMarkers(viewModel.wisataList);
          }

          return Stack(
            children: [
              // Google Map - using config
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  )
                      : GoogleMapsConfig.bimaCenter,
                  zoom: GoogleMapsConfig.defaultZoom,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (viewModel.wisataList.isNotEmpty) {
                    // Show all wisata on map load
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _showAllWisata();
                    });
                  }
                },
              ),

              // Top Stats Card
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: Color(0xFF8B6F47),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${viewModel.wisataList.length} Destinasi Wisata',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E2D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Control Buttons (Bottom Right)
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // My Location Button
                    FloatingActionButton(
                      heroTag: 'my_location',
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8B6F47),
                      onPressed: _goToMyLocation,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 12),

                    // Show All Button
                    FloatingActionButton(
                      heroTag: 'show_all',
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8B6F47),
                      onPressed: _showAllWisata,
                      child: const Icon(Icons.zoom_out_map),
                    ),
                  ],
                ),
              ),

              // Loading Location Indicator
              if (_isLoadingLocation)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Mencari lokasi Anda...',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}