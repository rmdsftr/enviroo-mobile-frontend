import 'package:intl/intl.dart';

class PengangkutanBsuData {
  final String id;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsu;
  final String status;
  final String tanggal;
  final DateTime? rawDate;

  PengangkutanBsuData({
    required this.id,
    required this.namaBsi,
    required this.namaBsu,
    required this.namaAdminBsu,
    required this.status,
    required this.tanggal,
    this.rawDate,
  });

  factory PengangkutanBsuData.fromJson(Map<String, dynamic> json) {
    String tanggal = '-';
    DateTime? rawDate;
    if (json['changed_at'] != null) {
      try {
        final parsed = DateTime.parse(json['changed_at'].toString()).toLocal();
        rawDate = parsed;
        tanggal = DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(parsed);
      } catch (_) {
        tanggal = json['changed_at'].toString();
      }
    }
    return PengangkutanBsuData(
      id: json['pengangkutan_id'] ?? '',
      namaBsi: json['nama_bsi'] as String? ?? '-',
      namaBsu: json['nama_bsu'] as String? ?? '-',
      namaAdminBsu: json['nama_admin_bsu'] as String? ?? '-',
      status: json['status_pengangkutan'] ?? '',
      tanggal: tanggal,
      rawDate: rawDate,
    );
  }
}

class SesiActiveData {
  final bool isActive;
  final String pengangkutanId;
  final String bsiId;
  final String namaBsi;
  final String statusTerkini;

  const SesiActiveData({
    required this.isActive,
    required this.pengangkutanId,
    required this.bsiId,
    required this.namaBsi,
    required this.statusTerkini,
  });

  factory SesiActiveData.fromJson(Map<String, dynamic> j) => SesiActiveData(
        isActive: j['is_active'] as bool? ?? false,
        pengangkutanId: j['pengangkutan_id'] as String? ?? '',
        bsiId: j['bsi_id'] as String? ?? '',
        namaBsi: j['nama_bsi'] as String? ?? '-',
        statusTerkini: j['status_terkini'] as String? ?? '',
      );
}
