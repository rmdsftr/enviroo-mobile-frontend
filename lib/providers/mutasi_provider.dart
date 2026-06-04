import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/mutasi_model.dart';
import '../services/mutasi_service.dart';
import 'auth_provider.dart';

class MutasiProvider extends ChangeNotifier {
  AuthProvider? _auth;

  bool loading = false;
  String? error;
  MutasiResponse? data;

  int _rewardId = 1; // 1=Uang, 2=Sembako
  late DateTime _filterStart;
  late DateTime _filterEnd;

  int get rewardId => _rewardId;
  DateTime get filterStart => _filterStart;
  DateTime get filterEnd => _filterEnd;

  MutasiProvider() {
    final now = DateTime.now();
    _filterEnd = DateTime(now.year, now.month);
    final startMonth = now.month - 2;
    _filterStart = startMonth <= 0
        ? DateTime(now.year - 1, 12 + startMonth)
        : DateTime(now.year, startMonth);
  }

  void bind(AuthProvider auth) {
    _auth = auth;
  }

  String? get _nasabahId => _auth?.identityId;
  bool get _ok => _nasabahId?.isNotEmpty ?? false;

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  String get _startStr =>
      _fmt(DateTime(_filterStart.year, _filterStart.month, 1));

  String get _endStr {
    final last = DateTime(_filterEnd.year, _filterEnd.month + 1, 0);
    return _fmt(last);
  }

  Future<void> load() async {
    if (!_ok) return;
    loading = true;
    error = null;
    notifyListeners();

    final res = await MutasiService.getMutasi(
      nasabahId: _nasabahId!,
      rewardId: _rewardId,
      startDate: _startStr,
      endDate: _endStr,
    );

    loading = false;
    if (res['success'] == true) {
      data = res['data'] != null
          ? MutasiResponse.fromJson(res['data'] as Map<String, dynamic>)
          : const MutasiResponse(
              namaReward: '',
              satuanReward: '',
              totalDebit: 0,
              totalKredit: 0,
              mutasiItems: [],
            );
    } else {
      error = res['message']?.toString();
      data = null;
    }
    notifyListeners();
  }

  void setRewardFilter(int rewardId) {
    if (_rewardId == rewardId) return;
    _rewardId = rewardId;
    load();
  }

  void setDateFilter(DateTime start, DateTime end) {
    _filterStart = start;
    _filterEnd = end;
    load();
  }
}
