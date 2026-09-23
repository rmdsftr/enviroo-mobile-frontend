import 'package:flutter/material.dart';

import '../models/bank_sampah_model.dart';
import '../models/bsu_unit_model.dart';
import '../services/bank_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

/// State untuk endpoint `/bank` yang dilayani `BankService`.
///
/// Dua slice: daftar seluruh bank sampah (peta `info_bank_sampah_screen`)
/// dan daftar BSU di bawah sebuah BSI.
class BankProvider extends ChangeNotifier {
  FetchStatus _semuaStatus = FetchStatus.idle;
  List<BankSampahModel> _semuaBank = [];
  String? _semuaError;

  FetchStatus get semuaStatus => _semuaStatus;
  List<BankSampahModel> get semuaBank => _semuaBank;
  String? get semuaError => _semuaError;

  Future<void> fetchSemuaBank() async {
    _semuaStatus = FetchStatus.loading;
    _semuaError = null;
    notifyListeners();

    final res = await BankService.getAllBankSampah();

    if (res['success'] == true) {
      _semuaBank = (res['data'] as List<BankSampahModel>?) ?? [];
      _semuaStatus = FetchStatus.success;
    } else {
      _semuaError = res['message']?.toString();
      _semuaStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // -- Daftar BSU di bawah satu BSI -------------------------------------------
  //
  // Tiga pemanggilnya dulu mem-parse BsuUnitModel sendiri-sendiri; sekarang
  // parsing-nya sekali di sini. `_bsiId` jadi penanda cache: ketiganya selalu
  // menanyakan BSI yang sama dalam satu sesi, jadi request kedua dan seterusnya
  // tidak perlu ditembakkan lagi.
  FetchStatus _bsuStatus = FetchStatus.idle;
  List<BsuUnitModel> _bsuList = [];
  String? _bsuError;
  String? _bsiId;

  FetchStatus get bsuStatus => _bsuStatus;
  List<BsuUnitModel> get bsuList => _bsuList;
  String? get bsuError => _bsuError;

  Future<void> fetchBsuList(String bsiId, {bool paksa = false}) async {
    if (!paksa && _bsiId == bsiId && _bsuStatus == FetchStatus.success) return;

    _bsuStatus = FetchStatus.loading;
    _bsuError = null;
    notifyListeners();

    final res = await BankService.getBsuByBsiId(bsiId);

    if (res['success'] == true) {
      _bsuList = (res['data'] as List? ?? [])
          .map((e) => BsuUnitModel.fromJson(e as Map<String, dynamic>))
          .toList();
      _bsiId = bsiId;
      _bsuStatus = FetchStatus.success;
    } else {
      _bsuError = res['message']?.toString();
      _bsuStatus = FetchStatus.error;
    }
    notifyListeners();
  }
}
