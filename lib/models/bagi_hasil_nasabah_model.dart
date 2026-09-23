class BagiHasilNasabahItem {
  final String penerimaId;
  final String bagiHasilId;
  final String reward;
  final DateTime tanggal;
  final double totalDiterima;
  final String satuanDiterima;

  BagiHasilNasabahItem({
    required this.penerimaId,
    required this.bagiHasilId,
    required this.reward,
    required this.tanggal,
    required this.totalDiterima,
    required this.satuanDiterima,
  });

  factory BagiHasilNasabahItem.fromJson(Map<String, dynamic> j) =>
      BagiHasilNasabahItem(
        penerimaId: j['penerima_id'] ?? '',
        bagiHasilId: j['bagi_hasil_id'] ?? '',
        reward: j['reward'] ?? '',
        tanggal:
            DateTime.tryParse(j['tanggal'] ?? '')?.toLocal() ?? DateTime.now(),
        totalDiterima: (j['total_diterima'] as num?)?.toDouble() ?? 0.0,
        satuanDiterima: j['satuan_diterima'] ?? '',
      );
}

class BagiHasilNasabahDetailItem {
  final String namaSampah;
  final double qty;
  final double hargaItem;
  final double subtotalHarga;

  BagiHasilNasabahDetailItem({
    required this.namaSampah,
    required this.qty,
    required this.hargaItem,
    required this.subtotalHarga,
  });

  factory BagiHasilNasabahDetailItem.fromJson(Map<String, dynamic> j) =>
      BagiHasilNasabahDetailItem(
        namaSampah: j['nama_sampah'] ?? '',
        qty: (j['qty'] as num?)?.toDouble() ?? 0.0,
        hargaItem: (j['harga_item'] as num?)?.toDouble() ?? 0.0,
        subtotalHarga: (j['subtotal_harga'] as num?)?.toDouble() ?? 0.0,
      );
}

class BagiHasilNasabahDetail {
  final String penerimaId;
  final String namaNasabah;
  final String reward;
  final DateTime tanggal;
  final double totalDiterima;
  final String satuanDiterima;
  final List<BagiHasilNasabahDetailItem> items;

  BagiHasilNasabahDetail({
    required this.penerimaId,
    required this.namaNasabah,
    required this.reward,
    required this.tanggal,
    required this.totalDiterima,
    required this.satuanDiterima,
    required this.items,
  });

  factory BagiHasilNasabahDetail.fromJson(Map<String, dynamic> j) {
    final rawItems = j['detail_item'] as List? ?? [];
    return BagiHasilNasabahDetail(
      penerimaId: j['penerima_id'] ?? '',
      namaNasabah: j['nama_nasabah'] ?? '',
      reward: j['reward'] ?? '',
      tanggal:
          DateTime.tryParse(j['tanggal'] ?? '')?.toLocal() ?? DateTime.now(),
      totalDiterima: (j['total_diterima'] as num?)?.toDouble() ?? 0.0,
      satuanDiterima: j['satuan_diterima'] ?? '',
      items: rawItems
          .map((e) =>
              BagiHasilNasabahDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
