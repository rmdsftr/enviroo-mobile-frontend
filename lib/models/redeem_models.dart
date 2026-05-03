enum RedeemStatus { waiting, approved, rejected, canceled, success, failed, unknown }

RedeemStatus redeemStatusFromString(String? value) {
  switch (value) {
    case 'waiting':
      return RedeemStatus.waiting;
    case 'approved':
      return RedeemStatus.approved;
    case 'rejected':
      return RedeemStatus.rejected;
    case 'canceled':
      return RedeemStatus.canceled;
    case 'success':
      return RedeemStatus.success;
    case 'failed':
      return RedeemStatus.failed;
    default:
      return RedeemStatus.unknown;
  }
}

String redeemStatusToString(RedeemStatus s) {
  switch (s) {
    case RedeemStatus.waiting:
      return 'waiting';
    case RedeemStatus.approved:
      return 'approved';
    case RedeemStatus.rejected:
      return 'rejected';
    case RedeemStatus.canceled:
      return 'canceled';
    case RedeemStatus.success:
      return 'success';
    case RedeemStatus.failed:
      return 'failed';
    case RedeemStatus.unknown:
      return 'unknown';
  }
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class RewardInfo {
  final int rewardId;
  final String namaReward;
  final String satuan;
  final String? deskripsi;

  RewardInfo({required this.rewardId, required this.namaReward, required this.satuan, this.deskripsi});

  factory RewardInfo.fromJson(Map<String, dynamic> json) {
    return RewardInfo(
      rewardId: _toInt(json['reward_id'] ?? json['RewardID']),
      namaReward: (json['nama_reward'] ?? json['NamaReward'] ?? '') as String,
      satuan: (json['satuan'] ?? json['Satuan'] ?? '') as String,
      deskripsi: json['deskripsi'] ?? json['Deskripsi'] as String?,
    );
  }
}

class BankInfo {
  final String bankId;
  final String namaBank;

  BankInfo({required this.bankId, required this.namaBank});

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      bankId: (json['bank_id'] ?? json['BankID'] ?? '') as String,
      namaBank: (json['nama_bank'] ?? json['NamaBank'] ?? '') as String,
    );
  }
}

class NilaiRewardBank {
  final String nilaiRewardId;
  final int rewardId;
  final double nilaiPoin;
  final double nilaiKonversi;
  final RewardInfo? reward;

  NilaiRewardBank({
    required this.nilaiRewardId,
    required this.rewardId,
    required this.nilaiPoin,
    required this.nilaiKonversi,
    this.reward,
  });

  String get namaReward => reward?.namaReward ?? '';
  String get satuan => reward?.satuan ?? '';

  bool get isSembako => namaReward.toLowerCase().contains('sembako');
  bool get isUang => namaReward.toLowerCase().contains('uang');
  bool get isEmas => namaReward.toLowerCase().contains('emas');

  /// Konversi poin ke nilai (rupiah / gram).
  double convertPoin(double poin) {
    if (nilaiPoin <= 0) return 0;
    return (poin / nilaiPoin) * nilaiKonversi;
  }

  factory NilaiRewardBank.fromJson(Map<String, dynamic> json) {
    final rewardJson = json['Reward'] ?? json['reward'];
    return NilaiRewardBank(
      nilaiRewardId: (json['nilai_reward_id'] ?? json['NilaiRewardID'] ?? '') as String,
      rewardId: _toInt(json['reward_id'] ?? json['RewardID']),
      nilaiPoin: _toDouble(json['nilai_poin'] ?? json['NilaiPoin']),
      nilaiKonversi: _toDouble(json['nilai_konversi'] ?? json['NilaiKonversi']),
      reward: rewardJson is Map<String, dynamic> ? RewardInfo.fromJson(rewardJson) : null,
    );
  }
}

class SembakoSchema {
  final String levelUser;
  final double poinHarga;

  SembakoSchema({required this.levelUser, required this.poinHarga});

  factory SembakoSchema.fromJson(Map<String, dynamic> json) {
    return SembakoSchema(
      levelUser: (json['level_user'] ?? '') as String,
      poinHarga: _toDouble(json['poin_harga']),
    );
  }
}

class SembakoItem {
  final String sembakoId;
  final String namaSembako;
  final String photoUrl;
  final double stok;
  final List<SembakoSchema> schemaHarga;

  SembakoItem({
    required this.sembakoId,
    required this.namaSembako,
    required this.photoUrl,
    required this.stok,
    required this.schemaHarga,
  });

  double get poinHargaBsu {
    final found = schemaHarga.firstWhere(
      (s) => s.levelUser.toLowerCase() == 'bsu',
      orElse: () => SembakoSchema(levelUser: '', poinHarga: 0),
    );
    return found.poinHarga;
  }

  double get poinHargaNasabah {
    final found = schemaHarga.firstWhere(
      (s) => s.levelUser.toLowerCase() == 'nasabah',
      orElse: () => SembakoSchema(levelUser: '', poinHarga: 0),
    );
    return found.poinHarga;
  }

  factory SembakoItem.fromJson(Map<String, dynamic> json) {
    final list = (json['schema_harga'] as List?) ?? [];
    return SembakoItem(
      sembakoId: (json['sembako_id'] ?? '') as String,
      namaSembako: (json['nama_sembako'] ?? '') as String,
      photoUrl: (json['photo_url'] ?? '') as String,
      stok: _toDouble(json['stok']),
      schemaHarga: list
          .whereType<Map<String, dynamic>>()
          .map((e) => SembakoSchema.fromJson(e))
          .toList(),
    );
  }
}

class KasReward {
  final int rewardId;
  final String namaReward;
  final String satuan;
  final double nominal;

  KasReward({
    required this.rewardId,
    required this.namaReward,
    required this.satuan,
    required this.nominal,
  });

  factory KasReward.fromJson(Map<String, dynamic> json) {
    return KasReward(
      rewardId: _toInt(json['reward_id']),
      namaReward: (json['nama_reward'] ?? '') as String,
      satuan: (json['satuan'] ?? '') as String,
      nominal: _toDouble(json['nominal']),
    );
  }
}

class SaldoBank {
  final String bankId;
  final String namaBank;
  final double saldoPoin;
  final List<KasReward> kas;

  SaldoBank({
    required this.bankId,
    required this.namaBank,
    required this.saldoPoin,
    required this.kas,
  });

  factory SaldoBank.fromJson(Map<String, dynamic> json) {
    final kasList = (json['kas'] as List?) ?? [];
    return SaldoBank(
      bankId: (json['bank_id'] ?? '') as String,
      namaBank: (json['nama_bank'] ?? '') as String,
      saldoPoin: _toDouble(json['saldo_poin']),
      kas: kasList
          .whereType<Map<String, dynamic>>()
          .map((e) => KasReward.fromJson(e))
          .toList(),
    );
  }
}

class RedeemSembakoDetail {
  final String sembakoId;
  final String? namaSembako;
  final String? photoUrl;
  final double qty;
  final double nilaiPoin;
  final double subtotalPoin;

  RedeemSembakoDetail({
    required this.sembakoId,
    this.namaSembako,
    this.photoUrl,
    required this.qty,
    required this.nilaiPoin,
    required this.subtotalPoin,
  });

  factory RedeemSembakoDetail.fromJson(Map<String, dynamic> json) {
    final sembakoRel = json['Sembako'] ?? json['sembako'];
    String? nama;
    String? photo;
    if (sembakoRel is Map) {
      nama = sembakoRel['nama_sembako'] ?? sembakoRel['NamaSembako'];
      photo = sembakoRel['photo_url'] ?? sembakoRel['PhotoURL'];
    }
    return RedeemSembakoDetail(
      sembakoId: (json['sembako_id'] ?? json['SembakoID'] ?? '') as String,
      namaSembako: nama,
      photoUrl: photo,
      qty: _toDouble(json['qty'] ?? json['Qty']),
      nilaiPoin: _toDouble(json['nilai_poin'] ?? json['NilaiPoin']),
      subtotalPoin: _toDouble(json['subtotal_poin'] ?? json['SubtotalPoin']),
    );
  }
}

class SaldoNasabah {
  final String nasabahId;
  final String namaNasabah;
  final double saldoPoin;

  SaldoNasabah({
    required this.nasabahId,
    required this.namaNasabah,
    required this.saldoPoin,
  });

  factory SaldoNasabah.fromJson(Map<String, dynamic> json) {
    return SaldoNasabah(
      nasabahId: (json['nasabah_id'] ?? '') as String,
      namaNasabah: (json['nama_nasabah'] ?? '') as String,
      saldoPoin: _toDouble(json['saldo_poin']),
    );
  }
}

class RedeemTransaksi {
  final String transaksiId;
  final String jenisTransaksi;
  final RedeemStatus status;
  final double poin;
  final double nominal;
  final String? catatan;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final RewardInfo? reward;
  final BankInfo? bankAsal;
  final BankInfo? bankTujuan;
  final String? nasabahName;
  final String? nasabahId;
  final String? namaPetugas;
  final List<RedeemSembakoDetail> details;

  RedeemTransaksi({
    required this.transaksiId,
    required this.jenisTransaksi,
    required this.status,
    required this.poin,
    required this.nominal,
    this.catatan,
    this.createdAt,
    this.updatedAt,
    this.reward,
    this.bankAsal,
    this.bankTujuan,
    this.nasabahName,
    this.nasabahId,
    this.namaPetugas,
    this.details = const [],
  });

  String get namaReward => reward?.namaReward ?? '-';
  bool get isSembako => namaReward.toLowerCase().contains('sembako');
  bool get isEmas => namaReward.toLowerCase().contains('emas');
  bool get isUang => namaReward.toLowerCase().contains('uang');

  factory RedeemTransaksi.fromJson(Map<String, dynamic> json) {
    // Backend baru mengirimkan flat fields: nasabah_id, nasabah_name, nama_petugas
    // Backward compat: juga coba parse dari nested Nasabah object (lama)
    final rewardJson = json['Reward'] ?? json['reward'];
    final asalJson = json['BankAsal'] ?? json['bank_asal'];
    final tujuanJson = json['BankTujuan'] ?? json['bank_tujuan'];
    final nasabahJson = json['Nasabah'] ?? json['nasabah'];
    final detailsJson = (json['Details'] ?? json['details']) as List?;

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) {
        final cleanStr = v.endsWith('Z') ? v.substring(0, v.length - 1) : v;
        return DateTime.tryParse(cleanStr);
      }
      return null;
    }

    // Ambil nasabah_name: coba flat dulu, lalu nested
    String? nasabahName = json['nasabah_name'] as String?;
    String? nasabahId = json['nasabah_id'] as String?;
    if ((nasabahName == null || nasabahName.isEmpty) && nasabahJson is Map<String, dynamic>) {
      nasabahName = nasabahJson['User']?['Nama'] ?? nasabahJson['user']?['nama'] as String?;
      nasabahId = (nasabahJson['nasabah_id'] ?? nasabahJson['NasabahID']) as String?;
    }

    // Reward: bisa flat (reward_name) atau nested
    RewardInfo? rewardInfo;
    if (rewardJson is Map<String, dynamic>) {
      rewardInfo = RewardInfo.fromJson(rewardJson);
    } else if (json['reward_name'] != null) {
      rewardInfo = RewardInfo(
        rewardId: 0,
        namaReward: json['reward_name'] as String,
        satuan: '',
      );
    }

    return RedeemTransaksi(
      transaksiId: (json['transaksi_id'] ?? json['TransaksiID'] ?? '') as String,
      jenisTransaksi: (json['jenis_transaksi'] ?? json['JenisTransaksi'] ?? '') as String,
      status: redeemStatusFromString(
          (json['status_transaksi'] ?? json['StatusTransaksi']) as String?),
      poin: _toDouble(json['poin'] ?? json['Poin']),
      nominal: _toDouble(json['nominal'] ?? json['Nominal']),
      catatan: (json['catatan'] ?? json['Catatan']) as String?,
      createdAt: parseDate(json['created_at'] ?? json['CreatedAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['UpdatedAt']),
      reward: rewardInfo,
      bankAsal: asalJson is Map<String, dynamic> ? BankInfo.fromJson(asalJson) : null,
      bankTujuan: tujuanJson is Map<String, dynamic> ? BankInfo.fromJson(tujuanJson) : null,
      nasabahName: nasabahName,
      nasabahId: nasabahId,
      namaPetugas: json['nama_petugas'] as String?,
      details: (detailsJson ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => RedeemSembakoDetail.fromJson(e))
          .toList(),
    );
  }
}
