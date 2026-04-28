class DashboardPetugasModel {
  final String namaBank;
  final String photoBank;
  final String alamatBank;
  final String? namaBankPusat; // BSU
  final int jumlahNasabah; // BSU, BSI, BSM
  final int? jumlahStaff; // BSU, BSM
  final int? jumlahBsu; // BSI

  DashboardPetugasModel({
    required this.namaBank,
    required this.photoBank,
    required this.alamatBank,
    this.namaBankPusat,
    required this.jumlahNasabah,
    this.jumlahStaff,
    this.jumlahBsu,
  });

  factory DashboardPetugasModel.fromJson(Map<String, dynamic> json) {
    return DashboardPetugasModel(
      namaBank: json['nama_bank'] ?? json['NamaBank'] ?? '',
      photoBank: json['photo_bank'] ?? json['PhotoBank'] ?? '',
      alamatBank: json['alamat_bank'] ?? json['AlamatBank'] ?? '',
      namaBankPusat: json['nama_bank_pusat'] ?? json['NamaBankPusat'],
      jumlahNasabah: json['jumlah_nasabah'] ?? json['JumlahNasabah'] ?? 0,
      jumlahStaff: json['jumlah_staff'] ?? json['JumlahStaff'],
      jumlahBsu: json['jumlah_bsu'] ?? json['JumlahBSU'],
    );
  }
}
