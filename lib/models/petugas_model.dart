class PetugasModel {
  final String adminId;
  final String role;
  final String statusAdmin;
  final String userId;
  final String nama;
  final String email;
  final String photoUrl;
  final String bankId;
  final String namaBank;
  final String jenisBank;

  PetugasModel({
    required this.adminId,
    required this.role,
    required this.statusAdmin,
    required this.userId,
    required this.nama,
    required this.email,
    required this.photoUrl,
    required this.bankId,
    required this.namaBank,
    required this.jenisBank,
  });

  factory PetugasModel.fromJson(Map<String, dynamic> json) {
    return PetugasModel(
      adminId: json['admin_id'] ?? '',
      role: json['role'] ?? '',
      statusAdmin: json['status_admin'] ?? '',
      userId: json['user_id'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      jenisBank: json['jenis_bank'] ?? '',
    );
  }
}
