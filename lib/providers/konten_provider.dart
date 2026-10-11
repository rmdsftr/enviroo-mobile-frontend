import 'package:flutter/material.dart';
import '../models/konten_model.dart';
import '../services/konten_service.dart';

class KontenProvider extends ChangeNotifier {
  List<KontenModel> _kontenList = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;

  String _lastBankId = '';
  bool? _lastPublished;

  List<KontenModel> get kontenList => _kontenList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> fetchKonten(
    String bankId, {
    bool? published,
    int page = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastBankId = bankId;
    _lastPublished = published;
    notifyListeners();

    final result = await KontenService.getAllKonten(
      bankId,
      published: published,
      page: page,
    );

    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      _kontenList = data.map((json) => KontenModel.fromJson(json)).toList();

      final pagination = result['pagination'] as Map<String, dynamic>?;
      if (pagination != null) {
        _currentPage = pagination['page'] ?? 1;
        _totalPages = pagination['total_pages'] ?? 1;
      }
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    await fetchKonten(_lastBankId, published: _lastPublished, page: page);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
