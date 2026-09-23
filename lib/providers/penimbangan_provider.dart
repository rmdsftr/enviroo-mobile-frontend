import 'package:flutter/material.dart';

import '../models/penimbangan_model.dart';
import '../services/penimbangan_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

/// State untuk modul penimbangan (endpoint `/penimbangan`).
///
/// Tiap kebutuhan baca punya slice sendiri (status + data + error). Ini bukan
/// gaya-gayaan: `PenimbanganScreen` mendorong `PenimbanganAktifScreen`, jadi
/// keduanya hidup bersamaan di stack. Kalau berbagi satu slot data, fetch milik
/// layar anak akan menimpa data layar induk dan tampilan induk berubah diam-diam
/// saat user menekan tombol kembali.
///
/// Aksi (update/batal) sengaja dibiarkan meneruskan hasil apa adanya: semuanya
/// sekali-jalan tanpa data yang perlu bertahan, dan layar pemanggilnya sudah
/// punya flag loading sendiri. `updatePenimbangan` malah dipanggil dari dua
/// layar yang hidup bersamaan — satu flag di provider tidak bisa melayani
/// keduanya.
class PenimbanganProvider extends ChangeNotifier {
  // ── Riwayat sesi ───────────────────────────────────────────────────────────
  FetchStatus _riwayatStatus = FetchStatus.idle;
  List<SessionData> _riwayat = [];
  String? _riwayatError;

  FetchStatus get riwayatStatus => _riwayatStatus;
  List<SessionData> get riwayat => _riwayat;
  String? get riwayatError => _riwayatError;

  // ── Sesi aktif hari ini ────────────────────────────────────────────────────
  FetchStatus _sesiAktifStatus = FetchStatus.idle;
  CheckActiveResult? _sesiAktif;
  String? _sesiAktifError;

  FetchStatus get sesiAktifStatus => _sesiAktifStatus;
  CheckActiveResult? get sesiAktif => _sesiAktif;
  String? get sesiAktifError => _sesiAktifError;

  // ── Daftar sesi hari ini ───────────────────────────────────────────────────
  FetchStatus _sesiHariIniStatus = FetchStatus.idle;
  List<SesiHariIniItem> _sesiHariIni = [];
  String? _sesiHariIniError;

  FetchStatus get sesiHariIniStatus => _sesiHariIniStatus;
  List<SesiHariIniItem> get sesiHariIni => _sesiHariIni;
  String? get sesiHariIniError => _sesiHariIniError;

  // ── Detail satu sesi (isi layar sesi aktif) ────────────────────────────────
  FetchStatus _detailStatus = FetchStatus.idle;
  SesiPenimbanganAktif? _detail;
  String? _detailError;

  FetchStatus get detailStatus => _detailStatus;
  SesiPenimbanganAktif? get detail => _detail;
  String? get detailError => _detailError;

  // ───────────────────────────────────────────────────────────────────────────
  // Baca
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchRiwayat(String bankId,
      {String? startDate, String? endDate}) async {
    _riwayatStatus = FetchStatus.loading;
    _riwayatError = null;
    notifyListeners();

    final res = await PenimbanganService.getPenimbangan(bankId,
        startDate: startDate, endDate: endDate);

    if (res['success'] == true) {
      final data = res['data'] as List? ?? [];
      _riwayat = data
          .map((e) => SessionData.fromJson(e as Map<String, dynamic>))
          .toList();
      _riwayatStatus = FetchStatus.success;
    } else {
      _riwayatError = res['message']?.toString();
      _riwayatStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchSesiAktif(String bankId) async {
    _sesiAktifStatus = FetchStatus.loading;
    _sesiAktifError = null;
    notifyListeners();

    final res = await PenimbanganService.checkActiveSession(bankId);

    if (res['success'] == true && res['data'] != null) {
      _sesiAktif = res['data'] as CheckActiveResult;
      _sesiAktifStatus = FetchStatus.success;
    } else {
      _sesiAktif = null;
      _sesiAktifError = res['message']?.toString();
      _sesiAktifStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchSesiHariIni(String bankId) async {
    _sesiHariIniStatus = FetchStatus.loading;
    _sesiHariIniError = null;
    notifyListeners();

    final res = await PenimbanganService.getSesiHariIni(bankId);

    if (res['success'] == true) {
      _sesiHariIni = (res['data'] as List? ?? []).cast<SesiHariIniItem>();
      _sesiHariIniStatus = FetchStatus.success;
    } else {
      _sesiHariIniError = res['message']?.toString();
      _sesiHariIniStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  /// Detail sesi + daftar setoran di dalamnya.
  Future<void> fetchDetail(String penimbanganId) async {
    _detailStatus = FetchStatus.loading;
    _detailError = null;
    _detail = null;
    notifyListeners();

    final res = await PenimbanganService.getListSetoran(penimbanganId);

    if (res['success'] == true && res['data'] != null) {
      _detail =
          SesiPenimbanganAktif.fromJson(res['data'] as Map<String, dynamic>);
      _detailStatus = FetchStatus.success;
    } else {
      _detailError = res['message']?.toString();
      _detailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Aksi — hasil diteruskan apa adanya, state tidak disentuh
  // ───────────────────────────────────────────────────────────────────────────

  /// Versi mentah dari [fetchDetail], untuk layar yang mem-parse isi sesi
  /// dengan bentuk berbeda (`SetoranSummary` + header mentah).
  ///
  /// Tidak memakai slice [detail] karena kedua pemakainya sama-sama anak dari
  /// `PenimbanganScreen` dan bisa hidup bersamaan — berbagi satu slot akan
  /// membuat keduanya saling menimpa.
  Future<Map<String, dynamic>> getListSetoran(String penimbanganId) =>
      PenimbanganService.getListSetoran(penimbanganId);

  Future<Map<String, dynamic>> updateStatus(
          String penimbanganId, String status) =>
      PenimbanganService.updatePenimbangan(penimbanganId, status);

  Future<Map<String, dynamic>> batalkanSesi(
          String penimbanganId, String alasan) =>
      PenimbanganService.batalkanPenimbangan(penimbanganId, alasan);

  /// Batalkan jadwal mendatang yang belum dimulai — beda dari [batalkanSesi]
  /// yang membatalkan sesi yang sudah aktif.
  Future<Map<String, dynamic>> batalkanJadwal({
    required String jadwalId,
    required String tanggalSesi,
    required String alasanPembatalan,
  }) =>
      PenimbanganService.batalkanJadwalPenimbangan(
        jadwalId: jadwalId,
        tanggalSesi: tanggalSesi,
        alasanPembatalan: alasanPembatalan,
      );
}
