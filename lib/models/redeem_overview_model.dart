/// Model untuk response GET /dashboard/redeem-overview/:nasabah_id
class DetailItemSembako {
  final String sembakoId;
  final String namaSembako;
  final String photoUrl;
  final double totalQty;
  final double poinPerItem;
  final double totalNominalPoin;

  DetailItemSembako({
    required this.sembakoId,
    required this.namaSembako,
    required this.photoUrl,
    required this.totalQty,
    required this.poinPerItem,
    required this.totalNominalPoin,
  });

  factory DetailItemSembako.fromJson(Map<String, dynamic> json) {
    return DetailItemSembako(
      sembakoId: json['sembako_id'] ?? '',
      namaSembako: json['nama_sembako'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      totalQty: (json['total_qty'] as num?)?.toDouble() ?? 0,
      poinPerItem: (json['poin_per_item'] as num?)?.toDouble() ?? 0,
      totalNominalPoin: (json['total_nominal_poin'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RedeemOverviewItem {
  final String namaReward;
  final String satuanReward;
  final double totalNominal;
  final List<DetailItemSembako> detailItemReward;

  RedeemOverviewItem({
    required this.namaReward,
    required this.satuanReward,
    required this.totalNominal,
    required this.detailItemReward,
  });

  bool get isUang => namaReward.toLowerCase().contains('uang');
  bool get isEmas => namaReward.toLowerCase().contains('emas');
  bool get isSembako => namaReward.toLowerCase().contains('sembako');

  factory RedeemOverviewItem.fromJson(Map<String, dynamic> json) {
    final detailList = (json['detail_item_reward'] as List?) ?? [];
    return RedeemOverviewItem(
      namaReward: json['nama_reward'] ?? '',
      satuanReward: json['satuan_reward'] ?? '',
      totalNominal: (json['total_nominal'] as num?)?.toDouble() ?? 0,
      detailItemReward: detailList
          .whereType<Map<String, dynamic>>()
          .map((e) => DetailItemSembako.fromJson(e))
          .toList(),
    );
  }
}
