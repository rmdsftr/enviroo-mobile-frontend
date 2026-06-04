import 'package:intl/intl.dart';

// ─── Riwayat item (satu entry perubahan status) ──────────────────────────────
class RiwayatSesiPengangkutanModel {
  final String status;
  final DateTime changedAt;
  final String changedBy;
  final String catatan;

  const RiwayatSesiPengangkutanModel({
    required this.status,
    required this.changedAt,
    required this.changedBy,
    required this.catatan,
  });

  factory RiwayatSesiPengangkutanModel.fromJson(Map<String, dynamic> j) {
    return RiwayatSesiPengangkutanModel(
      status: j['status'] as String? ?? '',
      changedAt: DateTime.tryParse(j['changed_at'] as String? ?? '') ?? DateTime.now(),
      changedBy: j['changed_by'] as String? ?? '-',
      catatan: j['catatan'] as String? ?? '',
    );
  }

  String get jamFormatted =>
      DateFormat('HH:mm', 'id_ID').format(changedAt);

  String get tanggalFormatted =>
      DateFormat('dd MMM yyyy', 'id_ID').format(changedAt);
}

// ─── Detail sesi aktif pengangkutan ─────────────────────────────────────────
class DetailSesiPengangkutanModel {
  final String pengangkutanId;
  final String bsiId;
  final String bsuId;
  final String namaBsi;
  final String namaBsu;
  final String statusTerkini;
  final String buktiFoto;
  final List<RiwayatSesiPengangkutanModel> riwayat;

  const DetailSesiPengangkutanModel({
    required this.pengangkutanId,
    required this.bsiId,
    required this.bsuId,
    required this.namaBsi,
    required this.namaBsu,
    required this.statusTerkini,
    this.buktiFoto = '',
    required this.riwayat,
  });

  factory DetailSesiPengangkutanModel.fromJson(Map<String, dynamic> j) =>
      DetailSesiPengangkutanModel(
        pengangkutanId: j['pengangkutan_id'] as String? ?? '',
        bsiId: j['bsi_id'] as String? ?? '',
        bsuId: j['bsu_id'] as String? ?? '',
        namaBsi: j['nama_bsi'] as String? ?? '-',
        namaBsu: j['nama_bsu'] as String? ?? '-',
        statusTerkini: j['status_terkini'] as String? ?? '',
        buktiFoto: j['bukti_foto'] as String? ?? '',
        riwayat: (j['riwayat'] as List<dynamic>? ?? [])
            .map((e) => RiwayatSesiPengangkutanModel.fromJson(
                e as Map<String, dynamic>))
            .toList(),
      );
}
