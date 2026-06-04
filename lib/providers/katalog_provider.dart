import 'package:flutter/material.dart';
import '../models/katalog_model.dart';
import '../services/katalog_service.dart';

class KatalogProvider extends ChangeNotifier {
  List<KatalogSampahModel> _katalogSampah = [];
  List<KatalogSembakoModel> _katalogSembako = [];
  List<KategoriSampahModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  DetailSampahModel? _currentDetail;
  bool _isDetailLoading = false;

  List<KatalogSampahModel> get katalogSampah => _katalogSampah;
  List<KatalogSembakoModel> get katalogSembako => _katalogSembako;
  List<KategoriSampahModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DetailSampahModel? get currentDetail => _currentDetail;
  bool get isDetailLoading => _isDetailLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await KatalogService.getKategori();
      if (result['success'] == true) {
        final data = result['data'] as List? ?? [];
        _categories = data.map((json) => KategoriSampahModel.fromJson(json)).toList();
      } else {
        _errorMessage = result['message']?.toString();
      }
    } catch (_) {
      _errorMessage = 'Gagal memuat kategori';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchKatalogSampah(String bankId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await KatalogService.getKatalogSampah(bankId);
      if (result['success'] == true) {
        final data = result['data'] as List? ?? [];
        _katalogSampah = data.map((json) => KatalogSampahModel.fromJson(json)).toList();
      } else {
        _errorMessage = result['message']?.toString();
      }
    } catch (_) {
      _errorMessage = 'Gagal memuat katalog';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAll(String bankId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        KatalogService.getKatalogSampah(bankId),
        KatalogService.getKategori(),
      ]);

      final sampahResult = results[0];
      final kategoriResult = results[1];

      if (sampahResult['success'] == true) {
        final data = sampahResult['data'] as List? ?? [];
        _katalogSampah = data.map((json) => KatalogSampahModel.fromJson(json)).toList();
      } else {
        _errorMessage = sampahResult['message']?.toString();
      }

      if (kategoriResult['success'] == true) {
        final data = kategoriResult['data'] as List? ?? [];
        _categories = data.map((json) => KategoriSampahModel.fromJson(json)).toList();
      } else {
        _errorMessage ??= kategoriResult['message']?.toString();
      }
    } catch (_) {
      _errorMessage = 'Gagal memuat katalog';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDetailSampah(String sampahId) async {
    _isDetailLoading = true;
    _currentDetail = null;
    notifyListeners();

    try {
      final result = await KatalogService.getDetailSampah(sampahId);
      if (result['success'] == true && result['data'] != null) {
        _currentDetail = DetailSampahModel.fromJson(result['data'] as Map<String, dynamic>);
      } else {
        _errorMessage = result['message']?.toString();
      }
    } catch (_) {
      _errorMessage = 'Gagal memuat detail';
    } finally {
      _isDetailLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> silentRefresh(String bankId) async {
    try {
      final sampahResult = await KatalogService.getKatalogSampah(bankId);
      if (sampahResult['success'] == true) {
        final data = sampahResult['data'] as List? ?? [];
        _katalogSampah = data.map((json) => KatalogSampahModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (_) {}

    if (_currentDetail != null) {
      try {
        final detailResult = await KatalogService.getDetailSampah(_currentDetail!.sampahId);
        if (detailResult['success'] == true && detailResult['data'] != null) {
          _currentDetail = DetailSampahModel.fromJson(detailResult['data'] as Map<String, dynamic>);
          notifyListeners();
        }
      } catch (_) {}
    }
  }
}
