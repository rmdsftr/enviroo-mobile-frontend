class JadwalModel {
  final String jadwalId;
  final String bankId;
  final String hari;
  final int mingguKe;
  final String jamMulai;
  final String jamSelesai;
  final String jenisJadwal;
  final String targetBankId;
  final bool isActive;
  final bool isRutin;
  final DateTime? tanggal;
  final String namaJadwalSpesial;
  final String bankName;
  final String targetBankName;

  JadwalModel({
    required this.jadwalId,
    required this.bankId,
    required this.hari,
    required this.mingguKe,
    required this.jamMulai,
    required this.jamSelesai,
    required this.jenisJadwal,
    required this.targetBankId,
    required this.isActive,
    required this.isRutin,
    this.tanggal,
    required this.namaJadwalSpesial,
    required this.bankName,
    required this.targetBankName,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      jadwalId: json['jadwal_id'] ?? '',
      bankId: json['bank_id'] ?? '',
      hari: json['hari'] ?? '',
      mingguKe: json['minggu_ke'] ?? 0,
      jamMulai: json['jam_mulai'] ?? '',
      jamSelesai: json['jam_selesai'] ?? '',
      jenisJadwal: json['jenis_jadwal'] ?? '',
      targetBankId: json['target_bank_id'] ?? '',
      isActive: json['is_active'] ?? true,
      isRutin: json['is_rutin'] ?? true,
      tanggal: json['tanggal'] != null && json['tanggal'] != "0001-01-01T00:00:00Z" 
          ? DateTime.tryParse(json['tanggal']) 
          : null,
      namaJadwalSpesial: json['nama_jadwal_spesial'] ?? '',
      bankName: json['bank_name'] ?? '',
      targetBankName: json['target_bank_name'] ?? '',
    );
  }

  int get dayIndex {
    switch (hari.toLowerCase()) {
      case 'senin': return 1;
      case 'selasa': return 2;
      case 'rabu': return 3;
      case 'kamis': return 4;
      case 'jumat': return 5;
      case 'sabtu': return 6;
      case 'minggu': return 7;
      default: return 1;
    }
  }

  String get formattedWaktu {
    String mulai = jamMulai.length >= 5 ? jamMulai.substring(0, 5) : jamMulai;
    String selesai = jamSelesai.length >= 5 ? jamSelesai.substring(0, 5) : jamSelesai;
    return '$mulai - $selesai';
  }
}
