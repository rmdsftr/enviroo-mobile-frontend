class BagiHasilSummary {
  final double grossBank;
  final double totalDistribusiNasabah;
  final double sisaBagiHasil;

  BagiHasilSummary({
    required this.grossBank,
    required this.totalDistribusiNasabah,
    required this.sisaBagiHasil,
  });

  factory BagiHasilSummary.fromJson(Map<String, dynamic> json) {
    return BagiHasilSummary(
      grossBank: (json['gross_bank'] ?? 0).toDouble(),
      totalDistribusiNasabah:
          (json['total_distribusi_nasabah'] ?? 0).toDouble(),
      sisaBagiHasil: (json['sisa_bagi_hasil'] ?? 0).toDouble(),
    );
  }
}

class PreviewPenerimaNasabah {
  final String nasabahId;
  final String namaNasabah;
  final double totalDiterima;

  PreviewPenerimaNasabah({
    required this.nasabahId,
    required this.namaNasabah,
    required this.totalDiterima,
  });

  factory PreviewPenerimaNasabah.fromJson(Map<String, dynamic> json) {
    return PreviewPenerimaNasabah(
      nasabahId: json['nasabah_id'] ?? '',
      namaNasabah: json['nama_nasabah'] ?? '',
      totalDiterima: (json['total_diterima'] ?? 0).toDouble(),
    );
  }
}

class PreviewPenerimaBank {
  final String bankId;
  final String namaBank;
  final List<PreviewPenerimaNasabah> nasabahPenerima;

  PreviewPenerimaBank({
    required this.bankId,
    required this.namaBank,
    required this.nasabahPenerima,
  });

  factory PreviewPenerimaBank.fromJson(Map<String, dynamic> json) {
    return PreviewPenerimaBank(
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      nasabahPenerima: (json['nasabah_penerima'] as List? ?? [])
          .map((e) => PreviewPenerimaNasabah.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PreviewBagiHasilModel {
  final String penjualanId;
  final String reward;
  final BagiHasilSummary summary;
  final List<PreviewPenerimaBank> penerima;

  PreviewBagiHasilModel({
    required this.penjualanId,
    required this.reward,
    required this.summary,
    required this.penerima,
  });

  factory PreviewBagiHasilModel.fromJson(Map<String, dynamic> json) {
    final summaryRaw = json['summary'] as Map<String, dynamic>? ?? {};
    return PreviewBagiHasilModel(
      penjualanId: json['penjualan_id'] ?? '',
      reward: json['reward'] ?? '',
      summary: BagiHasilSummary.fromJson(summaryRaw),
      penerima: (json['penerima'] as List? ?? [])
          .map((e) => PreviewPenerimaBank.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NasabahBagiHasil {
  final String penerimaId;
  final String nasabahId;
  final String namaNasabah;
  final double totalDiterima;
  final String satuanDiterima;

  NasabahBagiHasil({
    required this.penerimaId,
    required this.nasabahId,
    required this.namaNasabah,
    required this.totalDiterima,
    required this.satuanDiterima,
  });

  factory NasabahBagiHasil.fromJson(Map<String, dynamic> json) {
    return NasabahBagiHasil(
      penerimaId: json['penerima_id'] ?? '',
      nasabahId: json['nasabah_id'] ?? '',
      namaNasabah: json['nama_nasabah'] ?? '',
      totalDiterima: (json['total_diterima'] ?? 0).toDouble(),
      satuanDiterima: json['satuan_diterima'] ?? '',
    );
  }
}

class PenerimaBankBagiHasil {
  final String bankId;
  final String namaBank;
  final List<NasabahBagiHasil> nasabahPenerima;

  PenerimaBankBagiHasil({
    required this.bankId,
    required this.namaBank,
    required this.nasabahPenerima,
  });

  factory PenerimaBankBagiHasil.fromJson(Map<String, dynamic> json) {
    return PenerimaBankBagiHasil(
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      nasabahPenerima: (json['nasabah_penerima'] as List? ?? [])
          .map((e) => NasabahBagiHasil.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DetailBagiHasilModel {
  final String bagiHasilId;
  final String penjualanId;
  final String reward;
  final String satuan;
  final String tanggal;
  final String namaPetugas;
  final double grossBank;
  final double totalDistribusiNasabah;
  final double sisaBagiHasil;
  final List<PenerimaBankBagiHasil> penerima;
  final List<NasabahBagiHasil> nasabahLangsung;

  DetailBagiHasilModel({
    required this.bagiHasilId,
    required this.penjualanId,
    required this.reward,
    required this.satuan,
    required this.tanggal,
    required this.namaPetugas,
    required this.grossBank,
    required this.totalDistribusiNasabah,
    required this.sisaBagiHasil,
    required this.penerima,
    required this.nasabahLangsung,
  });

  bool get hasPenerima => penerima.isNotEmpty;

  factory DetailBagiHasilModel.fromJson(Map<String, dynamic> json) {
    return DetailBagiHasilModel(
      bagiHasilId: json['bagi_hasil_id'] ?? '',
      penjualanId: json['penjualan_id'] ?? '',
      reward: json['reward'] ?? '',
      satuan: json['satuan'] ?? '',
      tanggal: json['tanggal'] ?? '',
      namaPetugas: json['nama_petugas'] ?? '',
      grossBank: (json['gross_bank'] ?? 0).toDouble(),
      totalDistribusiNasabah:
          (json['total_distribusi_nasabah'] ?? 0).toDouble(),
      sisaBagiHasil: (json['sisa_bagi_hasil'] ?? 0).toDouble(),
      penerima: (json['penerima'] as List? ?? [])
          .map((e) => PenerimaBankBagiHasil.fromJson(e as Map<String, dynamic>))
          .toList(),
      nasabahLangsung: (json['nasabah_langsung'] as List? ?? [])
          .map((e) => NasabahBagiHasil.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
