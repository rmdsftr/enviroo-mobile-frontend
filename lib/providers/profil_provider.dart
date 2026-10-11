import 'dart:io';

import 'package:flutter/material.dart';

import '../models/detail_bank_model.dart';
import '../models/detail_petugas_model.dart';
import '../services/profil_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

class ProfilProvider extends ChangeNotifier {
  FetchStatus _nasabahStatus = FetchStatus.idle;
  Map<String, dynamic>? _nasabah;
  String? _nasabahError;

  FetchStatus get nasabahStatus => _nasabahStatus;
  Map<String, dynamic>? get nasabah => _nasabah;
  String? get nasabahError => _nasabahError;

  FetchStatus _bankStatus = FetchStatus.idle;
  DetailBankModel? _bank;
  String? _bankError;

  FetchStatus get bankStatus => _bankStatus;
  DetailBankModel? get bank => _bank;
  String? get bankError => _bankError;

  FetchStatus _petugasStatus = FetchStatus.idle;
  DetailPetugasModel? _petugas;
  String? _petugasError;

  FetchStatus get petugasStatus => _petugasStatus;
  DetailPetugasModel? get petugas => _petugas;
  String? get petugasError => _petugasError;

  FetchStatus _logStatus = FetchStatus.idle;
  Map<String, dynamic>? _log;
  String? _logError;

  FetchStatus get logStatus => _logStatus;
  Map<String, dynamic>? get log => _log;
  String? get logError => _logError;

  FetchStatus _activeUserStatus = FetchStatus.idle;
  Map<String, dynamic>? _activeUser;
  String? _activeUserError;
  String? _activeUserId;

  FetchStatus get activeUserStatus => _activeUserStatus;
  Map<String, dynamic>? get activeUser => _activeUser;
  String? get activeUserError => _activeUserError;

  String _bersihkan(Object e) =>
      e.toString().replaceAll('Exception: ', '').trim();

  Future<void> fetchNasabah(String nasabahId) async {
    _nasabahStatus = FetchStatus.loading;
    _nasabahError = null;
    notifyListeners();

    try {
      _nasabah = await ProfilService.getDetailNasabah(nasabahId);
      _nasabahStatus = FetchStatus.success;
    } catch (e) {
      _nasabahError = _bersihkan(e);
      _nasabahStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchBank(String bankId) async {
    _bankStatus = FetchStatus.loading;
    _bankError = null;
    notifyListeners();

    try {
      _bank = await ProfilService.getDetailBank(bankId);
      _bankStatus = FetchStatus.success;
    } catch (e) {
      _bankError = _bersihkan(e);
      _bankStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchPetugas(String petugasId) async {
    _petugasStatus = FetchStatus.loading;
    _petugasError = null;
    notifyListeners();

    try {
      _petugas = await ProfilService.getDetailPetugas(petugasId);
      _petugasStatus = FetchStatus.success;
    } catch (e) {
      _petugasError = _bersihkan(e);
      _petugasStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchLogAkun(String userId) async {
    _logStatus = FetchStatus.loading;
    _logError = null;
    notifyListeners();

    final res = await ProfilService.getLogAkun(userId);

    if (res['success'] == true) {
      _log = res['data'] as Map<String, dynamic>?;
      _logStatus = FetchStatus.success;
    } else {
      _logError = res['message']?.toString();
      _logStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchActiveUser(String userId, {bool paksa = false}) async {
    if (!paksa &&
        _activeUserId == userId &&
        _activeUserStatus == FetchStatus.success) {
      return;
    }

    _activeUserStatus = FetchStatus.loading;
    _activeUserError = null;
    notifyListeners();

    final res = await ProfilService.getActiveUser(userId);

    if (res['success'] == true) {
      _activeUser = res['data'] as Map<String, dynamic>?;
      _activeUserId = userId;
      _activeUserStatus = FetchStatus.success;
    } else {
      _activeUserError = res['message']?.toString();
      _activeUserStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> updateProfil({
    required String userId,
    String? nama,
    String? noWhatsapp,
    File? photo,
  }) =>
      ProfilService.updateProfil(
        userId: userId,
        nama: nama,
        noWhatsapp: noWhatsapp,
        photo: photo,
      );
}
