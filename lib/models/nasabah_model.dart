class NasabahModel {
  final String nasabahId;
  final String bankId;
  final String userId;
  final DateTime joinedAt;
  final String nomorRekening;
  final String statusNasabah;
  final NasabahUser user;

  NasabahModel({
    required this.nasabahId,
    required this.bankId,
    required this.userId,
    required this.joinedAt,
    required this.nomorRekening,
    required this.statusNasabah,
    required this.user,
  });

  factory NasabahModel.fromJson(Map<String, dynamic> json) {
    return NasabahModel(
      nasabahId: json['NasabahID'] ?? json['nasabah_id'] ?? '',
      bankId: json['BankID'] ?? json['bank_id'] ?? '',
      userId: json['UserID'] ?? json['user_id'] ?? '',
      joinedAt: DateTime.parse(json['JoinedAt'] ?? json['joined_at'] ?? DateTime.now().toIso8601String()),
      nomorRekening: json['NomorRekening'] ?? json['nomor_rekening'] ?? '',
      statusNasabah: json['StatusNasabah'] ?? json['status_nasabah'] ?? '',
      user: NasabahUser.fromJson(json['User'] ?? json['user'] ?? {}),
    );
  }
}

class NasabahUser {
  final String userId;
  final String nama;
  final String email;
  final String noWhatsapp;
  final String photoUrl;

  NasabahUser({
    required this.userId,
    required this.nama,
    required this.email,
    required this.noWhatsapp,
    required this.photoUrl,
  });

  factory NasabahUser.fromJson(Map<String, dynamic> json) {
    return NasabahUser(
      userId: json['UserID'] ?? json['user_id'] ?? '',
      nama: json['Nama'] ?? json['nama'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      noWhatsapp: json['NoWhatsapp'] ?? json['no_whatsapp'] ?? '',
      photoUrl: json['PhotoURL'] ?? json['photo_url'] ?? '',
    );
  }
}
