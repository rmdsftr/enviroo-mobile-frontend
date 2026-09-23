class RiwayatSetoranModel {
  final String setoranId;
  final String namaPetugas;
  final DateTime transaksiTimestamp;
  final int totalItem;

  RiwayatSetoranModel({
    required this.setoranId,
    required this.namaPetugas,
    required this.transaksiTimestamp,
    required this.totalItem,
  });

  factory RiwayatSetoranModel.fromJson(Map<String, dynamic> json) {
    return RiwayatSetoranModel(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? 'Petugas',
      transaksiTimestamp:
          DateTime.tryParse(json['transaksi_timestamp'] ?? '')?.toLocal() ??
              DateTime.now(),
      totalItem: json['total_item'] ?? 0,
    );
  }
}

class SetoranDetailHeader {
  final String setoranId;
  final String namaPetugas;
  final String namaNasabah;
  final DateTime transaksiTimestamp;
  final int totalItem;
  final String buktiViaManual;

  SetoranDetailHeader({
    required this.setoranId,
    required this.namaPetugas,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
    required this.buktiViaManual,
  });

  factory SetoranDetailHeader.fromJson(Map<String, dynamic> j) =>
      SetoranDetailHeader(
        setoranId: j['setoran_id'] ?? '',
        namaPetugas: j['nama_petugas'] ?? '',
        namaNasabah: j['nama_nasabah'] ?? '',
        transaksiTimestamp:
            DateTime.tryParse(j['transaksi_timestamp'] ?? '')?.toLocal() ??
                DateTime.now(),
        totalItem: j['total_item'] ?? 0,
        buktiViaManual: j['bukti_via_manual'] ?? '',
      );
}
