import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/katalog_model.dart';
import '../models/penarikan_model.dart';
import '../services/dashboard_service.dart';
import '../services/penarikan_service.dart';
import '../services/reward_service.dart';
import '../services/sembako_service.dart';
import 'auth_provider.dart';

class PenarikanNasabahProvider extends ChangeNotifier {
  AuthProvider? _auth;

  // ── Saldo ──────────────────────────────────────────────────────────────────
  bool loadingSaldo = false;
  SaldoNasabahV2? saldo;
  String? errorSaldo;

  // ── Reward types ──────────────────────────────────────────────────────────
  bool loadingRewards = false;
  List<NilaiRewardBank> nilaiRewards = [];

  // ── Sembako catalog (for request form) ───────────────────────────────────
  bool loadingSembako = false;
  List<KatalogSembakoModel> sembakoList = <KatalogSembakoModel>[];

  // ── Penarikan list ────────────────────────────────────────────────────────
  bool loadingList = false;
  bool loadingMore = false;
  List<PenarikanItem> penarikanList = [];
  int totalCount = 0;
  int totalPages = 0;
  int _currentPage = 1;
  bool hasMore = false;
  String? errorList;

  // ── Current filter ────────────────────────────────────────────────────────
  int? _activeRewardId;
  late DateTime _filterStart;
  late DateTime _filterEnd;

  // ── Detail ────────────────────────────────────────────────────────────────
  bool loadingDetail = false;
  PenarikanDetail? detail;
  String? errorDetail;

  // ── Submit states ─────────────────────────────────────────────────────────
  bool canceling = false;

  PenarikanNasabahProvider() {
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    final startMonth = now.month - 2;
    if (startMonth <= 0) {
      _filterStart = DateTime(now.year - 1, 12 + startMonth);
    } else {
      _filterStart = DateTime(now.year, startMonth);
    }
  }

  void bind(AuthProvider auth) {
    _auth = auth;
  }

  String? get _nasabahId => _auth?.identityId;
  String? get _bankId => _auth?.bankId;

  bool get _ok => _nasabahId?.isNotEmpty ?? false;
  bool get _hasToken => _auth != null;

  // ── Getters for filter state ──────────────────────────────────────────────

  int? get activeRewardId => _activeRewardId;
  DateTime get filterStart => _filterStart;
  DateTime get filterEnd => _filterEnd;

  NilaiRewardBank? get rewardUang =>
      nilaiRewards.cast<NilaiRewardBank?>().firstWhere(
            (r) => r!.isUang,
            orElse: () => null,
          );

  NilaiRewardBank? get rewardSembako =>
      nilaiRewards.cast<NilaiRewardBank?>().firstWhere(
            (r) => r!.isSembako,
            orElse: () => null,
          );

  // ── Load saldo ────────────────────────────────────────────────────────────

  Future<void> loadSaldo() async {
    if (!_ok) return;
    loadingSaldo = true;
    errorSaldo = null;
    notifyListeners();

    final res = await DashboardService.getSaldoNasabah(_nasabahId!);

    loadingSaldo = false;
    if (res['success'] == true && res['data'] != null) {
      saldo = SaldoNasabahV2.fromJson(
          (res['data'] as Map<String, dynamic>?) ?? {});
    } else {
      errorSaldo = res['message']?.toString();
    }
    notifyListeners();
  }

  // ── Load reward types ─────────────────────────────────────────────────────

  Future<void> loadRewards() async {
    if (_bankId == null) return;
    loadingRewards = true;
    notifyListeners();

    final res = await RewardService.getNilaiReward(_bankId!);
    loadingRewards = false;
    if (res['success'] == true) {
      final list = (res['data'] as List?) ?? [];
      nilaiRewards = list
          .whereType<Map<String, dynamic>>()
          .map((e) => NilaiRewardBank.fromJson(e))
          .toList();
    }
    notifyListeners();
  }

  // ── Load sembako catalog ──────────────────────────────────────────────────

  Future<void> loadSembako() async {
    if (_bankId == null) return;
    loadingSembako = true;
    notifyListeners();

    final res = await SembakoService.getSembakoBank(_bankId!);
    loadingSembako = false;
    if (res['success'] == true) {
      final list = (res['data'] as List?) ?? [];
      sembakoList = list
          .whereType<Map<String, dynamic>>()
          .map<KatalogSembakoModel>((e) => KatalogSembakoModel.fromJson(e))
          .toList();
    }
    notifyListeners();
  }

  // ── Load initial data for PenarikanNasabahScreen ─────────────────────────

  Future<void> loadInitial() async {
    await Future.wait([
      loadSaldo(),
      loadRewards(),
    ]);
    
    if (_activeRewardId == null) {
      _activeRewardId = rewardUang?.rewardId;
    }
    await loadList(refresh: true);
  }

  // ── Load form data for RequestPenarikanScreen ─────────────────────────────

  Future<void> loadFormData() async {
    await Future.wait([
      if (saldo == null) loadSaldo(),
      if (nilaiRewards.isEmpty) loadRewards(),
      if (sembakoList.isEmpty) loadSembako(),
    ]);
  }

  // ── Load penarikan list ───────────────────────────────────────────────────

  String _dateStr(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  String get _startDateStr =>
      _dateStr(DateTime(_filterStart.year, _filterStart.month, 1));

  String get _endDateStr {
    final lastDay = DateTime(_filterEnd.year, _filterEnd.month + 1, 0);
    return _dateStr(lastDay);
  }

  Future<void> loadList({bool refresh = true}) async {
    if (!_ok) {
      if (refresh) {
        loadingList = false;
        errorList = 'Sesi tidak valid. Silakan login ulang.';
        notifyListeners();
      }
      return;
    }

    if (refresh) {
      _currentPage = 1;
      loadingList = true;
      errorList = null;
    } else {
      loadingMore = true;
    }
    notifyListeners();

    final res = await PenarikanService.getList(
      nasabahId: _nasabahId!,
      rewardId: _activeRewardId,
      startDate: _startDateStr,
      endDate: _endDateStr,
      page: _currentPage,
      limit: 20,
    );

    if (refresh) {
      loadingList = false;
    } else {
      loadingMore = false;
    }

    if (res['success'] == true) {
      final resp = PenarikanListResponse.fromJson(
          (res['data'] as Map<String, dynamic>?) ?? {});
      if (refresh) {
        penarikanList = resp.data;
      } else {
        penarikanList = [...penarikanList, ...resp.data];
      }
      totalCount = resp.total;
      totalPages = resp.totalPages;
      hasMore = _currentPage < resp.totalPages;
    } else {
      if (refresh) {
        errorList = res['message']?.toString();
        penarikanList = [];
      }
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore) return;
    _currentPage++;
    await loadList(refresh: false);
  }

  void setFilter({int? rewardId, DateTime? start, DateTime? end}) {
    bool changed = false;
    if (rewardId != _activeRewardId) {
      _activeRewardId = rewardId;
      changed = true;
    }
    if (start != null && start != _filterStart) {
      _filterStart = start;
      changed = true;
    }
    if (end != null && end != _filterEnd) {
      _filterEnd = end;
      changed = true;
    }
    if (changed) loadList(refresh: true);
  }

  // ── Load detail ───────────────────────────────────────────────────────────

  Future<void> loadDetail(String penarikanId) async {
    if (!_hasToken) {
      loadingDetail = false;
      errorDetail = 'Sesi tidak valid. Silakan login ulang.';
      notifyListeners();
      return;
    }
    loadingDetail = true;
    errorDetail = null;
    detail = null;
    notifyListeners();

    final res = await PenarikanService.getDetail(penarikanId);

    loadingDetail = false;
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        detail = PenarikanDetail.fromJson(data);
      }
    } else {
      errorDetail = res['message']?.toString();
    }
    notifyListeners();
  }

  // ── Preview ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> callPreview({
    required int rewardId,
    double? nominalPenarikan,
    List<Map<String, dynamic>> itemSembako = const [],
  }) async {
    if (!_ok) {
      return {'success': false, 'message': 'Sesi tidak valid'};
    }
    return PenarikanService.preview(
      nasabahId: _nasabahId!,
      rewardId: rewardId,
      nominalPenarikan: nominalPenarikan,
      itemSembako: itemSembako,
    );
  }

  // ── Ajukan ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> callAjukan({
    required int rewardId,
    double? nominalPenarikan,
    List<Map<String, dynamic>> itemSembako = const [],
  }) async {
    if (!_ok) {
      return {'success': false, 'message': 'Sesi tidak valid'};
    }
    return PenarikanService.ajukan(
      nasabahId: _nasabahId!,
      rewardId: rewardId,
      nominalPenarikan: nominalPenarikan,
      itemSembako: itemSembako,
    );
  }

  // ── Batalkan ─────────────────────────────────────────────────────────────

  Future<bool> callBatal(String penarikanId) async {
    if (!_hasToken) return false;
    canceling = true;
    notifyListeners();

    final res = await PenarikanService.batal(penarikanId);

    canceling = false;
    if (res['success'] == true) {
      // Reload detail to reflect new status
      await loadDetail(penarikanId);
      // Also invalidate list cache so next visit is fresh
      penarikanList = penarikanList.map((item) {
        if (item.penarikanId == penarikanId) {
          return PenarikanItem(
            penarikanId: item.penarikanId,
            nasabahId: item.nasabahId,
            rewardId: item.rewardId,
            namaReward: item.namaReward,
            nominalPenarikan: item.nominalPenarikan,
            satuanPenarikan: item.satuanPenarikan,
            status: StatusPenarikan.dibatalkan,
            kadaluarsaAt: item.kadaluarsaAt,
            createdAt: item.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return item;
      }).toList();
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }
}
