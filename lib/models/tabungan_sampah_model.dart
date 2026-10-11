class DetailPencairan {
  final DateTime? tanggalCair;

  final double qtyDipakai;

  final double hargaItem;

  final double subtotal;

  DetailPencairan({
    required this.tanggalCair,
    required this.qtyDipakai,
    required this.hargaItem,
    required this.subtotal,
  });

  factory DetailPencairan.fromJson(Map<String, dynamic> j) => DetailPencairan(
        tanggalCair:
            DateTime.tryParse(j['tanggal_cair']?.toString() ?? '')?.toLocal(),
        qtyDipakai: (j['qty_dipakai'] as num?)?.toDouble() ?? 0.0,
        hargaItem: (j['harga_item'] as num?)?.toDouble() ?? 0.0,
        subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0.0,
      );
}

class BarisTabungan {
  final String tabunganId;

  final String sourceId;

  final DateTime? createdAt;

  final double qty;

  final double sisaQty;

  final String status;

  final List<DetailPencairan> detailPencairan;

  BarisTabungan({
    required this.tabunganId,
    required this.sourceId,
    required this.createdAt,
    required this.qty,
    required this.sisaQty,
    required this.status,
    required this.detailPencairan,
  });

  factory BarisTabungan.fromJson(Map<String, dynamic> j) => BarisTabungan(
        tabunganId: j['tabungan_id']?.toString() ?? '',
        sourceId: j['source_id']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '')?.toLocal(),
        qty: (j['qty'] as num?)?.toDouble() ?? 0.0,
        sisaQty: (j['sisa_qty'] as num?)?.toDouble() ?? 0.0,
        status: j['status']?.toString() ?? '',
        detailPencairan: ((j['detail_pencairan'] as List?) ?? [])
            .map((e) => DetailPencairan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SampahTabungan {
  final String sampahId;
  final String namaSampah;

  final String satuanSampah;

  final String satuanDiterima;

  final List<BarisTabungan> tabungan;

  SampahTabungan({
    required this.sampahId,
    required this.namaSampah,
    required this.satuanSampah,
    required this.satuanDiterima,
    required this.tabungan,
  });

  factory SampahTabungan.fromJson(Map<String, dynamic> j) => SampahTabungan(
        sampahId: j['sampah_id']?.toString() ?? '',
        namaSampah: j['nama_sampah']?.toString() ?? '',
        satuanSampah: j['satuan_sampah']?.toString() ?? '',
        satuanDiterima: j['satuan_diterima']?.toString() ?? '',
        tabungan: ((j['tabungan'] as List?) ?? [])
            .map((e) => BarisTabungan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BukuTabunganResponse {
  final String nasabahId;
  final List<SampahTabungan> sampah;

  BukuTabunganResponse({
    required this.nasabahId,
    required this.sampah,
  });

  factory BukuTabunganResponse.fromJson(Map<String, dynamic> j) =>
      BukuTabunganResponse(
        nasabahId: j['nasabah_id']?.toString() ?? '',
        sampah: ((j['sampah'] as List?) ?? [])
            .map((e) => SampahTabungan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ItemTabunganBsu {
  final String tabunganId;
  final String namaSampah;
  final String satuan;
  final String namaReward;
  final double qtySetoran;
  final double sisaQty;
  final double? hargaItem;
  final double? nilaiTotal;
  final String status;

  ItemTabunganBsu({
    required this.tabunganId,
    required this.namaSampah,
    required this.satuan,
    required this.namaReward,
    required this.qtySetoran,
    required this.sisaQty,
    required this.hargaItem,
    required this.nilaiTotal,
    required this.status,
  });

  factory ItemTabunganBsu.fromJson(Map<String, dynamic> j) => ItemTabunganBsu(
        tabunganId: j['tabungan_id'] ?? '',
        namaSampah: j['nama_sampah'] ?? '',
        satuan: j['satuan'] ?? '',
        namaReward: j['nama_reward'] ?? '',
        qtySetoran: (j['qty_setoran'] as num?)?.toDouble() ?? 0.0,
        sisaQty: (j['sisa_qty'] as num?)?.toDouble() ?? 0.0,
        hargaItem: (j['harga_item'] as num?)?.toDouble(),
        nilaiTotal: (j['nilai_total'] as num?)?.toDouble(),
        status: j['status'] ?? '',
      );
}

class PengangkutanGroup {
  final String sourceId;
  final DateTime? tanggalSetoran;
  final List<ItemTabunganBsu> items;

  PengangkutanGroup({
    required this.sourceId,
    required this.tanggalSetoran,
    required this.items,
  });

  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final clean = raw
        .replaceAll('Z', '')
        .replaceAll(RegExp(r'[+-]\d{2}:\d{2}$'), '')
        .trim();
    return DateTime.tryParse('${clean}+07:00')?.toLocal();
  }

  factory PengangkutanGroup.fromJson(Map<String, dynamic> j) {
    final tRaw = j['tanggal_setoran'] as String? ?? '';
    return PengangkutanGroup(
      sourceId: j['source_id'] ?? '',
      tanggalSetoran: _parseDate(tRaw),
      items: ((j['items'] as List?) ?? [])
          .map((e) => ItemTabunganBsu.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BukuTabunganBsuResponse {
  final String bankId;
  final List<PengangkutanGroup> pengangkutan;

  BukuTabunganBsuResponse({
    required this.bankId,
    required this.pengangkutan,
  });

  factory BukuTabunganBsuResponse.fromJson(Map<String, dynamic> j) =>
      BukuTabunganBsuResponse(
        bankId: j['bank_id'] ?? '',
        pengangkutan: ((j['pengangkutan'] as List?) ?? [])
            .map((e) => PengangkutanGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
