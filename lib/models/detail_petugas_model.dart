class DetailPetugasModel {
  final String petugasId;
  final String userId;
  final String nama;
  final String email;
  final String noWhatsapp;
  final String photoUrl;
  final String statusPetugas;
  final String rolePetugas;
  final DateTime? joinedAt;
  final String bankId;
  final String namaBank;
  final bool isNasabah;
  final String nasabahId;
  final String namaBankNasabah;

  DetailPetugasModel({
    required this.petugasId,
    required this.userId,
    required this.nama,
    required this.email,
    required this.noWhatsapp,
    required this.photoUrl,
    required this.statusPetugas,
    required this.rolePetugas,
    required this.joinedAt,
    required this.bankId,
    required this.namaBank,
    required this.isNasabah,
    required this.nasabahId,
    required this.namaBankNasabah,
  });

  factory DetailPetugasModel.fromJson(Map<String, dynamic> json) {
    DateTime? joinedAt;
    if (json['joined_at'] != null) {
      try {
        joinedAt = DateTime.parse(json['joined_at'].toString());
      } catch (_) {}
    }

    return DetailPetugasModel(
      petugasId: json['petugas_id'] ?? '',
      userId: json['user_id'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      noWhatsapp: json['no_whatsapp'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      statusPetugas: json['status_petugas'] ?? '',
      rolePetugas: json['role_petugas'] ?? '',
      joinedAt: joinedAt,
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      isNasabah: json['is_nasabah'] == true,
      nasabahId: json['nasabah_id'] ?? '',
      namaBankNasabah: json['nama_bank_nasabah'] ?? '',
    );
  }
}
