class BagiHasilBankItem {
  final String bagiHasilId;
  final int rewardId;
  final String namaReward;
  final DateTime tanggalBagiHasil;

  BagiHasilBankItem({
    required this.bagiHasilId,
    required this.rewardId,
    required this.namaReward,
    required this.tanggalBagiHasil,
  });

  factory BagiHasilBankItem.fromJson(Map<String, dynamic> json) {
    return BagiHasilBankItem(
      bagiHasilId: json['bagi_hasil_id'] ?? '',
      rewardId: json['reward_id'] ?? 1,
      namaReward: json['nama_reward'] ?? '',
      tanggalBagiHasil: DateTime.parse(json['tanggal_bagi_hasil'] as String),
    );
  }
}

class BagiHasilBankListResponse {
  final String bankId;
  final String namaBank;
  final String jenisBank;
  final List<BagiHasilBankItem> riwayatBagiHasil;

  BagiHasilBankListResponse({
    required this.bankId,
    required this.namaBank,
    required this.jenisBank,
    required this.riwayatBagiHasil,
  });

  factory BagiHasilBankListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['riwayat_bagi_hasil'] as List<dynamic>? ?? [])
        .map((e) => BagiHasilBankItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return BagiHasilBankListResponse(
      bankId: json['bank_id'] ?? '',
      namaBank: json['nama_bank'] ?? '',
      jenisBank: json['jenis_bank'] ?? '',
      riwayatBagiHasil: list,
    );
  }
}

class BhNasabahPenerima {
  final String penerimaId;
  final String nasabahId;
  final String namaNasabah;
  final double totalDiterima;
  final String satuanDiterima;

  BhNasabahPenerima({
    required this.penerimaId,
    required this.nasabahId,
    required this.namaNasabah,
    required this.totalDiterima,
    required this.satuanDiterima,
  });

  factory BhNasabahPenerima.fromJson(Map<String, dynamic> json) {
    return BhNasabahPenerima(
      penerimaId: json['penerima_id'] ?? '',
      nasabahId: json['nasabah_id'] ?? '',
      namaNasabah: json['nama_nasabah'] ?? '',
      totalDiterima: (json['total_diterima'] ?? 0).toDouble(),
      satuanDiterima: json['satuan_diterima'] ?? '',
    );
  }
}

class BhPenerimaItem {
  final String bankId;
  final String namaBank;
  final List<BhNasabahPenerima> nasabahPenerima;

  BhPenerimaItem({
    required this.bankId,
    required this.namaBank,
    required this.nasabahPenerima,
  });

  factory BhPenerimaItem.fromJson(Map<String, dynamic> json) => BhPenerimaItem(
        bankId: json['bank_id'] ?? '',
        namaBank: json['nama_bank'] ?? '',
        nasabahPenerima: (json['nasabah_penerima'] as List? ?? [])
            .map((e) => BhNasabahPenerima.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BagiHasilBankDetail {
  final String bagiHasilId;
  final String? distribusiId;
  final String penjualanId;
  final int rewardId;
  final String namaReward;
  final DateTime tanggal;
  final double grossBsi;
  final double sisaBagiHasil;
  final double totalDistribusiNasabah;
  final List<BhNasabahPenerima>? nasabahBsi;
  final List<BhPenerimaItem> penerima;

  BagiHasilBankDetail({
    required this.bagiHasilId,
    this.distribusiId,
    required this.penjualanId,
    required this.rewardId,
    required this.namaReward,
    required this.tanggal,
    required this.grossBsi,
    required this.sisaBagiHasil,
    required this.totalDistribusiNasabah,
    this.nasabahBsi,
    required this.penerima,
  });

  factory BagiHasilBankDetail.fromJson(Map<String, dynamic> json) =>
      BagiHasilBankDetail(
        bagiHasilId: json['bagi_hasil_id'] ?? '',
        distribusiId: json['distribusi_id']?.toString(),
        penjualanId: json['penjualan_id'] ?? '',
        rewardId: json['reward_id'] ?? 1,
        namaReward: json['nama_reward'] ?? '',
        tanggal: DateTime.tryParse(json['tanggal'] ?? '') ?? DateTime.now(),
        grossBsi: (json['gross_bsm'] ?? json['gross_bsi'] ?? 0).toDouble(),
        sisaBagiHasil: (json['sisa_bagi_hasil'] ?? 0).toDouble(),
        totalDistribusiNasabah:
            (json['total_distribusi_nasabah'] ?? 0).toDouble(),
        nasabahBsi: json['nasabah_bsi'] != null
            ? (json['nasabah_bsi'] as List)
                .map((e) =>
                    BhNasabahPenerima.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        penerima: (json['penerima'] as List? ?? [])
            .map((e) => BhPenerimaItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
