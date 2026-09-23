import 'dart:io';

import 'package:flutter/material.dart';

import '../models/setoran_model.dart';
import '../models/setoran_nasabah_model.dart';
import '../services/setoran_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

/// State untuk modul setoran (endpoint `/setoran`).
///
/// Tiap kebutuhan baca punya slice sendiri (status + data + error). Layar
/// memanggil `fetchX()` lalu menyalin hasilnya ke state lokalnya — provider yang
/// tahu cara fetch, parse, dan melapor error; layar memegang salinannya.
///
/// Pola salin itu penting buat [fetchDetail]: `DetailSetoranScreen` didorong
/// dari 5 tempat, jadi kalau dua layar detail sempat bertumpuk, fetch yang kedua
/// akan menimpa slice ini. Dengan disalin, tiap layar tetap memegang hasil
/// fetch-nya sendiri.
class SetoranProvider extends ChangeNotifier {
  // ── Riwayat setoran nasabah ────────────────────────────────────────────────
  FetchStatus _riwayatStatus = FetchStatus.idle;
  List<RiwayatSetoranModel> _riwayat = [];
  String? _riwayatError;

  FetchStatus get riwayatStatus => _riwayatStatus;
  List<RiwayatSetoranModel> get riwayat => _riwayat;
  String? get riwayatError => _riwayatError;

  // ── Detail satu setoran ────────────────────────────────────────────────────
  FetchStatus _detailStatus = FetchStatus.idle;
  SetoranDetailHeader? _detailHeader;
  List<SetoranItem> _detailItems = [];
  String? _detailError;

  FetchStatus get detailStatus => _detailStatus;
  SetoranDetailHeader? get detailHeader => _detailHeader;
  List<SetoranItem> get detailItems => _detailItems;
  String? get detailError => _detailError;

  // ── Preview sebelum setoran disimpan ───────────────────────────────────────
  FetchStatus _previewStatus = FetchStatus.idle;
  Map<String, dynamic>? _preview;
  String? _previewError;

  FetchStatus get previewStatus => _previewStatus;
  Map<String, dynamic>? get preview => _preview;
  String? get previewError => _previewError;

  // ───────────────────────────────────────────────────────────────────────────
  // Baca
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> fetchRiwayat(
    String nasabahId, {
    String? startDate,
    String? endDate,
  }) async {
    _riwayatStatus = FetchStatus.loading;
    _riwayatError = null;
    notifyListeners();

    final res = await SetoranService.getListSetoranNasabah(
      nasabahId,
      startDate: startDate,
      endDate: endDate,
    );

    if (res['success'] == true) {
      final data = res['data'] as List? ?? [];
      _riwayat = data.map((e) => RiwayatSetoranModel.fromJson(e)).toList();
      _riwayatStatus = FetchStatus.success;
    } else {
      _riwayatError = res['message']?.toString();
      _riwayatStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  /// Respons dibelah jadi dua: `data['header']` dan `data['items']`. Tidak ada
  /// model gabungan untuk keduanya, jadi disimpan sebagai dua field.
  Future<void> fetchDetail(String setoranId) async {
    _detailStatus = FetchStatus.loading;
    _detailError = null;
    _detailHeader = null;
    _detailItems = [];
    notifyListeners();

    final res = await SetoranService.getDetailSetoranNasabah(setoranId);

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      _detailHeader = SetoranDetailHeader.fromJson(data['header'] ?? {});
      _detailItems = (data['items'] as List? ?? [])
          .map((e) => SetoranItem.fromJson(e))
          .toList();
      _detailStatus = FetchStatus.success;
    } else {
      _detailError = res['message']?.toString();
      _detailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  /// Hasilnya `Map` mentah — belum ada model untuk respons preview, dan layarnya
  /// memang memakainya langsung sebagai map.
  Future<void> fetchPreview(
    String penimbanganId,
    String nasabahId,
    List<Map<String, dynamic>> items,
  ) async {
    _previewStatus = FetchStatus.loading;
    _previewError = null;
    _preview = null;
    notifyListeners();

    final res =
        await SetoranService.previewSetoran(penimbanganId, nasabahId, items);

    if (res['success'] == true) {
      _preview = res['data'] as Map<String, dynamic>?;
      _previewStatus = FetchStatus.success;
    } else {
      _previewError = res['message']?.toString();
      _previewStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Aksi — hasil diteruskan apa adanya, state tidak disentuh
  // ───────────────────────────────────────────────────────────────────────────

  /// Hasilnya langsung dipakai untuk navigasi (`nasabah_id`, `nama_nasabah`,
  /// `photo_url`), tidak ada yang perlu bertahan.
  Future<Map<String, dynamic>> verifikasiSetoran(
          String qrData, String adminId) =>
      SetoranService.verifikasiSetoran(qrData, adminId);

  Future<Map<String, dynamic>> inputSetoran(
    String penimbanganId,
    String nasabahId,
    String adminId,
    List<Map<String, dynamic>> items, {
    bool viaManual = false,
    File? fotoFile,
  }) =>
      SetoranService.inputSetoran(
        penimbanganId,
        nasabahId,
        adminId,
        items,
        viaManual: viaManual,
        fotoFile: fotoFile,
      );
}
