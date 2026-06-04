import 'package:flutter/foundation.dart';
import '../models/nasabah_model.dart';
import '../services/nasabah_service.dart';
import '../providers/auth_provider.dart';

class NasabahProvider with ChangeNotifier {
  List<NasabahModel> _nasabahs = [];
  bool _isLoading = false;
  String _error = '';

  List<NasabahModel> get nasabahs => _nasabahs;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchNasabahs(AuthProvider authProvider) async {
    if (authProvider.bankId == null) {
      _error = 'Anda belum login atau bank tidak ditemukan.';
      notifyListeners();
      return;
    }
    await _fetchByBankId(authProvider.bankId!);
  }

  Future<void> fetchNasabahsByBankId(String bankId) async {
    await _fetchByBankId(bankId);
  }

  Future<void> _fetchByBankId(String bankId) async {
    _isLoading = true;
    _error = '';
    _nasabahs = [];
    notifyListeners();

    try {
      final response = await NasabahService.getNasabahByBankId(bankId);
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _nasabahs = data.map((json) => NasabahModel.fromJson(json)).toList();
      } else {
        _error = response['message'] ?? 'Gagal memuat data nasabah';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get totalSemua => _nasabahs.length;
  int get totalAktif => _nasabahs.where((n) => n.statusNasabah.toLowerCase() == 'aktif').length;
  int get totalNonaktif => _nasabahs.where((n) => n.statusNasabah.toLowerCase() == 'nonaktif').length;
  int get totalPending => _nasabahs.where((n) => n.statusNasabah.toLowerCase() == 'pending').length;
}
