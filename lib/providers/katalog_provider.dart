import 'package:flutter/material.dart';
import '../models/katalog_model.dart';
import '../models/katalog_history_model.dart';
import '../services/katalog_service.dart';

class KatalogProvider extends ChangeNotifier {
  List<KatalogSampahModel> _katalogSampah = [];
  List<KatalogSembakoModel> _katalogSembako = [];
  List<KategoriSampahModel> _categories = [];
  Map<String, List<KatalogHistoryModel>> _historyCache = {};
  bool _isLoading = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;

  List<KatalogSampahModel> get katalogSampah => _katalogSampah;
  List<KatalogSembakoModel> get katalogSembako => _katalogSembako;
  List<KategoriSampahModel> get categories => _categories;
  Map<String, List<KatalogHistoryModel>> get historyCache => _historyCache;
  bool get isLoading => _isLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await KatalogService.getKategori(token);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _categories = data.map((json) => KategoriSampahModel.fromJson(json)).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchKatalogSampah(String bankId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await KatalogService.getKatalogSampah(bankId, token);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _katalogSampah = data.map((json) => KatalogSampahModel.fromJson(json)).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchKatalogSembako(String bankId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await KatalogService.getKatalogSembako(bankId, token);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _katalogSembako = data.map((json) => KatalogSembakoModel.fromJson(json)).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Optional metadata: Fetch both
  Future<void> fetchAll(String bankId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      KatalogService.getKatalogSampah(bankId, token),
      KatalogService.getKatalogSembako(bankId, token),
      KatalogService.getKategori(token),
    ]);

    final sampahResult = results[0];
    final sembakoResult = results[1];
    final kategoriResult = results[2];

    if (sampahResult['success'] == true) {
      final List<dynamic> data = sampahResult['data'];
      _katalogSampah = data.map((json) => KatalogSampahModel.fromJson(json)).toList();
    } else {
      _errorMessage = sampahResult['message'];
    }

    if (sembakoResult['success'] == true) {
      final List<dynamic> data = sembakoResult['data'];
      _katalogSembako = data.map((json) => KatalogSembakoModel.fromJson(json)).toList();
    } else {
      // Don't overwrite error if already set by sampah
      _errorMessage ??= sembakoResult['message'];
    }

    if (kategoriResult['success'] == true) {
      final List<dynamic> data = kategoriResult['data'];
      _categories = data.map((json) => KategoriSampahModel.fromJson(json)).toList();
    } else {
      // Don't overwrite error if already set
      _errorMessage ??= kategoriResult['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(String sampahId, String token) async {
    _isHistoryLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await KatalogService.getKatalogHistory(sampahId, token);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _historyCache[sampahId] = data.map((json) => KatalogHistoryModel.fromJson(json)).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isHistoryLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
