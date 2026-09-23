class BankSampahModel {
  final String bankId;
  final String namaBank;
  final String alamatBank;
  final String kelurahan;
  final String kecamatan;
  final String kabupatenKota;
  final String provinsi;
  final String jenisBank;
  final String photoUrl;
  final double latitude;
  final double longitude;

  BankSampahModel({
    required this.bankId,
    required this.namaBank,
    required this.alamatBank,
    required this.kelurahan,
    required this.kecamatan,
    required this.kabupatenKota,
    required this.provinsi,
    required this.jenisBank,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
  });

  factory BankSampahModel.fromJson(Map<String, dynamic> json) {
    return BankSampahModel(
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      alamatBank: json['alamat_bank'] ?? '',
      kelurahan: json['kelurahan'] ?? '',
      kecamatan: json['kecamatan'] ?? '',
      kabupatenKota: json['kabupaten_kota'] ?? '',
      provinsi: json['provinsi'] ?? '',
      jenisBank: json['jenis_bank'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
