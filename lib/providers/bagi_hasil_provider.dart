import 'package:flutter/material.dart';
import '../models/bagi_hasil_model.dart';
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

  void resetPreview() {
    _previewStatus = FetchStatus.idle;
    _preview = null;
    _previewError = null;
    _submitting = false;
    _submitError = null;
    notifyListeners();
  }
}
