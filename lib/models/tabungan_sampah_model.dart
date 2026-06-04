class ItemTabungan {
  final String tabunganId;
  final String namaSampah;
  final String satuan;
  final String namaReward;
  final double qtySetoran;
  final double sisaQty;
  final double? hargaItem;
  final double? nilaiTotal;
  final String status;

  ItemTabungan({
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

  factory ItemTabungan.fromJson(Map<String, dynamic> j) => ItemTabungan(
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

class SetoranGroup {
  final String sourceId;
  final DateTime? tanggalSetoran;
  final List<ItemTabungan> items;

  SetoranGroup({
    required this.sourceId,
    required this.tanggalSetoran,
    required this.items,
  });

  factory SetoranGroup.fromJson(Map<String, dynamic> j) {
    final tanggalRaw = j['tanggal_setoran'] as String? ?? '';
    return SetoranGroup(
      sourceId: j['source_id'] ?? '',
      tanggalSetoran: tanggalRaw.isNotEmpty ? DateTime.tryParse(tanggalRaw) : null,
      items: ((j['items'] as List?) ?? [])
          .map((e) => ItemTabungan.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BukuTabunganResponse {
  final String nasabahId;
  final List<SetoranGroup> setoran;

  BukuTabunganResponse({
    required this.nasabahId,
    required this.setoran,
  });

  factory BukuTabunganResponse.fromJson(Map<String, dynamic> j) =>
      BukuTabunganResponse(
        nasabahId: j['nasabah_id'] ?? '',
        setoran: ((j['setoran'] as List?) ?? [])
            .map((e) => SetoranGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── BSU Tabungan Models ─────────────────────────────────────────────────────

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

  // PostgreSQL OF format outputs "+07" (no minutes), Dart needs "+07:00"
  static DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final normalized = raw.replaceAllMapped(
      RegExp(r'([+-]\d{2})$'),
      (m) => '${m[1]}:00',
    );
    return DateTime.tryParse(normalized);
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
