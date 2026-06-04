class AdminBankModel {
  final String adminId;
  final String namaAdmin;
  final String photoUrl;
  final String roleAdmin;

  AdminBankModel({
    required this.adminId,
    required this.namaAdmin,
    required this.photoUrl,
    required this.roleAdmin,
  });

  factory AdminBankModel.fromJson(Map<String, dynamic> json) {
    return AdminBankModel(
      adminId: json['admin_id'] ?? '',
      namaAdmin: json['nama_admin'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      roleAdmin: json['role_admin'] ?? '',
    );
  }
}

class DetailBankModel {
  final String bankId;
  final String namaBank;
  final String photoUrl;
  final bool isBsu;
  final String bankIndukNama;
  final String jenisBank;
  final String alamat;
  final String provinsi;
  final String kabupatenKota;
  final String kecamatan;
  final String kelurahan;
  final String deskripsi;
  final bool isActive;
  final DateTime? joinedAt;
  final List<AdminBankModel> admins;

  DetailBankModel({
    required this.bankId,
    required this.namaBank,
    required this.photoUrl,
    required this.isBsu,
    required this.bankIndukNama,
    required this.jenisBank,
    required this.alamat,
    required this.provinsi,
    required this.kabupatenKota,
    required this.kecamatan,
    required this.kelurahan,
    required this.deskripsi,
    required this.isActive,
    required this.joinedAt,
    required this.admins,
  });

  factory DetailBankModel.fromJson(Map<String, dynamic> json) {
    final adminsList = (json['admins'] as List? ?? [])
        .map((e) => AdminBankModel.fromJson(e as Map<String, dynamic>))
        .toList();

    DateTime? joinedAt;
    if (json['joined_at'] != null) {
      try {
        joinedAt = DateTime.parse(json['joined_at'].toString());
      } catch (_) {}
    }

    return DetailBankModel(
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      isBsu: json['is_bsu'] == true,
      bankIndukNama: json['bank_induk_nama'] ?? '',
      jenisBank: json['jenis_bank'] ?? '',
      alamat: json['alamat'] ?? '',
      provinsi: json['provinsi'] ?? '',
      kabupatenKota: json['kabupaten_kota'] ?? '',
      kecamatan: json['kecamatan'] ?? '',
      kelurahan: json['kelurahan'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      isActive: json['is_active'] == true,
      joinedAt: joinedAt,
      admins: adminsList,
    );
  }

  String get wilayah {
    final parts = <String>[
      if (kecamatan.isNotEmpty) 'Kec. $kecamatan',
      if (kelurahan.isNotEmpty) 'Kel. $kelurahan',
      if (kabupatenKota.isNotEmpty) kabupatenKota,
      if (provinsi.isNotEmpty) provinsi,
    ];
    return parts.join(', ');
  }
}
