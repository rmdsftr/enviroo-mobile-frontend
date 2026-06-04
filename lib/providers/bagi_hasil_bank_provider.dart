import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/bagi_hasil_bank_model.dart';
import '../services/bagi_hasil_service.dart';

enum BhBankStatus { idle, loading, success, error }

class BagiHasilBankProvider extends ChangeNotifier {
  BhBankStatus _listStatus = BhBankStatus.idle;
  BagiHasilBankListResponse? _listData;
  String? _listError;

  BhBankStatus get listStatus => _listStatus;
  BagiHasilBankListResponse? get listData => _listData;
  String? get listError => _listError;

  BhBankStatus _detailStatus = BhBankStatus.idle;
  BagiHasilBankDetail? _detail;
  String? _detailError;

  BhBankStatus get detailStatus => _detailStatus;
  BagiHasilBankDetail? get detail => _detail;
  String? get detailError => _detailError;

  late DateTime filterStart;
  late DateTime filterEnd;

  BagiHasilBankProvider() {
    final now = DateTime.now();
    filterEnd = DateTime(now.year, now.month);
    final startMonth = now.month - 2;
    filterStart = startMonth <= 0
        ? DateTime(now.year - 1, 12 + startMonth)
        : DateTime(now.year, startMonth);
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
  String get _startStr => _fmt(DateTime(filterStart.year, filterStart.month, 1));
  String get _endStr {
    final last = DateTime(filterEnd.year, filterEnd.month + 1, 0);
    return _fmt(last);
  }

  Future<void> fetchList(String bankId) async {
    _listStatus = BhBankStatus.loading;
    _listError = null;
    notifyListeners();

    final res = await BagiHasilService.getListBagiHasilBank(bankId, _startStr, _endStr);

    if (res['success'] == true && res['data'] != null) {
      _listData = BagiHasilBankListResponse.fromJson(res['data'] as Map<String, dynamic>);
      _listStatus = BhBankStatus.success;
    } else {
      _listError = res['message']?.toString();
      _listStatus = BhBankStatus.error;
    }
    notifyListeners();
  }

  void setDateFilter(DateTime start, DateTime end, String bankId) {
    filterStart = start;
    filterEnd = end;
    fetchList(bankId);
  }

  Future<void> fetchDetail(String bagiHasilId) async {
    _detailStatus = BhBankStatus.loading;
    _detailError = null;
    _detail = null;
    notifyListeners();

    final res = await BagiHasilService.getDetailBagiHasilBank(bagiHasilId);

    if (res['success'] == true && res['data'] != null) {
      _detail = BagiHasilBankDetail.fromJson(res['data'] as Map<String, dynamic>);
      _detailStatus = BhBankStatus.success;
    } else {
      _detailError = res['message']?.toString();
      _detailStatus = BhBankStatus.error;
    }
    notifyListeners();
  }
}
