// lib/data/models/budaya_model.dart

class BudayaModel {
  final String id;
  final String nama;
  final String kategori;
  final String? deskripsi;
  final String? asalDaerah;
  final String? fotoPath;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudayaModel({
    required this.id,
    required this.nama,
    required this.kategori,
    this.deskripsi,
    this.asalDaerah,
    this.fotoPath,
    this.fotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // From JSON (dari Supabase)
  factory BudayaModel.fromJson(Map<String, dynamic> json) {
    return BudayaModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      kategori: json['kategori'] as String,
      deskripsi: json['deskripsi'] as String?,
      asalDaerah: json['asal_daerah'] as String?,
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
      'kategori': kategori,
      'deskripsi': deskripsi,
      'asal_daerah': asalDaerah,
      'foto_path': fotoPath,
    };
  }

  // To JSON with ID (untuk update)
  Map<String, dynamic> toJsonWithId() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'asal_daerah': asalDaerah,
      'foto_path': fotoPath,
    };
  }

  // CopyWith untuk immutability
  BudayaModel copyWith({
    String? id,
    String? nama,
    String? kategori,
    String? deskripsi,
    String? asalDaerah,
    String? fotoPath,
    String? fotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudayaModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      deskripsi: deskripsi ?? this.deskripsi,
      asalDaerah: asalDaerah ?? this.asalDaerah,
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

  // Getter untuk kategori icon
  String get kategoriIcon {
    switch (kategori.toLowerCase()) {
      case 'tarian':
        return '💃';
      case 'pakaian adat':
        return '👘';
      case 'rumah adat':
        return '🏠';
      case 'kuliner':
        return '🍜';
      case 'musik':
        return '🎵';
      case 'kerajinan':
        return '🎨';
      default:
        return '🏛️';
    }
  }

  @override
  String toString() {
    return 'BudayaModel(id: $id, nama: $nama, kategori: $kategori)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BudayaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum untuk kategori budaya (untuk filter & validation)
enum KategoriBudaya {
  tarian('Tarian'),
  pakaianAdat('Pakaian Adat'),
  rumahAdat('Rumah Adat'),
  kuliner('Kuliner'),
  musik('Musik'),
  kerajinan('Kerajinan'),
  semua('Semua');

  final String label;
  const KategoriBudaya(this.label);

  static KategoriBudaya fromString(String value) {
    return KategoriBudaya.values.firstWhere(
          (e) => e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => KategoriBudaya.semua,
    );
  }
}