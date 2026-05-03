import 'package:flutter/foundation.dart';

import '../models/redeem_models.dart';
import '../services/redeem_bsu_service.dart';
import 'auth_provider.dart';

/// Provider untuk sisi BSI: list pengajuan masuk, verifikasi, konfirmasi.
/// AuthProvider di-set lewat [bind] sebelum memanggil method API.
class RedeemBsiProvider extends ChangeNotifier {
  AuthProvider? _auth;

  bool _loadingList = false;
  bool _loadingDetail = false;
  bool _submitting = false;
  String? _error;

  List<RedeemTransaksi> _list = [];
  RedeemTransaksi? _detail;

  bool get loadingList => _loadingList;
  bool get loadingDetail => _loadingDetail;
  bool get submitting => _submitting;
  String? get error => _error;
  List<RedeemTransaksi> get list => _list;
  RedeemTransaksi? get detail => _detail;

  List<RedeemTransaksi> get waitingList =>
      _list.where((e) => e.status == RedeemStatus.waiting).toList();
  List<RedeemTransaksi> get approvedList =>
      _list.where((e) => e.status == RedeemStatus.approved).toList();
  List<RedeemTransaksi> get historyList => _list
      .where((e) =>
          e.status == RedeemStatus.success ||
          e.status == RedeemStatus.rejected ||
          e.status == RedeemStatus.canceled)
      .toList();

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

  Future<RedeemTransaksi?> loadDetail(String redeemId) async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return null;
    }
    _loadingDetail = true;
    _error = null;
    _detail = null;
    notifyListeners();

    final res = await RedeemBsuService.getDetailRedeem(redeemId, _token!);
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      _detail = RedeemTransaksi.fromJson(res['data'] as Map<String, dynamic>);
    } else {
      _error = res['message']?.toString();
    }

    _loadingDetail = false;
    notifyListeners();
    return _detail;
  }

  /// Cek apakah transaksi valid via verifikasi-manual.
  /// Mengembalikan true jika status verified.
  Future<bool> verifikasiManual(String transaksiId) async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return false;
    }
    _submitting = true;
    _error = null;
    notifyListeners();

    final res = await RedeemBsuService.verifikasiManual(
      transaksiId: transaksiId,
      adminBsiId: _identityId!,
      token: _token!,
    );

    _submitting = false;
    if (res['success'] == true) {
      notifyListeners();
      return true;
    }

    _error = res['message']?.toString();
    notifyListeners();
    return false;
  }

  /// status_transaksi: approved | rejected | success
  Future<bool> confirm({
    required String transaksiId,
    required String statusTransaksi,
    String? catatan,
  }) async {
    if (!_hasSession) {
      _error = 'Sesi tidak valid, silakan login ulang';
      notifyListeners();
      return false;
    }
    _submitting = true;
    _error = null;
    notifyListeners();

    final res = await RedeemBsuService.confirmRedeem(
      transaksiId: transaksiId,
      adminBsiId: _identityId!,
      token: _token!,
      statusTransaksi: statusTransaksi,
      catatan: catatan,
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
