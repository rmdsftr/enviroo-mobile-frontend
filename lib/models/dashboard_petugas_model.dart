class DashboardPetugasModel {
  final String namaBank;
  final String photoBank;
  final String alamatBank;
  final String? namaBankPusat; // BSU
  final int jumlahNasabah; // BSU, BSI, BSM
  final int? jumlahStaff; // BSU, BSM
  final int? jumlahBsu; // BSI
  final double kasUang;
  final double kasEmas;

  DashboardPetugasModel({
    required this.namaBank,
    required this.photoBank,
    required this.alamatBank,
    this.namaBankPusat,
    required this.jumlahNasabah,
    this.jumlahStaff,
    this.jumlahBsu,
    this.kasUang = 0,
    this.kasEmas = 0,
  });

  factory DashboardPetugasModel.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    final kas = json['kas'] as Map<String, dynamic>?;

    return DashboardPetugasModel(
      namaBank: json['nama_bank'] ?? json['NamaBank'] ?? '',
      photoBank: json['photo_bank'] ?? json['PhotoBank'] ?? '',
      alamatBank: json['alamat_bank'] ?? json['AlamatBank'] ?? '',
      namaBankPusat: json['nama_bank_pusat'] ?? json['NamaBankPusat'],
      jumlahNasabah: json['jumlah_nasabah'] ?? json['JumlahNasabah'] ?? 0,
      jumlahStaff: json['jumlah_staff'] ?? json['JumlahStaff'],
      jumlahBsu: json['jumlah_bsu'] ?? json['JumlahBSU'],
      kasUang: kas != null ? _toDouble(kas['total_uang']) : 0,
      kasEmas: kas != null ? _toDouble(kas['total_emas']) : 0,
    );
  }
}
