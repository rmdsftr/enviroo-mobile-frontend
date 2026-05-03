class JadwalPenimbangan {
  final String hari;
  final int mingguKe;
  final String jamMulai;
  final String jamSelesai;

  JadwalPenimbangan({
    required this.hari,
    required this.mingguKe,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory JadwalPenimbangan.fromJson(Map<String, dynamic> json) {
    return JadwalPenimbangan(
      hari: json['hari'] ?? '',
      mingguKe: json['minggu_ke'] ?? 0,
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
    );
  }
}

class BankSampahModel {
  final String bankId;
  final String namaBank;
  final String alamatBank;
  final String kecamatan;
  final String kabupatenKota;
  final String provinsi;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final List<JadwalPenimbangan> jadwalPenimbangan;

  BankSampahModel({
    required this.bankId,
    required this.namaBank,
    required this.alamatBank,
    required this.kecamatan,
    required this.kabupatenKota,
    required this.provinsi,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.jadwalPenimbangan,
  });

  factory BankSampahModel.fromJson(Map<String, dynamic> json) {
    var jadwalList = json['jadwal_penimbangan'] as List? ?? [];
    List<JadwalPenimbangan> jadwal = jadwalList
        .map((e) => JadwalPenimbangan.fromJson(e as Map<String, dynamic>))
        .toList();

    return BankSampahModel(
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      alamatBank: json['alamat_bank'] ?? '',
      kecamatan: json['kecamatan'] ?? '',
      kabupatenKota: json['kabupaten_kota'] ?? '',
      provinsi: json['provinsi'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      jadwalPenimbangan: jadwal,
    );
  }

  String get alamatLengkap {
    final parts = <String>[];
    if (kecamatan.isNotEmpty) parts.add(kecamatan);
    if (kabupatenKota.isNotEmpty) parts.add(kabupatenKota);
    if (provinsi.isNotEmpty) parts.add(provinsi);
    
    if (parts.isEmpty && alamatBank.isNotEmpty) return alamatBank;
    if (alamatBank.isNotEmpty) return '$alamatBank, ${parts.join(', ')}';
    return parts.join(', ');
  }
}
