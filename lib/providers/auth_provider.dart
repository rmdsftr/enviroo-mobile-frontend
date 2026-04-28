import 'package:enviroo/models/nasabah_profile_model.dart';
import 'package:enviroo/models/petugas_model.dart';
import 'package:enviroo/models/user_model.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key-key yang digunakan untuk menyimpan sesi di SharedPreferences
class _K {
  static const userId = 'auth_user_id';
  static const email = 'auth_email';
  static const nama = 'auth_nama';
  static const role = 'auth_role';
  static const bankId = 'auth_bank_id';
  static const identityId = 'auth_identity_id';
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';
}

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  NasabahProfileModel? _nasabahProfile;
  PetugasModel? _petugasProfile;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  NasabahProfileModel? get nasabahProfile => _nasabahProfile;
  PetugasModel? get petugasProfile => _petugasProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // Convenience getters
  String get role => _currentUser?.role ?? '';
  String get nama => _petugasProfile?.nama ?? _nasabahProfile?.nama ?? _currentUser?.nama ?? 'Tamu';
  String get userId => _currentUser?.userId ?? '';
  String? get bankId => _petugasProfile?.bankId ?? _currentUser?.bankId;
  String? get identityId => _currentUser?.identityId;
  String? get bsuName => _nasabahProfile?.namaBsu;

  // New Profile Getter
  int get saldoPoin => _nasabahProfile?.saldoPoin ?? 0;
  String get nomorRekening => _nasabahProfile?.nomorRekening ?? '-';

  // ─── Persistensi sesi ──────────────────────────────────────────────────────

  /// Simpan sesi login ke SharedPreferences
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_K.userId, user.userId);
    await prefs.setString(_K.email, user.email);
    await prefs.setString(_K.nama, user.nama);
    await prefs.setString(_K.role, user.role);
    await prefs.setString(_K.bankId, user.bankId ?? '');
    await prefs.setString(_K.identityId, user.identityId ?? '');
    await prefs.setString(_K.accessToken, user.accessToken);
    await prefs.setString(_K.refreshToken, user.refreshToken);
  }

  /// Hapus sesi dari SharedPreferences (saat logout)
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_K.userId);
    await prefs.remove(_K.email);
    await prefs.remove(_K.nama);
    await prefs.remove(_K.role);
    await prefs.remove(_K.bankId);
    await prefs.remove(_K.identityId);
    await prefs.remove(_K.accessToken);
    await prefs.remove(_K.refreshToken);
  }

  /// Muat sesi dari SharedPreferences (dipanggil saat app baru dibuka / restart)
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_K.accessToken);
    final userId = prefs.getString(_K.userId);

    if (accessToken == null || accessToken.isEmpty || userId == null) {
      return false;
    }

    _currentUser = UserModel(
      userId: userId,
      email: prefs.getString(_K.email) ?? '',
      nama: prefs.getString(_K.nama) ?? '',
      role: prefs.getString(_K.role) ?? '',
      bankId: prefs.getString(_K.bankId),
      identityId: prefs.getString(_K.identityId),
      accessToken: accessToken,
      refreshToken: prefs.getString(_K.refreshToken) ?? '',
    );

    // Ambil profil tambahan berdasarkan role
    if (_currentUser!.role == 'nasabah' && _currentUser!.identityId != null) {
      await fetchNasabahProfile();
    }
    if (_currentUser != null &&
        (_currentUser!.role == 'petugas_bsi' ||
            _currentUser!.role == 'petugas_bsu' ||
            _currentUser!.role == 'petugas_bsm')) {
      await fetchPetugasProfile();
    }

    notifyListeners();
    return true;
  }

  // ─── Auth flow ─────────────────────────────────────────────────────────────

  /// Step 1: Cek apakah user valid dan role apa saja yang dimiliki di mobile.
  Future<Map<String, dynamic>> cekUserMobile(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.cekUserMobile(email, password);

    _isLoading = false;
    if (result['success'] != true) {
      _errorMessage = result['message'];
    }
    notifyListeners();
    return result;
  }

  /// Step 2: Login dengan role yang sudah dipilih.
  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await AuthService.login(email, password, role);

    if (result['success'] == true && result['data'] != null) {
      _currentUser = UserModel.fromJson(result['data']);
      _isLoading = false;

      // Simpan sesi ke disk agar tahan terhadap restart Activity
      await _saveSession(_currentUser!);

      // Ambil profil tambahan
      if (_currentUser?.role == 'nasabah' && _currentUser?.identityId != null) {
        await fetchNasabahProfile();
      }
      if (_currentUser != null &&
          (_currentUser!.role == 'petugas_bsi' ||
              _currentUser!.role == 'petugas_bsu' ||
              _currentUser!.role == 'petugas_bsm')) {
        await fetchPetugasProfile();
      }

      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Login gagal';
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Ambil data detail profil nasabah (termasuk saldo poin)
  Future<void> fetchNasabahProfile() async {
    if (_currentUser == null || _currentUser!.identityId == null) return;

    final result = await AuthService.getProfilNasabah(
      _currentUser!.identityId!,
      _currentUser!.accessToken,
    );

    if (result['success'] == true && result['data'] != null) {
      _nasabahProfile = NasabahProfileModel.fromJson(result['data']);
      notifyListeners();
    }
  }

  /// Ambil data detail profil petugas
  Future<void> fetchPetugasProfile() async {
    if (_currentUser == null || _currentUser!.identityId == null) return;

    final result = await AuthService.getProfilPetugas(
      _currentUser!.identityId!,
      _currentUser!.accessToken,
    );

    if (result['success'] == true && result['data'] != null) {
      _petugasProfile = PetugasModel.fromJson(result['data']);
      notifyListeners();
    }
  }

  /// Logout dari aplikasi dan bersihkan data session
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();
    await _clearSession();

    _currentUser = null;
    _nasabahProfile = null;
    _petugasProfile = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Memperbarui Access Token menggunakan Refresh Token
  Future<bool> refreshToken() async {
    if (_currentUser == null || _currentUser!.refreshToken.isEmpty) return false;

    final result = await AuthService.refreshToken(_currentUser!.refreshToken);

    if (result['success'] == true && result['set_cookie'] != null) {
      String setCookie = result['set_cookie'];

      String? newAccessToken;
      String? newRefreshToken;

      final cookies = setCookie.split(',');
      for (var cookie in cookies) {
        if (cookie.contains('access_token=')) {
          newAccessToken = cookie.split('access_token=')[1].split(';')[0];
        } else if (cookie.contains('refresh_token=')) {
          newRefreshToken = cookie.split('refresh_token=')[1].split(';')[0];
        }
      }

      if (newAccessToken != null && newRefreshToken != null) {
        _currentUser = UserModel(
          userId: _currentUser!.userId,
          email: _currentUser!.email,
          nama: _currentUser!.nama,
          role: _currentUser!.role,
          bankId: _currentUser!.bankId,
          identityId: _currentUser!.identityId,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
        // Update token baru ke disk
        await _saveSession(_currentUser!);
        notifyListeners();
        return true;
      }
    }

    // Jika gagal refresh, logout user
    await logout();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
