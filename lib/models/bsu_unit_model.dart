class BsuUnitModel {
  final String bankId;
  final String namaBank;
  final String alamat;
  final String provinsi;
  final String kabupatenKota;
  final String kecamatan;
  final String photoUrl;
  final bool isActive;
  final int jumlahNasabah;

  BsuUnitModel({
    required this.bankId,
    required this.namaBank,
    required this.alamat,
    required this.provinsi,
    required this.kabupatenKota,
    required this.kecamatan,
    required this.photoUrl,
    required this.isActive,
    required this.jumlahNasabah,
  });

  /// JSON keys: Go serializes BankSampah struct fields as PascalCase (no json tags),
  /// except JumlahNasabah which has `json:"jumlah_nasabah"` tag.
  factory BsuUnitModel.fromJson(Map<String, dynamic> json) {
    return BsuUnitModel(
      bankId:        json['BankID']        ?? '',
      namaBank:      json['NamaBank']      ?? '-',
      alamat:        json['Alamat']        ?? '',
      provinsi:      json['Provinsi']      ?? '',
      kabupatenKota: json['KabupatenKota'] ?? '',
      kecamatan:     json['Kecamatan']     ?? '',
      photoUrl:      json['PhotoURL']      ?? '',
      isActive:      json['IsActive']      ?? true,
      jumlahNasabah: (json['jumlah_nasabah'] as num? ?? 0).toInt(),
    );
  }

  /// Status label untuk UI
  String get statusLabel => isActive ? 'Aktif' : 'Nonaktif';

  /// Alamat lengkap untuk ditampilkan di UI
  String get alamatLengkap {
    final parts = <String>[];
    if (kecamatan.isNotEmpty)     parts.add(kecamatan);
    if (kabupatenKota.isNotEmpty) parts.add(kabupatenKota);
    if (provinsi.isNotEmpty)      parts.add(provinsi);
    if (parts.isEmpty && alamat.isNotEmpty) return alamat;
    if (alamat.isNotEmpty) return '$alamat, ${parts.join(', ')}';
    return parts.join(', ');
  }
}
