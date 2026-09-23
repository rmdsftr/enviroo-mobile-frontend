// ─── Persentase bagi hasil per jenis reward (GET /nilai-reward/get/:bank_id) ──
class PersenBagiHasilReward {
  final int rewardId;
  final String namaReward;
  final String levelUser;
  final double persenBagiHasil;
  final bool isActive;

  /// Satuan saldo yang dipakai reward ini -- backend mengirim "Rp" atau
  /// "poin" apa adanya. Kartu bagi hasil di beranda nasabah memakainya untuk
  /// melabeli jenis saldo ("Saldo Rupiah" / "Saldo Poin").
  final String satuan;

  /// Keterangan panjang jenis insentif — ditampilkan di kartu reward beranda
  /// nasabah.
  final String deskripsi;

  PersenBagiHasilReward({
    required this.rewardId,
    required this.namaReward,
    required this.levelUser,
    this.deskripsi = '',
    this.satuan = '',
    required this.persenBagiHasil,
    required this.isActive,
  });

  factory PersenBagiHasilReward.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] as Map<String, dynamic>?;
    return PersenBagiHasilReward(
      rewardId: (json['reward_id'] as num?)?.toInt() ?? 0,
      // Endpoint /nilai-reward mengirim reward bersarang dalam snake_case
      // (`nama_reward`), sementara sebagian endpoint lain memakai PascalCase.
      // Dulu di sini cuma PascalCase yang dibaca, jadi namaReward diam-diam
      // kosong dan layar riwayat bagi hasil cuma menulis "Insentif " —
      // tanpa error apa pun. Model tetangga (RewardInfo, RewardModel) sudah
      // menangani dua-duanya sejak awal.
      namaReward:
          (reward?['nama_reward'] ?? reward?['NamaReward'] ?? '').toString(),
      levelUser: json['level_user']?.toString() ?? '',
      deskripsi:
          (reward?['deskripsi'] ?? reward?['Deskripsi'] ?? '').toString(),
      satuan: (reward?['satuan'] ?? reward?['Satuan'] ?? '').toString(),
      persenBagiHasil: (json['persen_bagi_hasil'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}

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
      tanggalBagiHasil: DateTime.parse(json['tanggal_bagi_hasil'] as String).toLocal(),
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
        tanggal: DateTime.tryParse(json['tanggal'] ?? '')?.toLocal() ?? DateTime.now(),
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
