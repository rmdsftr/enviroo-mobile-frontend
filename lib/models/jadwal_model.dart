const _dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

class JadwalRutin {
  final List<int> days;
  final List<int> weeks;
  final String waktu;
  final String targetBankName;

  JadwalRutin({
    required this.days,
    required this.weeks,
    required this.waktu,
    this.targetBankName = '',
  });

  String get label {
    final dayStr = days.map((d) => _dayNames[d - 1]).join(', ');
    final weekStr = weeks.isEmpty
        ? 'tiap minggunya'
        : weeks.map((w) => 'minggu ke-$w').join(' & ');
    return 'Setiap hari $dayStr $weekStr';
  }

  List<DateTime> datesInMonth(int year, int month) {
    final result = <DateTime>[];
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstOfMonth.weekday % 7;

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      final weekday = date.weekday;
      final adjustedDay = d + firstWeekday - 1;
      final weekNum = (adjustedDay ~/ 7) + 1;

      if (days.contains(weekday)) {
        if (weeks.isEmpty || weeks.contains(weekNum)) {
          result.add(date);
        }
      }
    }
    return result;
  }
}

class JadwalCustom {
  final DateTime tanggal;
  final String waktu;
  final String? pesan;

  JadwalCustom({required this.tanggal, required this.waktu, this.pesan});
}

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

// ── Jadwal Penimbangan (endpoint GET /jadwal/penimbangan/:bank_id) ──────────
// Dipakai khusus JadwalScreen role petugas_bsm.
class JadwalPenimbanganItem {
  final String jadwalId;
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String namaJadwal;
  final bool isRutin;
  final bool isActive;
  final String statusJadwal;

  JadwalPenimbanganItem({
    required this.jadwalId,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.namaJadwal,
    required this.isRutin,
    required this.isActive,
    required this.statusJadwal,
  });

  factory JadwalPenimbanganItem.fromJson(Map<String, dynamic> json) {
    return JadwalPenimbanganItem(
      jadwalId: json['jadwal_id']?.toString() ?? '',
      tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? '') ?? DateTime.now(),
      jamMulai: json['jam_mulai']?.toString() ?? '',
      jamSelesai: json['jam_selesai']?.toString() ?? '',
      namaJadwal: json['nama_jadwal']?.toString() ?? '',
      isRutin: json['is_rutin'] == true,
      isActive: json['is_active'] == true,
      statusJadwal: json['status_jadwal']?.toString() ?? '',
    );
  }

  String get formattedJam {
    String mulai = jamMulai.length >= 5 ? jamMulai.substring(0, 5) : jamMulai;
    String selesai = jamSelesai.length >= 5 ? jamSelesai.substring(0, 5) : jamSelesai;
    return '$mulai - $selesai';
  }
}
