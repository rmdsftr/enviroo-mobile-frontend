import 'package:flutter/material.dart';
import '../models/konten_model.dart';
import '../services/konten_service.dart';

class KontenProvider extends ChangeNotifier {
  List<KontenModel> _kontenList = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<KontenModel> get kontenList => _kontenList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchKonten(String bankId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await KontenService.getAllKonten(bankId, token);

    if (result['success'] == true) {
      final List<dynamic> data = result['data'];
      _kontenList = data.map((json) => KontenModel.fromJson(json)).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
