class NasabahProfileModel {
  final String nasabahId;
  final String bankId;
  final String userId;
  final DateTime joinedAt;
  final String statusNasabah;
  final String nomorRekening;
  final String nama;
  final String email;
  final String noWhatsapp;
  final String foto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bsiId;
  final String? namaBsi;
  final String? bsuId;
  final String? namaBsu;
  final int saldoPoin;

  NasabahProfileModel({
    required this.nasabahId,
    required this.bankId,
    required this.userId,
    required this.joinedAt,
    required this.statusNasabah,
    required this.nomorRekening,
    required this.nama,
    required this.email,
    required this.noWhatsapp,
    required this.foto,
    required this.createdAt,
    required this.updatedAt,
    this.bsiId,
    this.namaBsi,
    this.bsuId,
    this.namaBsu,
    required this.saldoPoin,
  });

  factory NasabahProfileModel.fromJson(Map<String, dynamic> json) {
    return NasabahProfileModel(
      nasabahId: json['nasabah_id'] ?? '',
      bankId: json['bank_id'] ?? '',
      userId: json['user_id'] ?? '',
      joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
      statusNasabah: json['status_nasabah'] ?? '',
      nomorRekening: json['nomor_rekening'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      noWhatsapp: json['no_whatsapp'] ?? '',
      foto: json['foto'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      bsiId: json['bsi_id'],
      namaBsi: json['nama_bsi'],
      bsuId: json['bsu_id'],
      namaBsu: json['nama_bsu'],
      saldoPoin: json['saldo_poin'] ?? 0,
    );
  }
}
