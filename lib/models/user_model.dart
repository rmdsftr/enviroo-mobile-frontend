class UserModel {
  final String userId;
  final String email;
  final String nama;
  final String role;       // finalRole dari backend (e.g. "nasabah", "petugas_bsi", etc.)
  final String? bankId;
  final String? identityId;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.userId,
    required this.email,
    required this.nama,
    required this.role,
    this.bankId,
    this.identityId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      nama: json['nama'] ?? '',
      role: json['role'] ?? '',
      bankId: json['bank_id'],
      identityId: json['identity_id'],
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
    );
  }
}
