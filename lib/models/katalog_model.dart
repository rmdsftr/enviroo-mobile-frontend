class KategoriSampahModel {
  final int kategoriId;
  final String kategori;

  KategoriSampahModel({required this.kategoriId, required this.kategori});

  factory KategoriSampahModel.fromJson(Map<String, dynamic> json) {
    return KategoriSampahModel(
      kategoriId: json['KategoriID'] ?? json['kategori_id'] ?? 0,
      kategori: (json['Kategori'] ?? json['kategori'] ?? '').toString(),
    );
  }
}

class RewardModel {
  final int rewardId;
  final String namaReward;
  final String satuan;
  final String? deskripsi;

  RewardModel({
    required this.rewardId,
    required this.namaReward,
    required this.satuan,
    this.deskripsi,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      rewardId: json['RewardID'] ?? json['reward_id'] ?? 0,
      namaReward: (json['NamaReward'] ?? json['nama_reward'] ?? '').toString(),
      satuan: (json['Satuan'] ?? json['satuan'] ?? '').toString(),
      deskripsi: (json['Deskripsi'] ?? json['deskripsi'])?.toString(),
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
  final int rewardId;
  final String syaratPemilahan;
  final double stok;
  final KategoriSampahModel? kategori;
  final RewardModel? reward;

  KatalogSampahModel({
    required this.sampahId,
    required this.namaSampah,
    required this.photoUrl,
    required this.satuan,
    required this.bankId,
    required this.kategoriId,
    required this.rewardId,
    required this.syaratPemilahan,
    required this.stok,
    this.kategori,
    this.reward,
  });

  factory KatalogSampahModel.fromJson(Map<String, dynamic> json) {
    return KatalogSampahModel(
      sampahId: json['sampah_id'] ?? '',
      namaSampah: json['nama_sampah'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      satuan: json['satuan'] ?? '',
      bankId: json['bank_id'] ?? '',
      kategoriId: json['kategori_id'] ?? 0,
      rewardId: json['reward_id'] ?? 0,
      syaratPemilahan: json['syarat_pemilahan'] ?? '',
      stok: (json['stok'] as num?)?.toDouble() ?? 0.0,
      kategori: json['kategori'] != null
          ? KategoriSampahModel.fromJson(json['kategori'] as Map<String, dynamic>)
          : null,
      reward: json['reward'] != null
          ? RewardModel.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
    );
  }

  // Backward-compat — new list endpoint does not return prices; these return 0.
  // Screens needing real prices (setoran, penjualan) must use the detail endpoint.
  double get poinNasabah => 0.0;
  double get poinBsu => 0.0;
  double get poinEksternal => 0.0;
  bool get hasAnyPrice => false;
}

class HargaPerLevelModel {
  final int schemaId;
  final String levelUser;
  final double harga;
  final String satuanReward;

  HargaPerLevelModel({
    required this.schemaId,
    required this.levelUser,
    required this.harga,
    required this.satuanReward,
  });

  factory HargaPerLevelModel.fromJson(Map<String, dynamic> json) {
    return HargaPerLevelModel(
      schemaId: json['schema_id'] ?? 0,
      levelUser: json['level_user'] ?? '',
      harga: (json['harga'] as num?)?.toDouble() ?? 0.0,
      satuanReward: json['satuan_reward'] ?? '',
    );
  }
}

class HistoryHargaModel {
  final int historyId;
  final int schemaId;
  final String levelUser;
  final double hargaLama;
  final double hargaBaru;
  final DateTime changedAt;
  final String changedByNama;

  HistoryHargaModel({
    required this.historyId,
    required this.schemaId,
    required this.levelUser,
    required this.hargaLama,
    required this.hargaBaru,
    required this.changedAt,
    required this.changedByNama,
  });

  factory HistoryHargaModel.fromJson(Map<String, dynamic> json) {
    return HistoryHargaModel(
      historyId: json['history_id'] ?? 0,
      schemaId: json['schema_id'] ?? 0,
      levelUser: json['level_user'] ?? '',
      hargaLama: (json['harga_lama'] as num?)?.toDouble() ?? 0.0,
      hargaBaru: (json['harga_baru'] as num?)?.toDouble() ?? 0.0,
      changedAt: json['changed_at'] != null
          ? DateTime.parse(json['changed_at']).toLocal()
          : DateTime.now(),
      changedByNama: json['changed_by_nama'] ?? '',
    );
  }
}

class DetailSampahModel {
  final String sampahId;
  final String namaSampah;
  final String photoUrl;
  final String satuan;
  final String syaratPemilahan;
  final String bankId;
  final KategoriSampahModel? kategori;
  final RewardModel? reward;
  final double stok;
  final List<HargaPerLevelModel> hargaPerLevel;
  final List<HistoryHargaModel> historyHarga;

  DetailSampahModel({
    required this.sampahId,
    required this.namaSampah,
    required this.photoUrl,
    required this.satuan,
    required this.syaratPemilahan,
    required this.bankId,
    this.kategori,
    this.reward,
    required this.stok,
    required this.hargaPerLevel,
    required this.historyHarga,
  });

  factory DetailSampahModel.fromJson(Map<String, dynamic> json) {
    return DetailSampahModel(
      sampahId: json['sampah_id'] ?? '',
      namaSampah: json['nama_sampah'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      satuan: json['satuan'] ?? '',
      syaratPemilahan: json['syarat_pemilahan'] ?? '',
      bankId: json['bank_id'] ?? '',
      kategori: json['kategori'] != null
          ? KategoriSampahModel.fromJson(json['kategori'] as Map<String, dynamic>)
          : null,
      reward: json['reward'] != null
          ? RewardModel.fromJson(json['reward'] as Map<String, dynamic>)
          : null,
      stok: (json['stok'] as num?)?.toDouble() ?? 0.0,
      hargaPerLevel: (json['harga_per_level'] as List<dynamic>? ?? [])
          .map((e) => HargaPerLevelModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      historyHarga: (json['history_harga'] as List<dynamic>? ?? [])
          .map((e) => HistoryHargaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Sembako models ────────────────────────────────────────────────────────────

class KatalogSembakoModel {
  final String sembakoId;
  final String namaSembako;
  final String photoUrl;
  final double stok;
  final double nilaiPoin;

  KatalogSembakoModel({
    required this.sembakoId,
    required this.namaSembako,
    required this.photoUrl,
    required this.stok,
    required this.nilaiPoin,
  });

  factory KatalogSembakoModel.fromJson(Map<String, dynamic> json) {
    return KatalogSembakoModel(
      sembakoId: json['produk_id']?.toString() ?? '',
      namaSembako: json['nama_barang']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? json['PhotoURL']?.toString() ?? '',
      stok: _toDouble(json['stok']),
      nilaiPoin: _toDouble(json['nilai_poin']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool get hasNilaiPoin => nilaiPoin > 0;
}

// ── Riwayat distribusi sembako ────────────────────────────────────────────────

class RiwayatDistribusiSembakoModel {
  final String disbakoId;
  final DateTime tanggalKirim;
  final double item;
  final double stokSebelum;
  final double stokSesudah;

  RiwayatDistribusiSembakoModel({
    required this.disbakoId,
    required this.tanggalKirim,
    required this.item,
    required this.stokSebelum,
    required this.stokSesudah,
  });

  factory RiwayatDistribusiSembakoModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['tanggal_kirim'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return RiwayatDistribusiSembakoModel(
      disbakoId: json['disba_id']?.toString() ?? '',
      tanggalKirim: parsedDate,
      item: (json['item'] as num?)?.toDouble() ?? 0.0,
      stokSebelum: (json['stok_sebelum'] as num?)?.toDouble() ?? 0.0,
      stokSesudah: (json['stok_sesudah'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DetailSembakoWithRiwayat {
  final KatalogSembakoModel sembako;
  final List<RiwayatDistribusiSembakoModel> riwayatDistribusi;

  DetailSembakoWithRiwayat({
    required this.sembako,
    required this.riwayatDistribusi,
  });
}

// ── Detail distribusi sembako ─────────────────────────────────────────────────

class DetailDistribusiItemModel {
  final String sembakoId;
  final String namaBarang;
  final String photoUrl;
  final double nilaiPoin;
  final double item;
  final double subtotalPoin;

  DetailDistribusiItemModel({
    required this.sembakoId,
    required this.namaBarang,
    required this.photoUrl,
    required this.nilaiPoin,
    required this.item,
    required this.subtotalPoin,
  });

  factory DetailDistribusiItemModel.fromJson(Map<String, dynamic> json) {
    return DetailDistribusiItemModel(
      sembakoId: json['produk_id']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '-',
      photoUrl: json['photo_url']?.toString() ?? '',
      nilaiPoin: (json['nilai_poin'] as num?)?.toDouble() ?? 0.0,
      item: (json['item'] as num?)?.toDouble() ?? 0.0,
      subtotalPoin: (json['subtotal_poin'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DetailDistribusiSembakoModel {
  final String disbakoId;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsi;
  final String namaAdminBsu;
  final DateTime createdAt;
  final double totalItem;
  final double totalPoin;
  final String statusDistribusi;
  final List<DetailDistribusiItemModel> items;

  DetailDistribusiSembakoModel({
    required this.disbakoId,
    required this.namaBsi,
    required this.namaBsu,
    required this.namaAdminBsi,
    required this.namaAdminBsu,
    required this.createdAt,
    required this.totalItem,
    required this.totalPoin,
    required this.statusDistribusi,
    required this.items,
  });

  factory DetailDistribusiSembakoModel.fromJson(Map<String, dynamic> json) {
    final hdr = json['header'] as Map<String, dynamic>;
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(hdr['created_at'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return DetailDistribusiSembakoModel(
      disbakoId: hdr['disba_id']?.toString() ?? '',
      namaBsi: hdr['nama_bsi']?.toString() ?? '-',
      namaBsu: hdr['nama_bsu']?.toString() ?? '-',
      namaAdminBsi: hdr['nama_admin_bsi']?.toString() ?? '-',
      namaAdminBsu: hdr['nama_admin_bsu']?.toString() ?? '-',
      createdAt: parsedDate,
      totalItem: (hdr['total_item'] as num?)?.toDouble() ?? 0.0,
      totalPoin: (hdr['total_poin'] as num?)?.toDouble() ?? 0.0,
      statusDistribusi: hdr['status_distribusi']?.toString() ?? '-',
      items: rawItems
          .map((e) => DetailDistribusiItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── List distribusi sembako (BSI → BSU) ──────────────────────────────────────

class ListDistribusiSembakoModel {
  final String disbakoId;
  final String namaBsu;
  final DateTime createdAt;
  final double totalItem;
  final String statusDistribusi;

  ListDistribusiSembakoModel({
    required this.disbakoId,
    required this.namaBsu,
    required this.createdAt,
    required this.totalItem,
    required this.statusDistribusi,
  });

  factory ListDistribusiSembakoModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return ListDistribusiSembakoModel(
      disbakoId: json['disba_id']?.toString() ?? '',
      namaBsu: json['nama_bsu']?.toString() ?? '-',
      createdAt: parsedDate,
      totalItem: (json['total_item'] as num?)?.toDouble() ?? 0.0,
      statusDistribusi: json['status_distribusi']?.toString() ?? '-',
    );
  }
}

// ── Preview distribusi sembako ─────────────────────────────────────────────────

class PreviewDistribusiItemModel {
  final String sembakoId;
  final String namaSembako;
  final String photoUrl;
  final double nilaiPoin;
  final int stokKirim;
  final int stokBsiSebelum;
  final int stokBsiSesudah;
  final int stokBsuSebelum;
  final int stokBsuSesudah;
  final bool bsuItemBaru;

  PreviewDistribusiItemModel({
    required this.sembakoId,
    required this.namaSembako,
    required this.photoUrl,
    required this.nilaiPoin,
    required this.stokKirim,
    required this.stokBsiSebelum,
    required this.stokBsiSesudah,
    required this.stokBsuSebelum,
    required this.stokBsuSesudah,
    required this.bsuItemBaru,
  });

  factory PreviewDistribusiItemModel.fromJson(Map<String, dynamic> json) {
    return PreviewDistribusiItemModel(
      sembakoId: json['produk_id']?.toString() ?? '',
      namaSembako: json['nama_barang']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString() ?? '',
      nilaiPoin: (json['nilai_poin'] as num?)?.toDouble() ?? 0.0,
      stokKirim: (json['stok_kirim'] as num?)?.toInt() ?? 0,
      stokBsiSebelum: (json['stok_bsi_sebelum'] as num?)?.toInt() ?? 0,
      stokBsiSesudah: (json['stok_bsi_sesudah'] as num?)?.toInt() ?? 0,
      stokBsuSebelum: (json['stok_bsu_sebelum'] as num?)?.toInt() ?? 0,
      stokBsuSesudah: (json['stok_bsu_sesudah'] as num?)?.toInt() ?? 0,
      bsuItemBaru: json['bsu_item_baru'] as bool? ?? false,
    );
  }
}
