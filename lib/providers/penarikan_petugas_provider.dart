import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/penarikan_model.dart';
import '../services/penarikan_service.dart';
import 'auth_provider.dart';

class PenarikanPetugasProvider extends ChangeNotifier {
  AuthProvider? _auth;

  // ── List state ────────────────────────────────────────────────────────────
  bool loadingList = false;
  String? errorList;
  List<PenarikanItem> _allItems = [];

  // ── Detail state ──────────────────────────────────────────────────────────
  bool loadingDetail = false;
  PenarikanDetail? detail;
  String? errorDetail;

  // ── Submit state ──────────────────────────────────────────────────────────
  bool submitting = false;

  // ── Filters ───────────────────────────────────────────────────────────────
  String _rewardFilter = 'Semua'; // "Semua" | "Uang" | "Sembako"
  late DateTime _filterStart;
  late DateTime _filterEnd;

  String get rewardFilter => _rewardFilter;
  DateTime get filterStart => _filterStart;
  DateTime get filterEnd => _filterEnd;

  PenarikanPetugasProvider() {
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

  String? get _bankId => _auth?.bankId;
  bool get _ok => _bankId?.isNotEmpty ?? false;
  bool get _hasToken => _auth != null;

  // ── Filtered views ────────────────────────────────────────────────────────

  List<PenarikanItem> get pengajuanList => _allItems
      .where((i) => i.status == StatusPenarikan.pending)
      .where(_matchesReward)
      .toList();

  List<PenarikanItem> get selesaiList => _allItems
      .where((i) => i.status != StatusPenarikan.pending)
      .where(_matchesReward)
      .toList();

  bool _matchesReward(PenarikanItem item) {
    if (_rewardFilter == 'Semua') return true;
    final lower = item.namaReward.toLowerCase();
    switch (_rewardFilter) {
      case 'Uang':
        return lower.contains('uang');
      case 'Sembako':
        return lower.contains('sembako');
      default:
        return true;
    }
  }

  // ── Date helpers ──────────────────────────────────────────────────────────

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  String get _startStr => _fmt(DateTime(_filterStart.year, _filterStart.month, 1));
  String get _endStr {
    final last = DateTime(_filterEnd.year, _filterEnd.month + 1, 0);
    return _fmt(last);
  }

  // ── Load list ─────────────────────────────────────────────────────────────

  Future<void> loadList() async {
    if (!_ok) {
      loadingList = false;
      errorList = 'Sesi tidak valid. Silakan login ulang.';
      notifyListeners();
      return;
    }
    loadingList = true;
    errorList = null;
    notifyListeners();

    final res = await PenarikanService.getListByBank(
      bankId: _bankId!,
      startDate: _startStr,
      endDate: _endStr,
      limit: 200,
    );

    loadingList = false;
    if (res['success'] == true) {
      final resp = PenarikanListResponse.fromJson(
          (res['data'] as Map<String, dynamic>?) ?? {});
      _allItems = resp.data;
    } else {
      errorList = res['message']?.toString();
      _allItems = [];
    }
    notifyListeners();
  }

  void setRewardFilter(String filter) {
    if (_rewardFilter == filter) return;
    _rewardFilter = filter;
    notifyListeners();
  }

  void setDateFilter(DateTime start, DateTime end) {
    _filterStart = start;
    _filterEnd = end;
    loadList();
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

  // ── Konfirmasi ────────────────────────────────────────────────────────────

  Future<bool> konfirmasi({
    required String penarikanId,
    required String buktiFoto,
  }) async {
    if (!_hasToken) {
      errorDetail = 'Sesi tidak valid. Silakan login ulang.';
      return false;
    }
    submitting = true;
    errorDetail = null;
    notifyListeners();

    final res = await PenarikanService.konfirmasi(
      penarikanId: penarikanId,
      buktiFoto: buktiFoto,
    );

    submitting = false;
    if (res['success'] == true) {
      await loadDetail(penarikanId);
      await loadList();
      return true;
    }
    errorDetail = res['message']?.toString();
    notifyListeners();
    return false;
  }
}
