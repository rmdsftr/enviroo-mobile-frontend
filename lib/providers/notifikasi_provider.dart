import 'package:flutter/material.dart';
import '../models/notifikasi_model.dart';
import '../services/notifikasi_service.dart';

class NotifikasiProvider extends ChangeNotifier {
  List<NotifikasiModel> _notifikasi = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotifikasiModel> get notifikasi => _notifikasi;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifikasi.where((n) => !n.isRead).length;

  Future<void> fetchNotifikasi({required String userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await NotifikasiService.getNotifikasi(userId);

    _isLoading = false;
    if (result['success'] == true) {
      _notifikasi = List<NotifikasiModel>.from(result['data']);
    } else {
      _errorMessage = result['message'];
    }
    notifyListeners();
  }

  Future<void> markAsRead({required String notifId}) async {
    _notifikasi = _notifikasi
        .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();

    await NotifikasiService.markAsRead(notifId);
  }

  Future<void> markAllAsRead({required String userId}) async {
    final result = await NotifikasiService.markAllAsRead(userId);
    if (result['success'] == true) {
      _notifikasi = _notifikasi.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  Future<void> registerFcmToken({required String fcmToken}) async {
    await NotifikasiService.registerFcmToken(fcmToken);
  }
}
