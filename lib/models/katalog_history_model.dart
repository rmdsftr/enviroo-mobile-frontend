class KatalogHistoryModel {
  final int historyId;
  final int schemaId;
  final String levelUser;
  final double hargaLama;
  final double hargaBaru;
  final DateTime changedAt;
  final String changedByNama;

  KatalogHistoryModel({
    required this.historyId,
    required this.schemaId,
    required this.levelUser,
    required this.hargaLama,
    required this.hargaBaru,
    required this.changedAt,
    required this.changedByNama,
  });

  factory KatalogHistoryModel.fromJson(Map<String, dynamic> json) {
    return KatalogHistoryModel(
      historyId: json['history_id'] ?? 0,
      schemaId: json['schema_id'] ?? 0,
      levelUser: json['level_user'] ?? '',
      hargaLama: (json['harga_lama'] as num?)?.toDouble() ?? 0.0,
      hargaBaru: (json['harga_baru'] as num?)?.toDouble() ?? 0.0,
      changedAt: json['changed_at'] != null
          ? DateTime.parse(json['changed_at'])
          : DateTime.now(),
      changedByNama: json['changed_by_nama'] ?? '',
    );
  }
}
