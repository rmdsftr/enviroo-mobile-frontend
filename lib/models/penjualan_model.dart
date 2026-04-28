import 'package:intl/intl.dart';

// ─── Reward (Master Data) ───────────────────────────────────────────────────
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
      namaReward: json['NamaReward'] ?? json['nama_reward'] ?? '',
      satuan: json['Satuan'] ?? json['satuan'] ?? '',
      deskripsi: json['Deskripsi'] ?? json['deskripsi'],
    );
  }

  bool get isSembako => namaReward.toLowerCase() == 'sembako';
}

// ─── Nilai Reward Bank (Konversi) ───────────────────────────────────────────
class NilaiRewardBankModel {
  final String nilaiRewardId;
  final String bankId;
  final int rewardId;
  final double nilaiPoin;
  final double nilaiKonversi;
  final RewardModel? reward;

  NilaiRewardBankModel({
    required this.nilaiRewardId,
    required this.bankId,
    required this.rewardId,
    required this.nilaiPoin,
    required this.nilaiKonversi,
    this.reward,
  });

  factory NilaiRewardBankModel.fromJson(Map<String, dynamic> json) {
    return NilaiRewardBankModel(
      nilaiRewardId: json['NilaiRewardID'] ?? json['nilai_reward_id'] ?? '',
      bankId: json['BankID'] ?? json['bank_id'] ?? '',
      rewardId: json['RewardID'] ?? json['reward_id'] ?? 0,
      nilaiPoin: (json['NilaiPoin'] ?? json['nilai_poin'] ?? 0).toDouble(),
      nilaiKonversi:
          (json['NilaiKonversi'] ?? json['nilai_konversi'] ?? 0).toDouble(),
      reward: json['Reward'] != null
          ? RewardModel.fromJson(json['Reward'])
          : (json['reward'] != null ? RewardModel.fromJson(json['reward']) : null),
    );
  }
}

// ─── Riwayat Penjualan (List Item) ──────────────────────────────────────────
class RiwayatPenjualanModel {
  final String penjualanId;
  final String identitasPembeli;
  final String rewardName;
  final String? satuan;
  final int totalItem;
  final double totalPoin;
  final double totalKonversi;
  final String buktiFoto;
  final DateTime createdAt;
  final String adminName;

  RiwayatPenjualanModel({
    required this.penjualanId,
    required this.identitasPembeli,
    required this.rewardName,
    this.satuan,
    required this.totalItem,
    required this.totalPoin,
    required this.totalKonversi,
    required this.buktiFoto,
    required this.createdAt,
    required this.adminName,
  });

  factory RiwayatPenjualanModel.fromJson(Map<String, dynamic> json) {
    return RiwayatPenjualanModel(
      penjualanId: json['penjualan_id'] ?? '',
      identitasPembeli: json['identitas_pembeli'] ?? '',
      rewardName: json['reward_name'] ?? '',
      satuan: json['satuan'],
      totalItem: json['total_item'] ?? 0,
      totalPoin: (json['total_poin'] ?? 0).toDouble(),
      totalKonversi: (json['total_konversi'] ?? 0).toDouble(),
      buktiFoto: json['bukti_foto'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      adminName: json['admin_name'] ?? '',
    );
  }

  String get tanggalFormatted =>
      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(createdAt);
}

// ─── Detail Penjualan ───────────────────────────────────────────────────────
class DetailSampahPenjualanModel {
  final String sampahId;
  final String namaSampah;
  final double qty;
  final double poinJual;
  final double nilaiKonversi;
  final double subtotalPoin;
  final double subtotalKonversi;

  DetailSampahPenjualanModel({
    required this.sampahId,
    required this.namaSampah,
    required this.qty,
    required this.poinJual,
    required this.nilaiKonversi,
    required this.subtotalPoin,
    required this.subtotalKonversi,
  });

  factory DetailSampahPenjualanModel.fromJson(Map<String, dynamic> json) {
    return DetailSampahPenjualanModel(
      sampahId: json['sampah_id'] ?? '',
      namaSampah: json['nama_sampah'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      poinJual: (json['poin_jual'] ?? 0).toDouble(),
      nilaiKonversi: (json['nilai_konversi'] ?? 0).toDouble(),
      subtotalPoin: (json['subtotal_poin'] ?? 0).toDouble(),
      subtotalKonversi: (json['subtotal_konversi'] ?? 0).toDouble(),
    );
  }
}

class DetailSembakoPenjualanModel {
  final String sembakoId;
  final String namaSembako;
  final double qty;
  final double hargaPoin;
  final double subtotalPoin;

  DetailSembakoPenjualanModel({
    required this.sembakoId,
    required this.namaSembako,
    required this.qty,
    required this.hargaPoin,
    required this.subtotalPoin,
  });

  factory DetailSembakoPenjualanModel.fromJson(Map<String, dynamic> json) {
    return DetailSembakoPenjualanModel(
      sembakoId: json['sembako_id'] ?? '',
      namaSembako: json['nama_sembako'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      hargaPoin: (json['harga_poin'] ?? 0).toDouble(),
      subtotalPoin: (json['subtotal_poin'] ?? 0).toDouble(),
    );
  }
}

class DetailPenjualanModel {
  final String penjualanId;
  final String identitasPembeli;
  final String rewardName;
  final String? satuan;
  final int totalItem;
  final double totalPoin;
  final double totalKonversi;
  final String buktiFoto;
  final DateTime createdAt;
  final String adminName;
  final List<DetailSampahPenjualanModel> itemsSampah;
  final List<DetailSembakoPenjualanModel>? itemsSembako;

  DetailPenjualanModel({
    required this.penjualanId,
    required this.identitasPembeli,
    required this.rewardName,
    this.satuan,
    required this.totalItem,
    required this.totalPoin,
    required this.totalKonversi,
    required this.buktiFoto,
    required this.createdAt,
    required this.adminName,
    required this.itemsSampah,
    this.itemsSembako,
  });

  factory DetailPenjualanModel.fromJson(Map<String, dynamic> json) {
    return DetailPenjualanModel(
      penjualanId: json['penjualan_id'] ?? '',
      identitasPembeli: json['identitas_pembeli'] ?? '',
      rewardName: json['reward_name'] ?? '',
      satuan: json['satuan'],
      totalItem: json['total_item'] ?? 0,
      totalPoin: (json['total_poin'] ?? 0).toDouble(),
      totalKonversi: (json['total_konversi'] ?? 0).toDouble(),
      buktiFoto: json['bukti_foto'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      adminName: json['admin_name'] ?? '',
      itemsSampah: (json['items_sampah'] as List? ?? [])
          .map((e) => DetailSampahPenjualanModel.fromJson(e))
          .toList(),
      itemsSembako: (json['items_sembako'] as List?)
          ?.map((e) => DetailSembakoPenjualanModel.fromJson(e))
          .toList(),
    );
  }

  bool get isSembako => rewardName.toLowerCase() == 'sembako';

  String get tanggalFormatted =>
      DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(createdAt) +
      ' WIB';
}

// ─── Item Pilihan (state lokal saat input) ──────────────────────────────────
class ItemSampahPilihan {
  final String sampahId;
  final String namaSampah;
  final String satuan;
  final double hargaEksternal;
  final double stokTersedia;
  double qty;

  ItemSampahPilihan({
    required this.sampahId,
    required this.namaSampah,
    required this.satuan,
    required this.hargaEksternal,
    required this.stokTersedia,
    this.qty = 0,
  });

  Map<String, dynamic> toPayload() => {
        'sampah_id': sampahId,
        'qty': qty,
      };
}

class ItemSembakoPilihan {
  final String sembakoId;
  final String namaSembako;
  final double hargaEksternal;
  double qty;

  ItemSembakoPilihan({
    required this.sembakoId,
    required this.namaSembako,
    required this.hargaEksternal,
    this.qty = 0,
  });

  Map<String, dynamic> toPayload() => {
        'sembako_id': sembakoId,
        'qty': qty,
      };
}

// ─── Sembako (untuk listing) ────────────────────────────────────────────────
class SembakoListingModel {
  final String sembakoId;
  final String namaSembako;
  final String photoUrl;
  final double stok;
  final double hargaEksternal;

  SembakoListingModel({
    required this.sembakoId,
    required this.namaSembako,
    required this.photoUrl,
    required this.stok,
    required this.hargaEksternal,
  });

  factory SembakoListingModel.fromJson(Map<String, dynamic> json) {
    final schema = (json['schema_harga'] as List?) ?? [];
    double hargaEks = 0;
    for (final s in schema) {
      if ((s['level_user'] ?? '').toString().toLowerCase() == 'eksternal') {
        hargaEks = (s['poin_harga'] ?? 0).toDouble();
        break;
      }
    }
    return SembakoListingModel(
      sembakoId: json['sembako_id'] ?? '',
      namaSembako: json['nama_sembako'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      stok: (json['stok'] ?? 0).toDouble(),
      hargaEksternal: hargaEks,
    );
  }
}
