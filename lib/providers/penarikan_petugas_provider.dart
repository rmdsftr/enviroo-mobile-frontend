import 'dart:io';
import 'package:flutter/foundation.dart';

import '../core/format/app_date.dart';
import '../models/penarikan_model.dart';
import '../services/penarikan_service.dart';
import 'auth_provider.dart';

class PenarikanPetugasProvider extends ChangeNotifier {
  AuthProvider? _auth;

  bool loadingList = false;
  String? errorList;
  List<PenarikanItem> _allItems = [];

  bool loadingDetail = false;
  PenarikanDetail? detail;
  String? errorDetail;

  bool submitting = false;

  String _rewardFilter = 'Semua';
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

  List<PenarikanItem> get pengajuanList => _allItems
      .where((i) => i.status.isDalamProses)
      .where(_matchesReward)
      .toList();

  List<PenarikanItem> get selesaiList => _allItems
      .where((i) => !i.status.isDalamProses)
      .where(_matchesReward)
      .toList();

  List<PenarikanItem> get pendingList => _allItems
      .where((i) => i.status == StatusPenarikan.pending)
      .where(_matchesReward)
      .toList();

  List<PenarikanItem> get approvedList => _allItems
      .where((i) => i.status == StatusPenarikan.approved)
      .where(_matchesReward)
      .toList();

  bool _matchesReward(PenarikanItem item) {
    if (_rewardFilter == 'Semua') return true;
    final lower = item.namaReward.toLowerCase();
    switch (_rewardFilter) {
      case 'Uang':
        return lower.contains('uang');
      case 'Barang':
        return lower.contains('barang');
      default:
        return true;
    }
  }

  String get _startStr => AppDate.apiAwalBulan(_filterStart);
  String get _endStr => AppDate.apiAkhirBulan(_filterEnd);

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

  Future<bool> selesaikanViaQr({
    required String qrData,
    required String penarikanId,
    String? catatan,
  }) async {
    if (!_hasToken) {
      errorDetail = 'Sesi tidak valid. Silakan login ulang.';
      return false;
    }
    submitting = true;
    errorDetail = null;
    notifyListeners();

    final res = await PenarikanService.selesaikanPenarikan(
      qrData: qrData,
      catatan: catatan,
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

  Future<bool> selesaikanManual({
    required String nasabahId,
    required String penarikanId,
    required File buktiFoto,
    required String catatan,
  }) async {
    if (!_hasToken) {
      errorDetail = 'Sesi tidak valid. Silakan login ulang.';
      return false;
    }
    submitting = true;
    errorDetail = null;
    notifyListeners();

    final res = await PenarikanService.selesaikanPenarikan(
      nasabahId: nasabahId,
      penarikanId: penarikanId,
      buktiFoto: buktiFoto,
      catatan: catatan,
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

  Future<bool> tolakPengajuan({
    required String penarikanId,
    required String catatan,
  }) async {
    if (!_hasToken) {
      errorDetail = 'Sesi tidak valid. Silakan login ulang.';
      return false;
    }
    submitting = true;
    errorDetail = null;
    notifyListeners();

    final res = await PenarikanService.tolakPengajuan(
      penarikanId: penarikanId,
      catatan: catatan,
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

  Future<bool> setujuiPengajuan({
    required String penarikanId,
    required DateTime deadlineJemput,
    String? catatan,
  }) async {
    if (!_hasToken) {
      errorDetail = 'Sesi tidak valid. Silakan login ulang.';
      return false;
    }
    submitting = true;
    errorDetail = null;
    notifyListeners();

    final res = await PenarikanService.setujuiPengajuan(
      penarikanId: penarikanId,
      deadlineJemput: deadlineJemput,
      catatan: catatan,
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
