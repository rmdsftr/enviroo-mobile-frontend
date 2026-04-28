class KategoriSampahModel {
  final int kategoriId;
  final String kategori;

  KategoriSampahModel({
    required this.kategoriId,
    required this.kategori,
  });

  factory KategoriSampahModel.fromJson(Map<String, dynamic> json) {
    return KategoriSampahModel(
      kategoriId: json['KategoriID'] ?? 0,
      kategori: json['Kategori'] ?? '',
    );
  }
}

class SchemaHargaModel {
  final String levelUser;
  final double poinHarga;

  SchemaHargaModel({
    required this.levelUser,
    required this.poinHarga,
  });

  factory SchemaHargaModel.fromJson(Map<String, dynamic> json) {
    return SchemaHargaModel(
      levelUser: json['level_user'] ?? '',
      poinHarga: (json['poin_harga'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class KatalogSampahModel {
  final String sampahId;
  final String namaSampah;
  final String photoUrl;
  final String satuan;
  final String bankId;
  final int kategoriId;
  final KategoriSampahModel? kategori;
  final List<SchemaHargaModel> harga;
  final double fallbackPoin; // Added for backwards compatibility
  final double stok;        // Stok sampah milik bank ini

  KatalogSampahModel({
    required this.sampahId,
    required this.namaSampah,
    required this.photoUrl,
    required this.satuan,
    required this.bankId,
    required this.kategoriId,
    this.kategori,
    required this.harga,
    this.fallbackPoin = 0.0,
    this.stok = 0.0,
  });

  factory KatalogSampahModel.fromJson(Map<String, dynamic> json) {
    var hargaList = json['harga'] as List? ?? [];
    return KatalogSampahModel(
      sampahId: json['sampah_id'] ?? json['SampahID'] ?? '',
      namaSampah: json['nama_sampah'] ?? json['NamaSampah'] ?? '',
      photoUrl: json['photo_url'] ?? json['PhotoURL'] ?? '',
      satuan: json['satuan'] ?? json['Satuan'] ?? '',
      bankId: json['bank_id'] ?? json['BankID'] ?? '',
      kategoriId: json['kategori_id'] ?? json['KategoriID'] ?? 0,
      kategori: json['kategori'] != null ? KategoriSampahModel.fromJson(json['kategori']) : (json['Kategori'] != null ? KategoriSampahModel.fromJson(json['Kategori']) : null),
      harga: hargaList.map((e) => SchemaHargaModel.fromJson(e)).toList(),
      fallbackPoin: (json['poin_satuan'] as num?)?.toDouble() ?? (json['PoinSatuan'] as num?)?.toDouble() ?? 0.0,
      stok: (json['stok'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double getPoinForLevel(String level) {
    for (var h in harga) {
      if (h.levelUser.toLowerCase() == level.toLowerCase()) {
        return h.poinHarga;
      }
    }
    // Fallback if not found (or for older endpoints that might still return PoinSatuan)
    return fallbackPoin;
  }

  double get poinNasabah => getPoinForLevel('nasabah');
  double get poinBsu => getPoinForLevel('bsu');
  double get poinEksternal => getPoinForLevel('eksternal');

  bool get hasAnyPrice => harga.isNotEmpty || fallbackPoin > 0;
}

class KatalogSembakoModel {
  final String sembakoId;
  final String bankId;
  final String namaSembako;
  final String photoUrl;
  final int poin;

  KatalogSembakoModel({
    required this.sembakoId,
    required this.bankId,
    required this.namaSembako,
    required this.photoUrl,
    required this.poin,
  });

  factory KatalogSembakoModel.fromJson(Map<String, dynamic> json) {
    return KatalogSembakoModel(
      sembakoId: json['SembakoID'] ?? '',
      bankId: json['BankID'] ?? '',
      namaSembako: json['NamaSembako'] ?? '',
      photoUrl: json['PhotoURL'] ?? '',
      poin: json['Poin'] ?? 0,
    );
  }
}
