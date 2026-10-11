import '../core/format/app_date.dart';

class SessionData {
  final String id;
  final String tanggal;
  final String waktu;
  final String fullTanggal;
  final int jumlahSetoran;
  final String status;
  final DateTime? rawDate;

  SessionData({
    required this.id,
    required this.tanggal,
    required this.waktu,
    required this.fullTanggal,
    required this.jumlahSetoran,
    required this.status,
    this.rawDate,
  });

  factory SessionData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    DateTime? rawDate;

    if (json['tanggal_sesi'] != null) {
      try {
        final parsed = DateTime.parse(json['tanggal_sesi']).toLocal();
        rawDate = parsed;
        tanggal = AppDate.tanggalPenuh(parsed);
      } catch (_) {
        tanggal = json['tanggal_sesi'].toString();
      }
    }

    final jumlahSetoran = (json['jumlah_setoran'] as num?)?.toInt() ?? 0;

    return SessionData(
      id: json['penimbangan_id'] ?? '',
      tanggal: tanggal,
      waktu: '$jumlahSetoran setoran',
      fullTanggal: tanggal,
      jumlahSetoran: jumlahSetoran,
      status: json['status_penimbangan'] ?? 'selesai',
      rawDate: rawDate,
    );
  }
}

class CheckActiveDetail {
  final String penimbanganId;
  final DateTime? tanggalSesi;
  final String jamMulai;
  final String jamSelesai;
  final String? namaJadwalSpesial;

  CheckActiveDetail({
    required this.penimbanganId,
    this.tanggalSesi,
    required this.jamMulai,
    required this.jamSelesai,
    this.namaJadwalSpesial,
  });

  factory CheckActiveDetail.fromJson(Map<String, dynamic> j) {
    DateTime? tanggalSesi;
    if (j['tanggal_sesi'] != null) {
      try {
        tanggalSesi = DateTime.parse(j['tanggal_sesi']).toLocal();
      } catch (_) {}
    }
    return CheckActiveDetail(
      penimbanganId: j['penimbangan_id'] ?? '',
      tanggalSesi: tanggalSesi,
      jamMulai: (j['jam_mulai'] ?? '').toString(),
      jamSelesai: (j['jam_selesai'] ?? '').toString(),
      namaJadwalSpesial: j['nama_jadwal_spesial'],
    );
  }

  String get tanggalFmt =>
      tanggalSesi != null ? AppDate.tanggalPenuh(tanggalSesi!) : '-';

  String get jamMulaiFmt => AppDate.jamDariString(jamMulai);

  String get jamSelesaiFmt => AppDate.jamDariString(jamSelesai);
}

class CheckActiveResult {
  final bool isActive;
  final CheckActiveDetail? detail;
  final int pendingSessions;

  CheckActiveResult({
    required this.isActive,
    this.detail,
    required this.pendingSessions,
  });

  factory CheckActiveResult.fromJson(Map<String, dynamic> j) {
    return CheckActiveResult(
      isActive: j['is_active'] == true,
      detail: j['detail'] != null ? CheckActiveDetail.fromJson(j['detail'] as Map<String, dynamic>) : null,
      pendingSessions: (j['pending_sessions'] as num?)?.toInt() ?? 0,
    );
  }
}

class SesiHariIniItem {
  final String penimbanganId;
  final DateTime? tanggalSesi;
  final String jamMulai;
  final String jamSelesai;
  final String? namaJadwalSpesial;
  final String statusPenimbangan;

  SesiHariIniItem({
    required this.penimbanganId,
    this.tanggalSesi,
    required this.jamMulai,
    required this.jamSelesai,
    this.namaJadwalSpesial,
    required this.statusPenimbangan,
  });

  factory SesiHariIniItem.fromJson(Map<String, dynamic> j) {
    DateTime? tanggalSesi;
    if (j['tanggal_sesi'] != null) {
      try {
        tanggalSesi = DateTime.parse(j['tanggal_sesi']).toLocal();
      } catch (_) {}
    }
    return SesiHariIniItem(
      penimbanganId: j['penimbangan_id'] ?? '',
      tanggalSesi: tanggalSesi,
      jamMulai: (j['jam_mulai'] ?? '').toString(),
      jamSelesai: (j['jam_selesai'] ?? '').toString(),
      namaJadwalSpesial: j['nama_jadwal_spesial'],
      statusPenimbangan: (j['status_penimbangan'] ?? 'pending').toString(),
    );
  }

  String get tanggalFmt =>
      tanggalSesi != null ? AppDate.tanggalPenuh(tanggalSesi!) : '-';

  String get jamMulaiFmt => AppDate.jamDariString(jamMulai);

  String get jamSelesaiFmt => AppDate.jamDariString(jamSelesai);
}

class PenimbanganSetoranItem {
  final String setoranId;
  final String nasabahId;
  final String namaNasabah;
  final String namaPetugas;
  final int totalItem;
  final DateTime createdAt;

  PenimbanganSetoranItem({
    required this.setoranId,
    required this.nasabahId,
    required this.namaNasabah,
    required this.namaPetugas,
    required this.totalItem,
    required this.createdAt,
  });

  factory PenimbanganSetoranItem.fromJson(Map<String, dynamic> j) {
    DateTime dt = DateTime.now();
    try {
      dt = DateTime.parse(j['transaksi_timestamp'] ?? '').toLocal();
    } catch (_) {}
    return PenimbanganSetoranItem(
      setoranId: j['setoran_id'] ?? '',
      nasabahId: j['nasabah_id'] ?? '',
      namaNasabah: j['nama_nasabah'] ?? '-',
      namaPetugas: j['nama_petugas'] ?? '-',
      totalItem: (j['total_item'] as num?)?.toInt() ?? 0,
      createdAt: dt,
    );
  }

  String get waktuFmt => AppDate.jam(createdAt);
}

class SesiPenimbanganAktif {
  final String penimbanganId;
  final String namaBank;
  final String startedAt;
  final String startedBy;
  final List<PenimbanganSetoranItem> listSetoran;

  SesiPenimbanganAktif({
    required this.penimbanganId,
    required this.namaBank,
    required this.startedAt,
    required this.startedBy,
    required this.listSetoran,
  });

  factory SesiPenimbanganAktif.fromJson(Map<String, dynamic> j) {
    String startedAt = '-';
    if (j['started_at'] != null) {
      try {
        final parsed = DateTime.parse(j['started_at']).toLocal();
        startedAt = AppDate.tanggalPenuhJam(parsed);
      } catch (_) {
        startedAt = j['started_at'].toString();
      }
    }

    final rawList = j['list_setoran'] as List? ?? [];
    final list = rawList
        .map((e) => PenimbanganSetoranItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return SesiPenimbanganAktif(
      penimbanganId: j['penimbangan_id'] ?? '',
      namaBank: j['nama_bank'] ?? '-',
      startedAt: startedAt,
      startedBy: j['started_by'] ?? '-',
      listSetoran: list,
    );
  }
}
