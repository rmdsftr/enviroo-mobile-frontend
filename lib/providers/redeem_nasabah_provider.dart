import 'package:flutter/foundation.dart';

import '../models/redeem_models.dart';
import '../models/redeem_overview_model.dart';
import '../services/dashboard_service.dart';
import '../services/redeem_nasabah_service.dart';
import '../services/reward_service.dart';
import '../services/sembako_service.dart';
import 'auth_provider.dart';

class RedeemNasabahProvider extends ChangeNotifier {
  AuthProvider? _auth;

  bool _loadingList = false;
  bool _loadingForm = false;
  bool _submitting = false;
  String? _error;

  List<RedeemTransaksi> _list = [];
  SaldoNasabah? _saldo;
  List<NilaiRewardBank> _nilaiRewards = [];
  List<SembakoItem> _sembakoList = [];
  List<String> _rewardTypes = [];
  List<RedeemOverviewItem> _redeemOverview = [];

  bool get loadingList => _loadingList;
  bool get loadingForm => _loadingForm;
  bool get submitting => _submitting;
  String? get error => _error;
  List<RedeemTransaksi> get list => _list;
  SaldoNasabah? get saldo => _saldo;
  List<NilaiRewardBank> get nilaiRewards => _nilaiRewards;
  List<SembakoItem> get sembakoList => _sembakoList;
  /// Nama reward yang tersedia di bank (e.g. ['Uang tunai', 'Emas'])
  List<String> get rewardTypes => _rewardTypes;
  /// Overview total penarikan per reward jenis
  List<RedeemOverviewItem> get redeemOverview => _redeemOverview;

  void bind(AuthProvider auth) {
    _auth = auth;
  }

  String? get _nasabahId => _auth?.identityId;
  String? get _bankId => _auth?.bankId;
  String? get _token => _auth?.currentUser?.accessToken;

  bool get _hasSession =>
      (_nasabahId?.isNotEmpty ?? false) &&
      (_token?.isNotEmpty ?? false);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadList() async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return;
    }
    _loadingList = true;
    _error = null;
    notifyListeners();

    final res = await RedeemNasabahService.listByNasabah(_nasabahId!, _token!);
    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      _list = data
          .whereType<Map<String, dynamic>>()
          .map((e) => RedeemTransaksi.fromJson(e))
          .toList();
    } else {
      _error = res['message']?.toString();
    }

    _loadingList = false;
    notifyListeners();
  }

  /// Ambil overview total penarikan per reward jenis
  Future<void> loadRedeemOverview() async {
    final nasabahId = _nasabahId;
    final token = _token;
    if (nasabahId == null || nasabahId.isEmpty || token == null) return;

    final res = await DashboardService.getRedeemOverviewNasabah(nasabahId, token);
    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      _redeemOverview = data
          .whereType<Map<String, dynamic>>()
          .map((e) => RedeemOverviewItem.fromJson(e))
          .toList();
      notifyListeners();
    }
  }

  /// Ambil reward types yang aktif di bank ini (ringan, tidak load saldo/sembako)
  Future<void> loadRewardTypes() async {
    final bankId = _bankId;
    final token = _token;
    if (bankId == null || bankId.isEmpty || token == null) return;

    final res = await RewardService.getNilaiReward(bankId, token);
    if (res['success'] == true) {
      final data = (res['data'] as List?) ?? [];
      _rewardTypes = data
          .whereType<Map<String, dynamic>>()
          .map((e) {
            final rewardMap = e['Reward'] ?? e['reward'];
            if (rewardMap is Map<String, dynamic>) {
              return (rewardMap['nama_reward'] ?? rewardMap['NamaReward'] ?? '') as String;
            }
            return '';
          })
          .where((name) => name.isNotEmpty)
          .toList();
      notifyListeners();
    }
  }

  Future<void> loadFormData() async {
    if (!_hasSession || (_bankId?.isEmpty ?? true)) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return;
    }
    _loadingForm = true;
    _error = null;
    notifyListeners();

    final saldoFut = RedeemNasabahService.getSaldoNasabah(_nasabahId!, _token!);
    final rewardFut = RewardService.getNilaiReward(_bankId!, _token!);
    final sembakoFut = SembakoService.getSembakoBank(_bankId!, _token!);

    final saldoRes = await saldoFut;
    if (saldoRes['success'] == true) {
      _saldo = SaldoNasabah.fromJson(
          (saldoRes['data'] as Map<String, dynamic>?) ?? {});
    } else {
      _error = saldoRes['message']?.toString();
    }

    final rewardRes = await rewardFut;
    if (rewardRes['success'] == true) {
      final list = (rewardRes['data'] as List?) ?? [];
      _nilaiRewards = list
          .whereType<Map<String, dynamic>>()
          .map((e) => NilaiRewardBank.fromJson(e))
          .toList();
    } else {
      _error ??= rewardRes['message']?.toString();
    }

    final sembakoRes = await sembakoFut;
    if (sembakoRes['success'] == true) {
      final list = (sembakoRes['data'] as List?) ?? [];
      _sembakoList = list
          .whereType<Map<String, dynamic>>()
          .map((e) => SembakoItem.fromJson(e))
          .toList();
    } else {
      _error ??= sembakoRes['message']?.toString();
    }

    _loadingForm = false;
    notifyListeners();
  }

  Future<bool> submitRequest({
    required int rewardId,
    required double poinRedeem,
    List<Map<String, dynamic>> redeemSembakoItem = const [],
  }) async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return false;
    }
    _submitting = true;
    _error = null;
    notifyListeners();

    final res = await RedeemNasabahService.request(
      nasabahId: _nasabahId!,
      token: _token!,
      rewardId: rewardId,
      poinRedeem: poinRedeem,
      redeemSembakoItem: redeemSembakoItem,
    );

    _submitting = false;
    if (res['success'] == true) {
      notifyListeners();
      await loadList();
      return true;
    }

    _error = res['message']?.toString();
    notifyListeners();
    return false;
  }

  Future<bool> cancelRedeem(String transaksiId) async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return false;
    }
    _submitting = true;
    _error = null;
    notifyListeners();

    final res = await RedeemNasabahService.cancel(
      transaksiId: transaksiId,
      nasabahId: _nasabahId!,
      token: _token!,
    );

    _submitting = false;
    if (res['success'] == true) {
      notifyListeners();
      await loadList();
      return true;
    }

    _error = res['message']?.toString();
    notifyListeners();
    return false;
  }
}
