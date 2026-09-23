import 'package:flutter/material.dart';
import '../models/bagi_hasil_model.dart';
import '../models/bagi_hasil_nasabah_model.dart';
import '../providers/penjualan_provider.dart' show FetchStatus;
import '../services/bagi_hasil_service.dart';

class BagiHasilProvider extends ChangeNotifier {
  // ── Preview ────────────────────────────────────────────────────────────────
  FetchStatus _previewStatus = FetchStatus.idle;
  PreviewBagiHasilModel? _preview;
  String? _previewError;

  FetchStatus get previewStatus => _previewStatus;
  PreviewBagiHasilModel? get preview => _preview;
  String? get previewError => _previewError;

  // ── Submit ─────────────────────────────────────────────────────────────────
  bool _submitting = false;
  String? _submitError;

  bool get submitting => _submitting;
  String? get submitError => _submitError;

  // ── Detail ─────────────────────────────────────────────────────────────────
  FetchStatus _detailStatus = FetchStatus.idle;
  DetailBagiHasilModel? _detail;
  String? _detailError;

  FetchStatus get detailStatus => _detailStatus;
  DetailBagiHasilModel? get detail => _detail;
  String? get detailError => _detailError;

  // ── Riwayat bagi hasil nasabah ─────────────────────────────────────────────
  FetchStatus _nasabahListStatus = FetchStatus.idle;
  List<BagiHasilNasabahItem> _nasabahList = [];
  String? _nasabahListError;

  FetchStatus get nasabahListStatus => _nasabahListStatus;
  List<BagiHasilNasabahItem> get nasabahList => _nasabahList;
  String? get nasabahListError => _nasabahListError;

  // ── Struk bagi hasil nasabah ───────────────────────────────────────────────
  FetchStatus _nasabahDetailStatus = FetchStatus.idle;
  BagiHasilNasabahDetail? _nasabahDetail;
  String? _nasabahDetailError;

  FetchStatus get nasabahDetailStatus => _nasabahDetailStatus;
  BagiHasilNasabahDetail? get nasabahDetail => _nasabahDetail;
  String? get nasabahDetailError => _nasabahDetailError;

  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchPreview(String penjualanId, String bankId) async {
    _previewStatus = FetchStatus.loading;
    _previewError = null;
    _preview = null;
    notifyListeners();

    final res = await BagiHasilService.previewBagiHasil(penjualanId, bankId);
    if (res['success'] == true && res['data'] != null) {
      _preview = PreviewBagiHasilModel.fromJson(
          res['data'] as Map<String, dynamic>);
      _previewStatus = FetchStatus.success;
    } else {
      _previewError = res['message']?.toString();
      _previewStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<bool> submitBagiHasil(String penjualanId, String bankId, String adminId) async {
    _submitting = true;
    _submitError = null;
    notifyListeners();

    final res = await BagiHasilService.submitBagiHasil(penjualanId, bankId, adminId);
    _submitting = false;
    if (res['success'] == true) {
      notifyListeners();
      return true;
    } else {
      _submitError = res['message']?.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchDetail(String penjualanId) async {
    _detailStatus = FetchStatus.loading;
    _detailError = null;
    _detail = null;
    notifyListeners();

    final res = await BagiHasilService.getDetailBagiHasil(penjualanId);
    if (res['success'] == true && res['data'] != null) {
      _detail = DetailBagiHasilModel.fromJson(
          res['data'] as Map<String, dynamic>);
      _detailStatus = FetchStatus.success;
    } else {
      _detailError = res['message']?.toString();
      _detailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  /// Riwayat bagi hasil milik seorang nasabah.
  ///
  /// ⚠️ Service mengembalikan body mentah, jadi daftarnya ada di
  /// `data['riwayat_bagi_hasil']` — bukan langsung `data` seperti di
  /// [fetchDetailNasabah].
  Future<void> fetchListNasabah(
    String nasabahId, {
    required String startDate,
    required String endDate,
  }) async {
    _nasabahListStatus = FetchStatus.loading;
    _nasabahListError = null;
    notifyListeners();

    final res = await BagiHasilService.getListBagiHasilNasabah(
      nasabahId,
      startDate: startDate,
      endDate: endDate,
    );

    if (res['success'] == true) {
      final body = res['data'] as Map<String, dynamic>? ?? {};
      _nasabahList = (body['riwayat_bagi_hasil'] as List? ?? [])
          .map((e) => BagiHasilNasabahItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _nasabahListStatus = FetchStatus.success;
    } else {
      _nasabahListError = res['message']?.toString();
      _nasabahListStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchDetailNasabah(String penerimaId) async {
    _nasabahDetailStatus = FetchStatus.loading;
    _nasabahDetailError = null;
    _nasabahDetail = null;
    notifyListeners();

    final res = await BagiHasilService.getDetailBagiHasilNasabah(penerimaId);

    if (res['success'] == true && res['data'] != null) {
      _nasabahDetail =
          BagiHasilNasabahDetail.fromJson(res['data'] as Map<String, dynamic>);
      _nasabahDetailStatus = FetchStatus.success;
    } else {
      _nasabahDetailError = res['message']?.toString();
      _nasabahDetailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  void resetPreview() {
    _previewStatus = FetchStatus.idle;
    _preview = null;
    _previewError = null;
    _submitting = false;
    _submitError = null;
    notifyListeners();
  }
}
