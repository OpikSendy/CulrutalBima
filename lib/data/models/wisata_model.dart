// lib/data/models/wisata_model.dart

class WisataModel {
  final String id;
  final String nama;
  final String? deskripsi;
  final double latitude;
  final double longitude;
  final String? alamat;
  final String? fotoPath;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  WisataModel({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.latitude,
    required this.longitude,
    this.alamat,
    this.fotoPath,
    this.fotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (dari Supabase)
  factory WisataModel.fromJson(Map<String, dynamic> json) {
    return WisataModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      deskripsi: json['deskripsi'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      alamat: json['alamat'] as String?,
      fotoPath: json['foto_path'] as String?,
      fotoUrl: json['foto_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // To JSON (untuk insert/update ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'deskripsi': deskripsi,
      'latitude': latitude,
      'longitude': longitude,
      'alamat': alamat,
      'foto_path': fotoPath,
    };
  }

  // To JSON with ID (untuk update)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'latitude': latitude,
      'longitude': longitude,
      'alamat': alamat,
      'foto_path': fotoPath,
    };
  }

  // CopyWith untuk immutability
  WisataModel copyWith({
    String? id,
    String? nama,
    String? deskripsi,
    double? latitude,
    double? longitude,
    String? alamat,
    String? fotoPath,
    String? fotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WisataModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      deskripsi: deskripsi ?? this.deskripsi,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alamat: alamat ?? this.alamat,
      fotoPath: fotoPath ?? this.fotoPath,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter untuk placeholder image
  String get imageUrl {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return fotoUrl!;
    }
    return 'https://via.placeholder.com/400x300.png?text=No+Image';
  }

  // Getter untuk koordinat string (untuk display)
  String get koordinat {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  // Getter untuk Google Maps URL
  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  // Getter untuk alamat singkat (hanya kabupaten/kota)
  String get alamatSingkat {
    if (alamat == null || alamat!.isEmpty) return 'Bima, NTB';

    // Extract kabupaten/kota dari alamat
    final parts = alamat!.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim() + ', ' + parts.last.trim();
    }
    return alamat!;
  }

  @override
  String toString() {
    return 'WisataModel(id: $id, nama: $nama, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WisataModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}