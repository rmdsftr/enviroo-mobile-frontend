class BsuPreviewItem {
  final String bankId;
  final String namaBank;
  final double persenKontribusi;
  final double pokok;
  final double transportasi;
  final double nominal;

  BsuPreviewItem({
    required this.bankId,
    required this.namaBank,
    required this.persenKontribusi,
    required this.pokok,
    required this.transportasi,
    required this.nominal,
  });

  factory BsuPreviewItem.fromJson(Map<String, dynamic> json) => BsuPreviewItem(
        bankId: json['bank_id'] ?? '',
        namaBank: json['nama_bank'] ?? '',
        persenKontribusi: (json['persen_kontribusi'] ?? 0).toDouble(),
        pokok: (json['pokok'] ?? 0).toDouble(),
        transportasi: (json['transportasi'] ?? 0).toDouble(),
        nominal: (json['nominal'] ?? 0).toDouble(),
      );
}

class PreviewDistribusiSisaModel {
  final String bagiHasilId;
  final double totalSisa;
  final String satuan;
  final double nominalBsi;
  final List<BsuPreviewItem> penerimaBsu;

  PreviewDistribusiSisaModel({
    required this.bagiHasilId,
    required this.totalSisa,
    required this.satuan,
    required this.nominalBsi,
    required this.penerimaBsu,
  });

  factory PreviewDistribusiSisaModel.fromJson(Map<String, dynamic> json) =>
      PreviewDistribusiSisaModel(
        bagiHasilId: json['bagi_hasil_id'] ?? '',
        totalSisa: (json['total_sisa'] ?? 0).toDouble(),
        satuan: json['satuan']?.toString() ?? '',
        nominalBsi: (json['nominal_bsi'] ?? 0).toDouble(),
        penerimaBsu: (json['penerima_bsu'] as List? ?? [])
            .map((e) => BsuPreviewItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TransportDetailItem {
  final String bsuId;
  final String namaBsu;
  final double transport;

  TransportDetailItem({
    required this.bsuId,
    required this.namaBsu,
    required this.transport,
  });

  factory TransportDetailItem.fromJson(Map<String, dynamic> json) =>
      TransportDetailItem(
        bsuId: json['bsu_id'] ?? '',
        namaBsu: json['nama_bsu'] ?? '',
        transport: (json['transport'] ?? 0).toDouble(),
      );
}

class PenerimaDistribusiSisaItem {
  final String penerimaSisaId;
  final String bankId;
  final String namaBank;
  final double nominalDiterima;
  final double porsi;
  final double transportasi;
  final String satuanNominal;
  final String? diantarOleh;
  final List<TransportDetailItem> transportDetail;

  PenerimaDistribusiSisaItem({
    required this.penerimaSisaId,
    required this.bankId,
    required this.namaBank,
    required this.nominalDiterima,
    required this.porsi,
    required this.transportasi,
    required this.satuanNominal,
    this.diantarOleh,
    this.transportDetail = const [],
  });

  factory PenerimaDistribusiSisaItem.fromJson(Map<String, dynamic> json) =>
      PenerimaDistribusiSisaItem(
        penerimaSisaId: json['penerima_sisa_id'] ?? '',
        bankId: json['bank_id'] ?? '',
        namaBank: json['nama_bank'] ?? '',
        nominalDiterima: (json['nominal_diterima'] ?? 0).toDouble(),
        porsi: (json['porsi'] ?? 0).toDouble(),
        transportasi: (json['transportasi'] ?? 0).toDouble(),
        satuanNominal: json['satuan_nominal'] ?? '',
        diantarOleh: json['diantar_oleh']?.toString(),
        transportDetail: (json['transport_detail'] as List? ?? [])
            .map((e) => TransportDetailItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DetailDistribusiSisaModel {
  final String distribusiId;
  final String bagiHasilId;
  final double totalSisa;
  final String satuan;
  final String createdAt;
  final String createdBy;
  final PenerimaDistribusiSisaItem? penerimaBsi;
  final List<PenerimaDistribusiSisaItem> penerimaBsu;

  DetailDistribusiSisaModel({
    required this.distribusiId,
    required this.bagiHasilId,
    required this.totalSisa,
    required this.satuan,
    required this.createdAt,
    required this.createdBy,
    this.penerimaBsi,
    required this.penerimaBsu,
  });

  factory DetailDistribusiSisaModel.fromJson(Map<String, dynamic> json) =>
      DetailDistribusiSisaModel(
        distribusiId: json['distribusi_id'] ?? '',
        bagiHasilId: json['bagi_hasil_id'] ?? '',
        totalSisa: (json['total_sisa'] ?? 0).toDouble(),
        satuan: json['satuan']?.toString() ?? '',
        createdAt: json['created_at'] ?? '',
        createdBy: json['created_by'] ?? '',
        penerimaBsi: json['penerima_bsi'] != null
            ? PenerimaDistribusiSisaItem.fromJson(
                json['penerima_bsi'] as Map<String, dynamic>)
            : null,
        penerimaBsu: (json['penerima_bsu'] as List? ?? [])
            .map((e) =>
                PenerimaDistribusiSisaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
