// RewardModel dulu dideklarasi kembar di sini. Sekarang satu definisi saja,
// tinggal di penjualan_model.dart.
import 'penjualan_model.dart';

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
  // String, bukan int: backend mengirim id sebagai teks ("12010010010022").
  // Dulu bertipe int, dan karena `json[...]` itu dynamic, analyzer diam —
  // gagalnya baru muncul saat runtime sebagai TypeError yang lalu ditelan
  // `catch` di KatalogProvider dan tampil sebagai "Data tidak tersedia".
  final String schemaId;
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
      schemaId: json['schema_id']?.toString() ?? '',
      levelUser: json['level_user'] ?? '',
      harga: (json['harga'] as num?)?.toDouble() ?? 0.0,
      satuanReward: json['satuan_reward'] ?? '',
    );
  }
}

class HistoryHargaModel {
  // Sama seperti HargaPerLevelModel: id dikirim backend sebagai teks.
  final String historyId;
  final String schemaId;
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
      historyId: json['history_id']?.toString() ?? '',
      schemaId: json['schema_id']?.toString() ?? '',
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

// ── Barang models ────────────────────────────────────────────────────────────

class KatalogBarangModel {
  final String produkId;
  final String namaBarang;
  final String photoUrl;
  final double stok;
  final double nilaiPoin;

  KatalogBarangModel({
    required this.produkId,
    required this.namaBarang,
    required this.photoUrl,
    required this.stok,
    required this.nilaiPoin,
  });

  factory KatalogBarangModel.fromJson(Map<String, dynamic> json) {
    return KatalogBarangModel(
      produkId: json['produk_id']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '',
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

// ── Riwayat distribusi barang ────────────────────────────────────────────────

class RiwayatDistribusiBarangModel {
  final String disbaId;
  final DateTime tanggalKirim;
  final double item;
  final double stokSebelum;
  final double stokSesudah;

  RiwayatDistribusiBarangModel({
    required this.disbaId,
    required this.tanggalKirim,
    required this.item,
    required this.stokSebelum,
    required this.stokSesudah,
  });

  factory RiwayatDistribusiBarangModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['tanggal_kirim'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return RiwayatDistribusiBarangModel(
      disbaId: json['disba_id']?.toString() ?? '',
      tanggalKirim: parsedDate,
      item: (json['item'] as num?)?.toDouble() ?? 0.0,
      stokSebelum: (json['stok_sebelum'] as num?)?.toDouble() ?? 0.0,
      stokSesudah: (json['stok_sesudah'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DetailBarangWithRiwayat {
  final KatalogBarangModel barang;
  final List<RiwayatDistribusiBarangModel> riwayatDistribusi;

  DetailBarangWithRiwayat({
    required this.barang,
    required this.riwayatDistribusi,
  });
}

// ── Detail distribusi barang ─────────────────────────────────────────────────

class DetailDistribusiItemModel {
  final String produkId;
  final String namaBarang;
  final String photoUrl;
  final double nilaiPoin;
  final double item;
  final double subtotalPoin;

  DetailDistribusiItemModel({
    required this.produkId,
    required this.namaBarang,
    required this.photoUrl,
    required this.nilaiPoin,
    required this.item,
    required this.subtotalPoin,
  });

  factory DetailDistribusiItemModel.fromJson(Map<String, dynamic> json) {
    return DetailDistribusiItemModel(
      produkId: json['produk_id']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '-',
      photoUrl: json['photo_url']?.toString() ?? '',
      nilaiPoin: (json['nilai_poin'] as num?)?.toDouble() ?? 0.0,
      item: (json['item'] as num?)?.toDouble() ?? 0.0,
      subtotalPoin: (json['subtotal_poin'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DetailDistribusiBarangModel {
  final String disbaId;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsi;
  final String namaAdminBsu;
  final DateTime createdAt;
  final double totalItem;
  final double totalPoin;
  final String statusDistribusi;
  final List<DetailDistribusiItemModel> items;

  DetailDistribusiBarangModel({
    required this.disbaId,
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

  factory DetailDistribusiBarangModel.fromJson(Map<String, dynamic> json) {
    final hdr = json['header'] as Map<String, dynamic>;
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(hdr['created_at'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return DetailDistribusiBarangModel(
      disbaId: hdr['disba_id']?.toString() ?? '',
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

// ── List distribusi barang (BSI → BSU) ──────────────────────────────────────

class ListDistribusiBarangModel {
  final String disbaId;
  final String namaBsu;
  final DateTime createdAt;
  final double totalItem;
  final String statusDistribusi;

  ListDistribusiBarangModel({
    required this.disbaId,
    required this.namaBsu,
    required this.createdAt,
    required this.totalItem,
    required this.statusDistribusi,
  });

  factory ListDistribusiBarangModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at'] ?? '').toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }
    return ListDistribusiBarangModel(
      disbaId: json['disba_id']?.toString() ?? '',
      namaBsu: json['nama_bsu']?.toString() ?? '-',
      createdAt: parsedDate,
      totalItem: (json['total_item'] as num?)?.toDouble() ?? 0.0,
      statusDistribusi: json['status_distribusi']?.toString() ?? '-',
    );
  }
}

// ── Preview distribusi barang ─────────────────────────────────────────────────

class PreviewDistribusiItemModel {
  final String produkId;
  final String namaBarang;
  final String photoUrl;
  final double nilaiPoin;
  final int stokKirim;
  final int stokBsiSebelum;
  final int stokBsiSesudah;
  final int stokBsuSebelum;
  final int stokBsuSesudah;
  final bool bsuItemBaru;

  PreviewDistribusiItemModel({
    required this.produkId,
    required this.namaBarang,
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
      produkId: json['produk_id']?.toString() ?? '',
      namaBarang: json['nama_barang']?.toString() ?? '',
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
