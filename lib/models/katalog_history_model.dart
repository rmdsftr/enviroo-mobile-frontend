class KatalogHistoryModel {
  final int historySampahId;
  final String sampahId;
  final String levelUser;
  final double oldPoin;
  final double newPoin;
  final DateTime changedAt;
  final String changedBy;
  final String adminNama;

  KatalogHistoryModel({
    required this.historySampahId,
    required this.sampahId,
    required this.levelUser,
    required this.oldPoin,
    required this.newPoin,
    required this.changedAt,
    required this.changedBy,
    required this.adminNama,
  });

  factory KatalogHistoryModel.fromJson(Map<String, dynamic> json) {
    return KatalogHistoryModel(
      historySampahId: json['history_sampah_id'] ?? json['HistorySampahID'] ?? 0,
      sampahId: json['sampah_id'] ?? json['SampahID'] ?? '',
      levelUser: json['level_user'] ?? json['LevelUser'] ?? '',
      oldPoin: (json['old_poin'] as num?)?.toDouble() ?? (json['OldPoin'] as num?)?.toDouble() ?? 0.0,
      newPoin: (json['new_poin'] as num?)?.toDouble() ?? (json['NewPoin'] as num?)?.toDouble() ?? 0.0,
      changedAt: json['changed_at'] != null 
          ? DateTime.parse(json['changed_at']) 
          : (json['ChangedAt'] != null ? DateTime.parse(json['ChangedAt']) : DateTime.now()),
      changedBy: json['changed_by'] ?? json['ChangedBy'] ?? '',
      adminNama: json['admin_nama'] ?? '',
    );
  }
}
