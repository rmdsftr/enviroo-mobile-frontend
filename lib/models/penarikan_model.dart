// ── Reward info (moved from redeem_models) ───────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────

enum StatusPenarikan { pending, berhasil, kadaluarsa, dibatalkan, unknown }

StatusPenarikan statusPenarikanFromString(String? v) {
  switch (v) {
    case 'pending':
      return StatusPenarikan.pending;
    case 'berhasil':
      return StatusPenarikan.berhasil;
    case 'kadaluarsa':
      return StatusPenarikan.kadaluarsa;
    case 'dibatalkan':
      return StatusPenarikan.dibatalkan;
    default:
      return StatusPenarikan.unknown;
  }
}

double _d(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _i(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String && v.isNotEmpty) {
    final s = v.endsWith('Z') ? v.substring(0, v.length - 1) : v;
    return DateTime.tryParse(s);
  }
  return null;
}

// ── Saldo per reward ─────────────────────────────────────────────────────────

class SaldoReward {
  final int rewardId;
  final String namaReward;
  final String satuan;
  final double nominal;

  SaldoReward({
    required this.rewardId,
    required this.namaReward,
    required this.satuan,
    required this.nominal,
  });

  bool get isUang => namaReward.toLowerCase().contains('uang');
  bool get isSembako => namaReward.toLowerCase().contains('sembako');

  factory SaldoReward.fromJson(Map<String, dynamic> j) => SaldoReward(
        rewardId: _i(j['reward_id']),
        namaReward: (j['nama_reward'] ?? '') as String,
        satuan: (j['satuan'] ?? '') as String,
        nominal: _d(j['nominal'] ?? j['nominal_saldo']),
      );
}

/// Model saldo nasabah yang mendukung per-reward breakdown.
/// Fallback ke single saldo_poin jika backend belum mengembalikan breakdown.
class SaldoNasabahV2 {
  final String nasabahId;
  final String namaNasabah;
  final List<SaldoReward> saldo;
  final double saldoPoinTotal;

  SaldoNasabahV2({
    required this.nasabahId,
    required this.namaNasabah,
    required this.saldo,
    required this.saldoPoinTotal,
  });

  SaldoReward? get saldoUang =>
      saldo.cast<SaldoReward?>().firstWhere((s) => s!.isUang, orElse: () => null);
  SaldoReward? get saldoSembako =>
      saldo.cast<SaldoReward?>().firstWhere((s) => s!.isSembako, orElse: () => null);

  bool get hasPerRewardSaldo => saldo.isNotEmpty;

  factory SaldoNasabahV2.fromJson(Map<String, dynamic> j) {
    List<SaldoReward> saldoList = [];

    // Format 1 (actual API): { uang: {total_uang}, poin: {total_poin} }
    final uangData = j['uang'] as Map<String, dynamic>?;
    final poinData = j['poin'] as Map<String, dynamic>?;
    if (uangData != null || poinData != null) {
      if (uangData != null) {
        saldoList.add(SaldoReward(
            rewardId: 1,
            namaReward: 'uang',
            satuan: 'rupiah',
            nominal: _d(uangData['total_uang'])));
      }
      if (poinData != null) {
        saldoList.add(SaldoReward(
            rewardId: 2,
            namaReward: 'sembako',
            satuan: 'poin',
            nominal: _d(poinData['total_poin'])));
      }
    }

    // Format 2: saldo[] array
    if (saldoList.isEmpty) {
      final saldoData = j['saldo'];
      if (saldoData is List) {
        saldoList = saldoData
            .whereType<Map<String, dynamic>>()
            .map(SaldoReward.fromJson)
            .toList();
      }
    }

    // Format 3: flat fields
    if (saldoList.isEmpty) {
      if (j['saldo_uang'] != null) {
        saldoList.add(SaldoReward(
            rewardId: 1,
            namaReward: 'uang',
            satuan: 'rupiah',
            nominal: _d(j['saldo_uang'])));
      }
      if (j['saldo_poin_sembako'] != null) {
        saldoList.add(SaldoReward(
            rewardId: 2,
            namaReward: 'sembako',
            satuan: 'poin',
            nominal: _d(j['saldo_poin_sembako'])));
      }
    }

    double saldoPoinTotal = _d(j['saldo_poin']);
    if (saldoPoinTotal == 0 && poinData != null) {
      saldoPoinTotal = _d(poinData['total_poin']);
    }

    return SaldoNasabahV2(
      nasabahId: (j['nasabah_id'] ?? '') as String,
      namaNasabah: (j['nama_nasabah'] ?? '') as String,
      saldo: saldoList,
      saldoPoinTotal: saldoPoinTotal,
    );
  }
}

// ── Penarikan list item ──────────────────────────────────────────────────────

class PenarikanItem {
  final String penarikanId;
  final String? nasabahId;
  final String? namaNasabah;
  final String? bankId;
  final String? namaBank;
  final int? rewardId;
  final String namaReward;
  final double nominalPenarikan;
  final String satuanPenarikan;
  final StatusPenarikan status;
  final DateTime? kadaluarsaAt;
  final String? buktiFoto;
  final DateTime createdAt;
  final DateTime updatedAt;

  PenarikanItem({
    required this.penarikanId,
    this.nasabahId,
    this.namaNasabah,
    this.bankId,
    this.namaBank,
    this.rewardId,
    required this.namaReward,
    required this.nominalPenarikan,
    required this.satuanPenarikan,
    required this.status,
    this.kadaluarsaAt,
    this.buktiFoto,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isUang => namaReward.toLowerCase().contains('uang');
  bool get isSembako => namaReward.toLowerCase().contains('sembako');

  factory PenarikanItem.fromJson(Map<String, dynamic> j) => PenarikanItem(
        penarikanId: (j['penarikan_id'] ?? '') as String,
        nasabahId: j['nasabah_id'] as String?,
        namaNasabah: j['nama_nasabah'] as String?,
        bankId: j['bank_id'] as String?,
        namaBank: j['nama_bank'] as String?,
        rewardId: j['reward_id'] == null ? null : _i(j['reward_id']),
        namaReward: (j['nama_reward'] ?? '') as String,
        nominalPenarikan: _d(j['nominal_penarikan']),
        satuanPenarikan: (j['satuan_penarikan'] ?? '') as String,
        status: statusPenarikanFromString(j['status_penarikan'] as String?),
        kadaluarsaAt: _parseDate(j['kadaluarsa_at']),
        buktiFoto: j['bukti_foto'] as String?,
        createdAt: _parseDate(j['created_at']) ?? DateTime.now(),
        updatedAt: _parseDate(j['updated_at']) ?? DateTime.now(),
      );
}

// ── Penarikan detail (includes sembako breakdown) ────────────────────────────

class DetailSembakoItem {
  final String sembakoId;
  final String namaSembako;
  final String? photoUrl;
  final double qty;
  final double nilaiPoin;
  final double subtotalPoin;

  DetailSembakoItem({
    required this.sembakoId,
    required this.namaSembako,
    this.photoUrl,
    required this.qty,
    required this.nilaiPoin,
    required this.subtotalPoin,
  });

  factory DetailSembakoItem.fromJson(Map<String, dynamic> j) =>
      DetailSembakoItem(
        sembakoId: (j['sembako_id'] ?? '') as String,
        namaSembako: (j['nama_sembako'] ?? '') as String,
        photoUrl: j['photo_url'] as String?,
        qty: _d(j['qty']),
        nilaiPoin: _d(j['nilai_poin']),
        subtotalPoin: _d(j['subtotal_poin']),
      );
}

class PenarikanDetail extends PenarikanItem {
  final List<DetailSembakoItem> detailSembako;

  PenarikanDetail({
    required super.penarikanId,
    super.nasabahId,
    super.namaNasabah,
    super.bankId,
    super.namaBank,
    super.rewardId,
    required super.namaReward,
    required super.nominalPenarikan,
    required super.satuanPenarikan,
    required super.status,
    super.kadaluarsaAt,
    super.buktiFoto,
    required super.createdAt,
    required super.updatedAt,
    required this.detailSembako,
  });

  factory PenarikanDetail.fromJson(Map<String, dynamic> j) {
    final base = PenarikanItem.fromJson(j);
    final sembakoList = (j['detail_sembako'] as List?) ?? [];
    return PenarikanDetail(
      penarikanId: base.penarikanId,
      nasabahId: base.nasabahId,
      namaNasabah: base.namaNasabah,
      bankId: base.bankId,
      namaBank: base.namaBank,
      rewardId: base.rewardId,
      namaReward: base.namaReward,
      nominalPenarikan: base.nominalPenarikan,
      satuanPenarikan: base.satuanPenarikan,
      status: base.status,
      kadaluarsaAt: base.kadaluarsaAt,
      buktiFoto: base.buktiFoto,
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      detailSembako: sembakoList
          .whereType<Map<String, dynamic>>()
          .map(DetailSembakoItem.fromJson)
          .toList(),
    );
  }
}

// ── Paginated list response ──────────────────────────────────────────────────

class PenarikanListResponse {
  final List<PenarikanItem> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PenarikanListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PenarikanListResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['data'] as List?) ?? [];
    return PenarikanListResponse(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(PenarikanItem.fromJson)
          .toList(),
      total: _i(j['total']),
      page: _i(j['page']),
      limit: _i(j['limit']),
      totalPages: _i(j['total_pages']),
    );
  }
}

// ── Preview data (response from /penarikan/preview) ─────────────────────────

class PreviewSembakoItem {
  final String sembakoId;
  final String namaSembako;
  final double qty;
  final double nilaiPoin;
  final double subtotalPoin;

  PreviewSembakoItem({
    required this.sembakoId,
    required this.namaSembako,
    required this.qty,
    required this.nilaiPoin,
    required this.subtotalPoin,
  });

  factory PreviewSembakoItem.fromJson(Map<String, dynamic> j) =>
      PreviewSembakoItem(
        sembakoId: (j['sembako_id'] ?? '') as String,
        namaSembako: (j['nama_sembako'] ?? '') as String,
        qty: _d(j['qty']),
        nilaiPoin: _d(j['nilai_poin']),
        subtotalPoin: _d(j['subtotal_poin']),
      );
}

class PenarikanPreviewData {
  final String nasabahId;
  final String namaReward;
  final String satuan;
  final double saldoSekarang;
  final String satuanSaldo;
  final double nominalPenarikan;
  final double saldoSetelah;
  final bool saldoCukup;
  final List<PreviewSembakoItem> itemSembako;

  // Form data carried forward to submit (not from API)
  final int rewardId;
  final double? nominalRequest;
  final List<Map<String, dynamic>> itemSembakoRequest;

  PenarikanPreviewData({
    required this.nasabahId,
    required this.namaReward,
    required this.satuan,
    required this.saldoSekarang,
    required this.satuanSaldo,
    required this.nominalPenarikan,
    required this.saldoSetelah,
    required this.saldoCukup,
    required this.itemSembako,
    required this.rewardId,
    this.nominalRequest,
    this.itemSembakoRequest = const [],
  });

  bool get isUang => namaReward.toLowerCase().contains('uang');
  bool get isSembako => namaReward.toLowerCase().contains('sembako');

  factory PenarikanPreviewData.fromJson(
    Map<String, dynamic> j, {
    required int rewardId,
    double? nominalRequest,
    List<Map<String, dynamic>> itemSembakoRequest = const [],
  }) {
    final items = (j['item_sembako'] as List?) ?? [];
    return PenarikanPreviewData(
      nasabahId: (j['nasabah_id'] ?? '') as String,
      namaReward: (j['nama_reward'] ?? '') as String,
      satuan: (j['satuan'] ?? '') as String,
      saldoSekarang: _d(j['saldo_sekarang']),
      satuanSaldo: (j['satuan_saldo'] ?? '') as String,
      nominalPenarikan: _d(j['nominal_penarikan']),
      saldoSetelah: _d(j['saldo_setelah']),
      saldoCukup: (j['saldo_cukup'] as bool?) ?? false,
      itemSembako: items
          .whereType<Map<String, dynamic>>()
          .map(PreviewSembakoItem.fromJson)
          .toList(),
      rewardId: rewardId,
      nominalRequest: nominalRequest,
      itemSembakoRequest: itemSembakoRequest,
    );
  }
}

// ── Form data passed from request screen to preview screen ───────────────────

class PenarikanFormData {
  final int rewardId;
  final String namaReward;
  final double? nominalPenarikan;
  final List<Map<String, dynamic>> itemSembako;

  const PenarikanFormData({
    required this.rewardId,
    required this.namaReward,
    this.nominalPenarikan,
    this.itemSembako = const [],
  });

  bool get isSembako => namaReward.toLowerCase().contains('sembako');
}
