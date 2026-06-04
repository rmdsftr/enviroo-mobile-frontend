import 'package:flutter/material.dart';
import '../models/distribusi_sisa_model.dart';
import '../providers/penjualan_provider.dart' show FetchStatus;
import '../services/distribusi_sisa_service.dart';

class DistribusiSisaProvider extends ChangeNotifier {
  FetchStatus _previewStatus = FetchStatus.idle;
  PreviewDistribusiSisaModel? _preview;
  String? _previewError;
  bool _alreadyDistributed = false;
  String? _existingDistribusiId;

  FetchStatus get previewStatus => _previewStatus;
  PreviewDistribusiSisaModel? get preview => _preview;
  String? get previewError => _previewError;
  bool get alreadyDistributed => _alreadyDistributed;
  String? get existingDistribusiId => _existingDistribusiId;

  bool _submitting = false;
  String? _submitError;
  String? _newDistribusiId;

  bool get submitting => _submitting;
  String? get submitError => _submitError;
  String? get newDistribusiId => _newDistribusiId;

  FetchStatus _detailStatus = FetchStatus.idle;
  DetailDistribusiSisaModel? _detail;
  String? _detailError;

  FetchStatus get detailStatus => _detailStatus;
  DetailDistribusiSisaModel? get detail => _detail;
  String? get detailError => _detailError;

  Future<void> fetchPreview(String bagiHasilId) async {
    _previewStatus = FetchStatus.loading;
    _previewError = null;
    _preview = null;
    _alreadyDistributed = false;
    _existingDistribusiId = null;
    notifyListeners();

    final res = await DistribusiSisaService.previewDistribusiSisa(bagiHasilId);
    if (res['success'] == true && res['data'] != null) {
      _preview = PreviewDistribusiSisaModel.fromJson(res['data'] as Map<String, dynamic>);
      _previewStatus = FetchStatus.success;
    } else if (res['already_distributed'] == true) {
      _alreadyDistributed = true;
      _existingDistribusiId = res['distribusi_id']?.toString();
      _previewStatus = FetchStatus.error;
    } else {
      _previewError = res['message']?.toString();
      _previewStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  Future<bool> submitDistribusiSisa(
    String bagiHasilId,
    String adminId,
    List<Map<String, dynamic>> pengirimanBsu,
  ) async {
    _submitting = true;
    _submitError = null;
    _newDistribusiId = null;
    notifyListeners();

    final res = await DistribusiSisaService.submitDistribusiSisa(bagiHasilId, adminId, pengirimanBsu);
    _submitting = false;
    if (res['success'] == true) {
      _newDistribusiId = res['distribusi_id']?.toString();
      notifyListeners();
      return true;
    } else {
      _submitError = res['message']?.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchDetail(String distribusiId) async {
    _detailStatus = FetchStatus.loading;
    _detailError = null;
    _detail = null;
    notifyListeners();

    final res = await DistribusiSisaService.getDetailDistribusiSisa(distribusiId);
    if (res['success'] == true && res['data'] != null) {
      _detail = DetailDistribusiSisaModel.fromJson(res['data'] as Map<String, dynamic>);
      _detailStatus = FetchStatus.success;
    } else {
      _detailError = res['message']?.toString();
      _detailStatus = FetchStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _previewStatus = FetchStatus.idle;
    _preview = null;
    _previewError = null;
    _alreadyDistributed = false;
    _existingDistribusiId = null;
    _submitting = false;
    _submitError = null;
    _newDistribusiId = null;
    notifyListeners();
  }
}
