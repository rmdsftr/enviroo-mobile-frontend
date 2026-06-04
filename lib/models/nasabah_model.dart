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
    // Flat format: nama/email/foto/status at top level (new API)
    // Nested format: User object (old API)
    final bool isFlat = json.containsKey('nama') || json.containsKey('foto');
    final NasabahUser user = isFlat
        ? NasabahUser(
            userId: '',
            nama: json['nama'] ?? '',
            email: json['email'] ?? '',
            noWhatsapp: '',
            photoUrl: json['foto'] ?? '',
          )
        : NasabahUser.fromJson(json['User'] ?? json['user'] ?? {});

    return NasabahModel(
      nasabahId: json['NasabahID'] ?? json['nasabah_id'] ?? '',
      bankId: json['BankID'] ?? json['bank_id'] ?? '',
      userId: json['UserID'] ?? json['user_id'] ?? '',
      joinedAt: json['JoinedAt'] != null || json['joined_at'] != null
          ? DateTime.parse(json['JoinedAt'] ?? json['joined_at'])
          : DateTime.now(),
      nomorRekening: json['NomorRekening'] ?? json['nomor_rekening'] ?? '',
      statusNasabah: json['StatusNasabah'] ?? json['status_nasabah'] ?? json['status'] ?? '',
      user: user,
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
