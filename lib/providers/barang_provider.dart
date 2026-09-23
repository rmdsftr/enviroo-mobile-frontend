import 'package:enviroo/models/bsu_unit_model.dart';
import 'package:enviroo/models/katalog_model.dart';
import 'package:enviroo/services/nasabah_service.dart';
import 'package:enviroo/services/sembako_service.dart';
import 'package:flutter/material.dart';

class SembakoProvider extends ChangeNotifier {
  // ── Catalog state ──────────────────────────────────────────────────────────
  List<KatalogSembakoModel> _katalogBsi = [];
  List<KatalogSembakoModel> _katalogBsu = [];

  // ── Pagination state (katalogBsi) ─────────────────────────────────────────
  int _katalogBsiPage = 1;
  int _katalogBsiTotalPages = 1;
  List<BsuUnitModel> _bsuList = [];
  BsuUnitModel? _selectedBsu;

  // ── Detail state ──────────────────────────────────────────────────────────
  DetailSembakoWithRiwayat? _currentDetail;
  bool _isDetailLoading = false;

  // ── Preview state ─────────────────────────────────────────────────────────
  List<PreviewDistribusiItemModel> _previewItems = [];
  bool _isPreviewLoading = false;

  // ── Input distribusi state ────────────────────────────────────────────────
  final Map<String, int> _distribusiQty = {}; // sembakoId -> qty

  // ── List distribusi state ─────────────────────────────────────────────────
  List<ListDistribusiSembakoModel> _listDistribusi = [];
  bool _isListDistribusiLoading = false;

  // ── Loading / error ───────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isBsuLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<KatalogSembakoModel> get katalogBsi => _katalogBsi;
  List<KatalogSembakoModel> get katalogBsu => _katalogBsu;
  List<BsuUnitModel> get bsuList => _bsuList;
  BsuUnitModel? get selectedBsu => _selectedBsu;

  DetailSembakoWithRiwayat? get currentDetail => _currentDetail;
  bool get isDetailLoading => _isDetailLoading;

  List<PreviewDistribusiItemModel> get previewItems => _previewItems;
  bool get isPreviewLoading => _isPreviewLoading;

  List<ListDistribusiSembakoModel> get listDistribusi => _listDistribusi;
  bool get isListDistribusiLoading => _isListDistribusiLoading;

  Map<String, int> get distribusiQty => Map.unmodifiable(_distribusiQty);
  int get totalDistribusiItems => _distribusiQty.values.fold(0, (sum, v) => sum + v);
  bool get hasDistribusiItems => _distribusiQty.values.any((v) => v > 0);

  int get katalogBsiPage => _katalogBsiPage;
  int get katalogBsiTotalPages => _katalogBsiTotalPages;

  bool get isLoading => _isLoading;
  bool get isBsuLoading => _isBsuLoading;
  String? get errorMessage => _errorMessage;

  // ── Catalog methods ───────────────────────────────────────────────────────

  Future<void> fetchKatalogBsi(String bankId, {int page = 1}) async {
    _katalogBsiPage = page;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await SembakoService.getSembakoBank(bankId, page: page);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _katalogBsi = data.map((e) => KatalogSembakoModel.fromJson(e as Map<String, dynamic>)).toList();
      final pag = result['pagination'] as Map<String, dynamic>?;
      _katalogBsiTotalPages = (pag?['total_pages'] as num?)?.toInt() ?? 1;
      _katalogBsiPage = (pag?['page'] as num?)?.toInt() ?? page;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchKatalogBsu(String bsuId) async {
    _isBsuLoading = true;
    notifyListeners();

    final result = await SembakoService.getSembakoBank(bsuId);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _katalogBsu = data.map((e) => KatalogSembakoModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isBsuLoading = false;
    notifyListeners();
  }

  Future<void> fetchBsuList(String bsiId) async {
    final result = await NasabahService.getBsuByBsiId(bsiId);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _bsuList = data.map((e) => BsuUnitModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      _errorMessage = result['message'];
    }

    notifyListeners();
  }

  void setSelectedBsu(BsuUnitModel? bsu) {
    _selectedBsu = bsu;
    if (bsu == null) _katalogBsu = [];
    notifyListeners();
  }

  // ── Detail methods ────────────────────────────────────────────────────────

  Future<void> fetchDetailSembako(String sembakoId, KatalogSembakoModel item, String bankId) async {
    _isDetailLoading = true;
    _currentDetail = null;
    notifyListeners();

    final result = await SembakoService.getDetailSembako(sembakoId, bankId);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final riwayatJson = data['riwayat_distribusi'] as List<dynamic>? ?? [];
      _currentDetail = DetailSembakoWithRiwayat(
        sembako: item,
        riwayatDistribusi: riwayatJson
            .map((e) => RiwayatDistribusiSembakoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } else {
      _errorMessage = result['message'];
    }

    _isDetailLoading = false;
    notifyListeners();
  }

  void setDetailDirect(KatalogSembakoModel item) {
    _currentDetail = DetailSembakoWithRiwayat(sembako: item, riwayatDistribusi: []);
    _isDetailLoading = false;
    notifyListeners();
  }

  // ── List distribusi methods ───────────────────────────────────────────────

  Future<void> fetchListDistribusi(String bankId, {String? startDate, String? endDate}) async {
    _isListDistribusiLoading = true;
    notifyListeners();

    final result = await SembakoService.getListDistribusi(bankId, startDate: startDate, endDate: endDate);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _listDistribusi = data
          .map((e) => ListDistribusiSembakoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _errorMessage = result['message'];
    }

    _isListDistribusiLoading = false;
    notifyListeners();
  }

  // ── Input distribusi methods ──────────────────────────────────────────────

  void updateDistribusiQty(String sembakoId, int qty) {
    if (qty <= 0) {
      _distribusiQty.remove(sembakoId);
    } else {
      _distribusiQty[sembakoId] = qty;
    }
    notifyListeners();
  }

  int getDistribusiQty(String sembakoId) => _distribusiQty[sembakoId] ?? 0;

  void clearDistribusiItems() {
    _distribusiQty.clear();
    notifyListeners();
  }

  // ── Preview distribusi ────────────────────────────────────────────────────

  Future<bool> previewDistribusi({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
  }) async {
    _isPreviewLoading = true;
    _errorMessage = null;
    notifyListeners();

    final items = _distribusiQty.entries
        .map((e) => {'produk_id': e.key, 'stok': e.value})
        .toList();

    final result = await SembakoService.previewDistribusiBsu(
      bsiId: bsiId,
      bsuId: bsuId,
      adminBsiId: adminBsiId,
      items: items,
    );

    bool ok = false;
    if (result['success'] == true) {
      final List<dynamic> data = (result['data'] as List<dynamic>? ?? []);
      _previewItems = data
          .map((e) => PreviewDistribusiItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      ok = true;
    } else {
      _errorMessage = result['message'];
    }

    _isPreviewLoading = false;
    notifyListeners();
    return ok;
  }

  // ── Generate QR distribusi ───────────────────────────────────────────────

  Future<Map<String, dynamic>> generateQrDistribusi({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
  }) async {
    final items = _previewItems
        .map((e) => {'produk_id': e.sembakoId, 'stok': e.stokKirim})
        .toList();
    return SembakoService.generateQrDistribusi(
      bsiId: bsiId,
      bsuId: bsuId,
      adminBsiId: adminBsiId,
      items: items,
    );
  }

  // ── Add distribusi ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> addDistribusi({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
    required String adminBsuId,
  }) async {
    final items = _distribusiQty.entries
        .map((e) => {'produk_id': e.key, 'stok': e.value})
        .toList();

    final result = await SembakoService.addDistribusiBsu(
      bsiId: bsiId,
      bsuId: bsuId,
      adminBsiId: adminBsiId,
      adminBsuId: adminBsuId,
      items: items,
    );

    if (result['success'] == true) {
      clearDistribusiItems();
    } else {
      _errorMessage = result['message'];
      notifyListeners();
    }

    return result;
  }

  // ── Add distribusi from QR (BSU side) ────────────────────────────────────

  Future<Map<String, dynamic>> addDistribusiFromQr({
    required String disbakoId,
    required String bsuId,
    required String adminBsuId,
  }) async {
    final result = await SembakoService.addDistribusiBsuFromQr(
      disbakoId: disbakoId,
      bsuId: bsuId,
      adminBsuId: adminBsuId,
    );

    if (result['success'] != true) {
      _errorMessage = result['message'];
      notifyListeners();
    }

    return result;
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
