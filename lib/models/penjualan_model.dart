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

// ─── Riwayat Penjualan (List Item) ──────────────────────────────────────────
class RiwayatPenjualanModel {
  final String penjualanId;
  final String identitasPembeli;
  final String namaReward;
  final String satuanReward;
  final int totalItem;
  final double totalPenjualan;
  final String buktiFoto;
  final DateTime createdAt;
  final String adminName;
  final String statusBagiHasil;

  RiwayatPenjualanModel({
    required this.penjualanId,
    required this.identitasPembeli,
    required this.namaReward,
    required this.satuanReward,
    required this.totalItem,
    required this.totalPenjualan,
    required this.buktiFoto,
    required this.createdAt,
    required this.adminName,
    required this.statusBagiHasil,
  });

  factory RiwayatPenjualanModel.fromJson(Map<String, dynamic> json) {
    return RiwayatPenjualanModel(
      penjualanId: json['penjualan_id'] ?? '',
      identitasPembeli: json['identitas_pembeli'] ?? '',
      namaReward: json['nama_reward'] ?? '',
      satuanReward: json['satuan_reward'] ?? '',
      totalItem: json['total_item'] ?? 0,
      totalPenjualan: (json['total_penjualan'] ?? 0).toDouble(),
      buktiFoto: json['bukti_foto'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      adminName: json['admin_name'] ?? '',
      statusBagiHasil: json['status_bagi_hasil'] ?? 'pending',
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
  final double hargaJual;
  final double subtotalPenjualan;
  final double hargaNasabahSnapshot;

  DetailSampahPenjualanModel({
    required this.sampahId,
    required this.namaSampah,
    required this.qty,
    required this.hargaJual,
    required this.subtotalPenjualan,
    required this.hargaNasabahSnapshot,
  });

  factory DetailSampahPenjualanModel.fromJson(Map<String, dynamic> json) {
    return DetailSampahPenjualanModel(
      sampahId: json['sampah_id'] ?? '',
      namaSampah: json['nama_sampah'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      hargaJual: (json['harga_jual'] ?? 0).toDouble(),
      subtotalPenjualan: (json['subtotal_penjualan'] ?? 0).toDouble(),
      hargaNasabahSnapshot: (json['harga_nasabah_snapshot'] ?? 0).toDouble(),
    );
  }
}

class DetailPenjualanModel {
  final String penjualanId;
  final String identitasPembeli;
  final String namaReward;
  final String satuanReward;
  final int totalItem;
  final double totalPenjualan;
  final String buktiFoto;
  final DateTime createdAt;
  final String adminName;
  final String statusBagiHasil;
  final List<DetailSampahPenjualanModel> itemsSampah;

  DetailPenjualanModel({
    required this.penjualanId,
    required this.identitasPembeli,
    required this.namaReward,
    required this.satuanReward,
    required this.totalItem,
    required this.totalPenjualan,
    required this.buktiFoto,
    required this.createdAt,
    required this.adminName,
    required this.statusBagiHasil,
    required this.itemsSampah,
  });

  factory DetailPenjualanModel.fromJson(Map<String, dynamic> json) {
    return DetailPenjualanModel(
      penjualanId: json['penjualan_id'] ?? '',
      identitasPembeli: json['identitas_pembeli'] ?? '',
      namaReward: json['nama_reward'] ?? '',
      satuanReward: json['satuan_reward'] ?? '',
      totalItem: json['total_item'] ?? 0,
      totalPenjualan: (json['total_penjualan'] ?? 0).toDouble(),
      buktiFoto: json['bukti_foto'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      adminName: json['admin_name'] ?? '',
      statusBagiHasil: json['status_bagi_hasil'] ?? 'pending',
      itemsSampah: (json['items_sampah'] as List? ?? [])
          .map((e) => DetailSampahPenjualanModel.fromJson(e))
          .toList(),
    );
  }

  String get tanggalFormatted =>
      DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(createdAt);
}

// ─── Preview Penjualan ───────────────────────────────────────────────────────
class DetailKalkulasiItem {
  final String sampahId;
  final String namaSampah;
  final double qty;
  final double hargaJual;
  final double subtotal;
  final double hargaNasabahSnapshot;

  DetailKalkulasiItem({
    required this.sampahId,
    required this.namaSampah,
    required this.qty,
    required this.hargaJual,
    required this.subtotal,
    required this.hargaNasabahSnapshot,
  });

  factory DetailKalkulasiItem.fromJson(Map<String, dynamic> json) {
    return DetailKalkulasiItem(
      sampahId: json['SampahID'] ?? json['sampah_id'] ?? '',
      namaSampah: json['NamaSampah'] ?? json['nama_sampah'] ?? '',
      qty: (json['Qty'] ?? json['qty'] ?? 0).toDouble(),
      hargaJual: (json['HargaJual'] ?? json['harga_jual'] ?? 0).toDouble(),
      subtotal: (json['Subtotal'] ?? json['subtotal'] ?? 0).toDouble(),
      hargaNasabahSnapshot: (json['HargaNasabahSnapshot'] ?? json['harga_nasabah_snapshot'] ?? 0).toDouble(),
    );
  }
}

class PreviewPenjualanModel {
  final double totalPenjualan;
  final String satuan;
  final double persenNasabah;
  final List<DetailKalkulasiItem> detailItems;

  PreviewPenjualanModel({
    required this.totalPenjualan,
    required this.satuan,
    required this.persenNasabah,
    required this.detailItems,
  });

  factory PreviewPenjualanModel.fromJson(Map<String, dynamic> json) {
    return PreviewPenjualanModel(
      totalPenjualan: (json['total_penjualan'] ?? 0).toDouble(),
      satuan: json['satuan']?.toString() ?? '',
      persenNasabah: (json['persen_nasabah'] ?? 0).toDouble(),
      detailItems: (json['detail_items'] as List? ?? [])
          .map((e) => DetailKalkulasiItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Item Pilihan (state lokal saat input) ──────────────────────────────────
class ItemSampahPilihan {
  final String sampahId;
  final String namaSampah;
  final String satuan;
  final double stokTersedia;
  double qty;
  double hargaJual; // diinput manual oleh admin per transaksi

  ItemSampahPilihan({
    required this.sampahId,
    required this.namaSampah,
    required this.satuan,
    required this.stokTersedia,
    this.qty = 0,
    this.hargaJual = 0,
  });

  Map<String, dynamic> toPayload() => {
        'sampah_id': sampahId,
        'qty': qty,
        'harga_jual': hargaJual,
      };
}
