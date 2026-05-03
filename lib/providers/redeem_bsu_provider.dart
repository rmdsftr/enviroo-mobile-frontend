import 'package:flutter/foundation.dart';

import '../models/redeem_models.dart';
import '../services/dashboard_service.dart';
import '../services/redeem_bsu_service.dart';
import '../services/reward_service.dart';
import '../services/sembako_service.dart';
import 'auth_provider.dart';

/// Provider untuk sisi BSU: list pengajuan, form data, submit, cancel.
/// AuthProvider di-set lewat [bind] sebelum memanggil method API.
class RedeemBsuProvider extends ChangeNotifier {
  AuthProvider? _auth;

  bool _loadingList = false;
  bool _loadingForm = false;
  bool _submitting = false;
  String? _error;

  List<RedeemTransaksi> _list = [];
  SaldoBank? _saldo;
  List<NilaiRewardBank> _nilaiRewards = [];
  List<SembakoItem> _sembakoList = [];

  bool get loadingList => _loadingList;
  bool get loadingForm => _loadingForm;
  bool get submitting => _submitting;
  String? get error => _error;
  List<RedeemTransaksi> get list => _list;
  SaldoBank? get saldo => _saldo;
  List<NilaiRewardBank> get nilaiRewards => _nilaiRewards;
  List<SembakoItem> get sembakoList => _sembakoList;

  void bind(AuthProvider auth) {
    _auth = auth;
  }

  String? get _bankId => _auth?.bankId;
  String? get _identityId => _auth?.identityId;
  String? get _token => _auth?.currentUser?.accessToken;

  bool get _hasSession =>
      (_bankId?.isNotEmpty ?? false) &&
      (_identityId?.isNotEmpty ?? false) &&
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

    final res = await RedeemBsuService.listRedeem(_bankId!, _token!);
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

  Future<void> loadFormData() async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return;
    }
    _loadingForm = true;
    _error = null;
    notifyListeners();

    final saldoFut = DashboardService.getSaldoBank(_bankId!, _token!);
    final rewardFut = RewardService.getNilaiReward(_bankId!, _token!);
    final sembakoFut = SembakoService.getSembakoBank(_bankId!, _token!);

    final saldoRes = await saldoFut;
    if (saldoRes['success'] == true) {
      _saldo = SaldoBank.fromJson(
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

  /// [redeemSembakoItem] format: [{sembako_id: 'SMB-1', qty: 2.0}, ...]
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

    final res = await RedeemBsuService.requestRedeem(
      bsuId: _bankId!,
      adminBsuId: _identityId!,
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

    final res = await RedeemBsuService.cancelRedeem(
      transaksiId: transaksiId,
      adminBsuId: _identityId!,
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
