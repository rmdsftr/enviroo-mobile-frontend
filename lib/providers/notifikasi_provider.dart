import 'package:flutter/material.dart';
import '../models/notifikasi_model.dart';
import '../services/notifikasi_service.dart';

class NotifikasiProvider extends ChangeNotifier {
  List<NotifikasiModel> _notifikasi = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  String _roleTarget = 'nasabah';

  List<NotifikasiModel> get notifikasi => _notifikasi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifikasi.where((n) => !n.isRead).length;

  // Khusus nasabah: ref_type 'penimbangan'/'jadwal_penimbangan' udah punya
  // "inbox" sendiri di ChatInfoBankSampahScreen, jadi gak perlu ikut dihitung
  // di badge notif topbar biar gak keitung dobel.
  int unreadCountFor(String role) => _notifikasi.where((n) {
        if (n.isRead) return false;
        if (role == 'nasabah' && n.isChatInfoBank) return false;
        return true;
      }).length;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  Future<void> fetchNotifikasi({required String role, int page = 1}) async {
    _roleTarget = role == 'nasabah' ? 'nasabah' : 'admin';
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await NotifikasiService.getNotifikasi(_roleTarget, page: page);

    _isLoading = false;
    if (result['success'] == true) {
      _notifikasi = List<NotifikasiModel>.from(result['data']);
      final meta = result['meta'] as Map<String, dynamic>?;
      if (meta != null) {
        _currentPage = (meta['page'] as num?)?.toInt() ?? page;
        _totalPages = (meta['total_halaman'] as num?)?.toInt() ?? 1;
      } else {
        _currentPage = page;
        _totalPages = 1;
      }
    } else {
      _errorMessage = result['message'];
    }
    notifyListeners();
  }

  Future<void> goToPage(int page) async {
    await fetchNotifikasi(role: _roleTarget, page: page);
  }

  Future<void> markAsRead({required String notifId}) async {
    _notifikasi = _notifikasi
        .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();

    await NotifikasiService.markAsRead(notifId);
  }

  Future<void> markAllAsRead() async {
    final result = await NotifikasiService.markAllAsRead();
    if (result['success'] == true) {
      _notifikasi = _notifikasi.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  Future<void> registerFcmToken({required String fcmToken}) async {
    await NotifikasiService.registerFcmToken(fcmToken);
  }
}
