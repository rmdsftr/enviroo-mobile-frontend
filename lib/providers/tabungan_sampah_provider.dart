import 'package:flutter/material.dart';

import '../models/tabungan_sampah_model.dart';
import '../services/tabungan_sampah_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

/// State untuk endpoint `/tabungan-sampah`.
///
/// Dua slice terpisah karena bentuk datanya memang beda — buku tabungan nasabah
/// berisi kelompok setoran, buku tabungan BSU berisi kelompok pengangkutan.
/// Dipisah juga supaya tidak saling menimpa kalau suatu saat dipakai bersamaan.
class TabunganSampahProvider extends ChangeNotifier {
  // ── Buku tabungan nasabah ──────────────────────────────────────────────────
  FetchStatus _nasabahStatus = FetchStatus.idle;
  BukuTabunganResponse? _nasabah;
  String? _nasabahError;

  FetchStatus get nasabahStatus => _nasabahStatus;
  BukuTabunganResponse? get nasabah => _nasabah;
  String? get nasabahError => _nasabahError;

  // ── Buku tabungan BSU ──────────────────────────────────────────────────────
  FetchStatus _bsuStatus = FetchStatus.idle;
  BukuTabunganBsuResponse? _bsu;
  String? _bsuError;

  FetchStatus get bsuStatus => _bsuStatus;
  BukuTabunganBsuResponse? get bsu => _bsu;
  String? get bsuError => _bsuError;

  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchNasabah(
    String nasabahId, {
    String? startDate,
    String? endDate,
  }) async {
    _nasabahStatus = FetchStatus.loading;
    _nasabahError = null;
    notifyListeners();

    final res = await TabunganSampahService.getBukuTabungan(
      nasabahId,
      startDate: startDate,
      endDate: endDate,
    );

    if (res['success'] == true) {
      _nasabah = res['data'] as BukuTabunganResponse?;
      _nasabahStatus = FetchStatus.success;
    } else {
      _nasabahError = res['message']?.toString();
      _nasabahStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchBsu(
    String bsuId, {
    String? startDate,
    String? endDate,
  }) async {
    _bsuStatus = FetchStatus.loading;
    _bsuError = null;
    notifyListeners();

    final res = await TabunganSampahService.getBukuTabunganBsu(
      bsuId,
      startDate: startDate,
      endDate: endDate,
    );

    if (res['success'] == true) {
      _bsu = res['data'] as BukuTabunganBsuResponse?;
      _bsuStatus = FetchStatus.success;
    } else {
      _bsuError = res['message']?.toString();
      _bsuStatus = FetchStatus.error;
    }
    notifyListeners();
  }
}
