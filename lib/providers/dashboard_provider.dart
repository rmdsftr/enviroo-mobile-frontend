import 'package:flutter/foundation.dart';
import '../models/dashboard_petugas_model.dart';
import '../services/dashboard_service.dart';
import '../providers/auth_provider.dart';

class DashboardProvider with ChangeNotifier {
  DashboardPetugasModel? _dashboardData;
  bool _isLoading = false;
  String _error = '';

  DashboardPetugasModel? get dashboardData => _dashboardData;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchDashboardPetugas(AuthProvider authProvider) async {
    if (authProvider.bankId == null) {
      _error = 'Anda belum login atau bank tidak ditemukan.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await DashboardService.getDashboardPetugas(authProvider.bankId!);
      if (response['success'] == true) {
        _dashboardData = DashboardPetugasModel.fromJson(response['data']);
      } else {
        _error = response['message'] ?? 'Gagal memuat data dashboard';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _saldoRefreshToken = 0;
  int get saldoRefreshToken => _saldoRefreshToken;

  void requestSaldoRefresh() {
    _saldoRefreshToken++;
    notifyListeners();
  }
}
