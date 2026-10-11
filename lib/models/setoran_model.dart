import '../core/format/app_date.dart';

class SetoranItem {
  final String namaSampah;
  final double qty;
  final String satuan;

  SetoranItem({
    required this.namaSampah,
    required this.qty,
    required this.satuan,
  });

  factory SetoranItem.fromJson(Map<String, dynamic> json) {
    return SetoranItem(
      namaSampah: json['nama_sampah'] ?? '-',
      qty: (json['qty'] as num? ?? 0).toDouble(),
      satuan: json['satuan'] ?? '',
    );
  }
}

class SetoranSummary {
  final String setoranId;
  final String namaPetugas;
  final String? nasabahId;
  final String namaNasabah;
  final String transaksiTimestamp;
  final int totalItem;

  SetoranSummary({
    required this.setoranId,
    required this.namaPetugas,
    this.nasabahId,
    required this.namaNasabah,
    required this.transaksiTimestamp,
    required this.totalItem,
  });

  factory SetoranSummary.fromJson(Map<String, dynamic> json) {
    String timestamp = '-';
    if (json['transaksi_timestamp'] != null) {
      try {
        timestamp = AppDate.tanggalPenuhJam(
            DateTime.parse(json['transaksi_timestamp']).toLocal());
      } catch (_) {
        timestamp = json['transaksi_timestamp'].toString();
      }
    }
    return SetoranSummary(
      setoranId: json['setoran_id'] ?? '',
      namaPetugas: json['nama_petugas'] ?? '-',
      nasabahId: json['nasabah_id'] ?? '',
      namaNasabah: json['nama_nasabah'] ?? '-',
      transaksiTimestamp: timestamp,
      totalItem: (json['total_item'] ?? 0) as int,
    );
  }
}
