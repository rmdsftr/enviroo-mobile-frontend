class NotifikasiModel {
  final String id;
  final String judul;
  final String pesan;
  final String? refId;
  final String? refType;
  final bool isRead;
  final String createdAt;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    this.refId,
    this.refType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['notifikasi_id']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      pesan: json['pesan']?.toString() ?? '',
      refId: json['ref_id']?.toString(),
      refType: json['ref_type']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  NotifikasiModel copyWith({bool? isRead}) {
    return NotifikasiModel(
      id: id,
      judul: judul,
      pesan: pesan,
      refId: refId,
      refType: refType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
