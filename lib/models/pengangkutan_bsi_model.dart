import 'package:intl/intl.dart';

class PengangkutanData {
  final String id;
  final String bsiId;
  final String bsuId;
  final String namaBsu;
  final String namaBsi;
  final String namaAdminBsi;
  final String namaAdminBsu;
  final String adminBsuId;
  final String status;
  final String tanggal;
  final DateTime? rawDate;

  PengangkutanData({
    required this.id,
    required this.bsiId,
    required this.bsuId,
    required this.namaBsu,
    required this.namaBsi,
    required this.namaAdminBsi,
    required this.namaAdminBsu,
    required this.adminBsuId,
    required this.status,
    required this.tanggal,
    this.rawDate,
  });

  factory PengangkutanData.fromJson(Map<String, dynamic> json) {
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
    return PengangkutanData(
      id: json['pengangkutan_id'] ?? '',
      bsiId: json['bsi_id'] ?? '',
      bsuId: json['bsu_id'] ?? '',
      namaBsu: json['nama_bsu'] ?? '-',
      namaBsi: json['nama_bsi'] ?? '-',
      namaAdminBsi: json['nama_admin_bsi'] ?? '-',
      namaAdminBsu: json['nama_admin_bsu'] ?? '-',
      adminBsuId: json['admin_bsu_id'] ?? '',
      status: json['status_pengangkutan'] ?? '',
      tanggal: tanggal,
      rawDate: rawDate,
    );
  }
}

class PengangkutanAktifBsiData {
  final String pengangkutanId;
  final String bsuId;
  final String namaBsu;
  final String statusTerkini;
  final bool isActionAllowed;

  const PengangkutanAktifBsiData({
    required this.pengangkutanId,
    required this.bsuId,
    required this.namaBsu,
    required this.statusTerkini,
    required this.isActionAllowed,
  });

  factory PengangkutanAktifBsiData.fromJson(Map<String, dynamic> json) =>
      PengangkutanAktifBsiData(
        pengangkutanId: json['pengangkutan_id'] as String? ?? '',
        bsuId: json['bsu_id'] as String? ?? '',
        namaBsu: json['nama_bsu'] as String? ?? '-',
        statusTerkini: json['status_terkini'] as String? ?? '',
        isActionAllowed: json['is_action_allowed'] as bool? ?? false,
      );
}

class BsuUnit {
  final String bankId;
  final String namaBank;

  BsuUnit({required this.bankId, required this.namaBank});

  factory BsuUnit.fromJson(Map<String, dynamic> json) => BsuUnit(
        bankId: json['bank_id'] ?? json['BankID'] ?? '',
        namaBank: json['nama_bank'] ?? json['NamaBank'] ?? '-',
      );
}

class JadwalHariIniItem {
  final String bsuId;
  final String namaBsu;
  final String jadwalId;
  final String namaJadwalSpesial;
  final bool isCompleted;

  JadwalHariIniItem({
    required this.bsuId,
    required this.namaBsu,
    required this.jadwalId,
    required this.namaJadwalSpesial,
    required this.isCompleted,
  });

  factory JadwalHariIniItem.fromJson(Map<String, dynamic> json) =>
      JadwalHariIniItem(
        bsuId: json['bsu_id'] as String? ?? '',
        namaBsu: json['nama_bsu'] as String? ?? '',
        jadwalId: json['jadwal_id'] as String? ?? '',
        namaJadwalSpesial: json['nama_jadwal_spesial'] as String? ?? '',
        isCompleted: json['is_completed'] as bool? ?? false,
      );
}

class PengangkutanHeader {
  final String pengangkutanId;
  final String namaBsi;
  final String namaBsu;
  final String namaAdminBsi;
  final String namaAdminBsu;
  final double totalItem;
  final bool isMandiri;
  final String statusTerkini;
  final String? buktiFoto;

  PengangkutanHeader({
    required this.pengangkutanId,
    required this.namaBsi,
    required this.namaBsu,
    required this.namaAdminBsi,
    required this.namaAdminBsu,
    required this.totalItem,
    required this.isMandiri,
    required this.statusTerkini,
    this.buktiFoto,
  });

  factory PengangkutanHeader.fromJson(Map<String, dynamic> json) =>
      PengangkutanHeader(
        pengangkutanId: json['pengangkutan_id'] as String? ?? '',
        namaBsi: json['nama_bsi'] as String? ?? '-',
        namaBsu: json['nama_bsu'] as String? ?? '-',
        namaAdminBsi: json['nama_admin_bsi'] as String? ?? '-',
        namaAdminBsu: json['nama_admin_bsu'] as String? ?? '-',
        totalItem: (json['total_item'] as num?)?.toDouble() ?? 0,
        isMandiri: json['is_mandiri'] as bool? ?? false,
        statusTerkini: json['status_terkini'] as String? ?? '',
        buktiFoto: json['bukti_foto'] as String?,
      );
}

class PengangkutanItem {
  final String namaSampah;
  final String satuan;
  final double qty;

  PengangkutanItem({
    required this.namaSampah,
    required this.satuan,
    required this.qty,
  });

  factory PengangkutanItem.fromJson(Map<String, dynamic> json) =>
      PengangkutanItem(
        namaSampah: json['nama_sampah'] ?? '-',
        satuan: json['satuan'] ?? '-',
        qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      );
}

class PreviewItemPengangkutan {
  final String sampahId;
  final String namaSampah;
  final String namaReward;
  final double qty;
  final double stokBsuSebelum;
  final double stokBsuSetelah;
  final double stokBsiSebelum;
  final double stokBsiSetelah;
  final bool cukupUntukKirim;

  PreviewItemPengangkutan({
    required this.sampahId,
    required this.namaSampah,
    required this.namaReward,
    required this.qty,
    required this.stokBsuSebelum,
    required this.stokBsuSetelah,
    required this.stokBsiSebelum,
    required this.stokBsiSetelah,
    required this.cukupUntukKirim,
  });

  factory PreviewItemPengangkutan.fromJson(Map<String, dynamic> json) =>
      PreviewItemPengangkutan(
        sampahId: json['sampah_id'] ?? '',
        namaSampah: json['nama_sampah'] ?? '-',
        namaReward: json['nama_reward'] ?? '',
        qty: (json['qty'] as num? ?? 0).toDouble(),
        stokBsuSebelum: (json['stok_bsu_sebelum'] as num? ?? 0).toDouble(),
        stokBsuSetelah: (json['stok_bsu_setelah'] as num? ?? 0).toDouble(),
        stokBsiSebelum: (json['stok_bsi_sebelum'] as num? ?? 0).toDouble(),
        stokBsiSetelah: (json['stok_bsi_setelah'] as num? ?? 0).toDouble(),
        cukupUntukKirim: json['cukup_untuk_kirim'] as bool? ?? true,
      );
}

class PreviewPengangkutanData {
  final String pengangkutanId;
  final String bsiId;
  final String namaBsi;
  final String bsuId;
  final String namaBsu;
  final int totalItem;
  final bool adaStokKurang;
  final List<PreviewItemPengangkutan> items;

  PreviewPengangkutanData({
    required this.pengangkutanId,
    required this.bsiId,
    required this.namaBsi,
    required this.bsuId,
    required this.namaBsu,
    required this.totalItem,
    required this.adaStokKurang,
    required this.items,
  });

  factory PreviewPengangkutanData.fromJson(Map<String, dynamic> json) =>
      PreviewPengangkutanData(
        pengangkutanId: json['pengangkutan_id'] ?? '',
        bsiId: json['bsi_id'] ?? '',
        namaBsi: json['nama_bsi'] ?? '-',
        bsuId: json['bsu_id'] ?? '',
        namaBsu: json['nama_bsu'] ?? '-',
        totalItem: (json['total_item'] as num? ?? 0).toInt(),
        adaStokKurang: json['ada_stok_kurang'] as bool? ?? false,
        items: (json['items'] as List? ?? [])
            .map((e) =>
                PreviewItemPengangkutan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SampahPengangkutan {
  final String sampahId;
  final String namaSampah;
  final String fotoSampah;
  final String satuan;
  final String namaReward;
  final double stok;

  SampahPengangkutan({
    required this.sampahId,
    required this.namaSampah,
    required this.fotoSampah,
    required this.satuan,
    required this.namaReward,
    required this.stok,
  });

  factory SampahPengangkutan.fromJson(Map<String, dynamic> json) =>
      SampahPengangkutan(
        sampahId: json['sampah_id'] ?? '',
        namaSampah: json['nama_sampah'] ?? '-',
        fotoSampah: json['foto_sampah'] ?? '',
        satuan: json['satuan'] ?? '-',
        namaReward: json['nama_reward'] ?? '',
        stok: (json['stok'] as num? ?? 0).toDouble(),
      );
}
