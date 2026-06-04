class MutasiItem {
  final bool isPositive;
  final double nominal;
  final DateTime tanggalTransaksi;

  const MutasiItem({
    required this.isPositive,
    required this.nominal,
    required this.tanggalTransaksi,
  });

  factory MutasiItem.fromJson(Map<String, dynamic> json) {
    return MutasiItem(
      isPositive: json['is_positive'] as bool? ?? false,
      nominal: (json['nominal'] as num?)?.toDouble() ?? 0,
      tanggalTransaksi: DateTime.parse(json['tanggal_transaksi'] as String),
    );
  }
}

class MutasiResponse {
  final String namaReward;
  final String satuanReward;
  // totalDebit = saldo keluar (isPositive=false items) in backend terms
  // totalKredit = saldo masuk (isPositive=true items) in backend terms
  final double totalDebit;
  final double totalKredit;
  final List<MutasiItem> mutasiItems;

  const MutasiResponse({
    required this.namaReward,
    required this.satuanReward,
    required this.totalDebit,
    required this.totalKredit,
    required this.mutasiItems,
  });

  factory MutasiResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['mutasi_items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(MutasiItem.fromJson)
            .toList()
        : <MutasiItem>[];

    return MutasiResponse(
      namaReward: json['nama_reward'] as String? ?? '',
      satuanReward: json['satuan_reward'] as String? ?? '',
      totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0,
      totalKredit: (json['total_kredit'] as num?)?.toDouble() ?? 0,
      mutasiItems: items,
    );
  }
}
