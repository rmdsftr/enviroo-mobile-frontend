class BsuPreviewItem {
  final String bankId;
  final String namaBank;
  final double totalKontribusiNasabah;
  final double kontribusiPersen;

  BsuPreviewItem({
    required this.bankId,
    required this.namaBank,
    required this.totalKontribusiNasabah,
    required this.kontribusiPersen,
  });

  factory BsuPreviewItem.fromJson(Map<String, dynamic> json) => BsuPreviewItem(
        bankId: json['bank_id'] ?? '',
        namaBank: json['nama_bank'] ?? '',
        totalKontribusiNasabah:
            (json['total_kontribusi_nasabah'] ?? 0).toDouble(),
        kontribusiPersen: (json['kontribusi_persen'] ?? 0).toDouble(),
      );
}

class PreviewDistribusiSisaModel {
  final String bagiHasilId;
  final double totalSisa;
  final String satuan;
  final double porsiBsi;
  final double porsiBsu;
  final double porsiTransport;
  final List<BsuPreviewItem> bsuTerlibat;

  PreviewDistribusiSisaModel({
    required this.bagiHasilId,
    required this.totalSisa,
    required this.satuan,
    required this.porsiBsi,
    required this.porsiBsu,
    required this.porsiTransport,
    required this.bsuTerlibat,
  });

  factory PreviewDistribusiSisaModel.fromJson(Map<String, dynamic> json) =>
      PreviewDistribusiSisaModel(
        bagiHasilId: json['bagi_hasil_id'] ?? '',
        totalSisa: (json['total_sisa'] ?? 0).toDouble(),
        satuan: json['satuan']?.toString() ?? '',
        porsiBsi: (json['porsi_bsi'] ?? 0).toDouble(),
        porsiBsu: (json['porsi_bsu'] ?? 0).toDouble(),
        porsiTransport: (json['porsi_transport'] ?? 0).toDouble(),
        bsuTerlibat: (json['bsu_terlibat'] as List? ?? [])
            .map((e) => BsuPreviewItem.fromJson(e as Map<String, dynamic>))
            .toList(),
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

  PenerimaDistribusiSisaItem({
    required this.penerimaSisaId,
    required this.bankId,
    required this.namaBank,
    required this.nominalDiterima,
    required this.porsi,
    required this.transportasi,
    required this.satuanNominal,
    this.diantarOleh,
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
