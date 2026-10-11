import 'dart:io';

import 'package:flutter/material.dart';

import '../models/setoran_model.dart';
import '../models/setoran_nasabah_model.dart';
import '../services/setoran_service.dart';
import 'penjualan_provider.dart' show FetchStatus;

class SetoranProvider extends ChangeNotifier {
  FetchStatus _riwayatStatus = FetchStatus.idle;
  List<RiwayatSetoranModel> _riwayat = [];
  String? _riwayatError;

  FetchStatus get riwayatStatus => _riwayatStatus;
  List<RiwayatSetoranModel> get riwayat => _riwayat;
  String? get riwayatError => _riwayatError;

  FetchStatus _detailStatus = FetchStatus.idle;
  SetoranDetailHeader? _detailHeader;
  List<SetoranItem> _detailItems = [];
  String? _detailError;

  FetchStatus get detailStatus => _detailStatus;
  SetoranDetailHeader? get detailHeader => _detailHeader;
  List<SetoranItem> get detailItems => _detailItems;
  String? get detailError => _detailError;

  FetchStatus _previewStatus = FetchStatus.idle;
  Map<String, dynamic>? _preview;
  String? _previewError;

  FetchStatus get previewStatus => _previewStatus;
  Map<String, dynamic>? get preview => _preview;
  String? get previewError => _previewError;

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
