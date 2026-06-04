import 'package:enviroo/models/nasabah_profile_model.dart';
import 'package:enviroo/models/petugas_model.dart';
import 'package:enviroo/models/user_model.dart';
import 'package:enviroo/services/api_client.dart';
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
  static const availableRoles = 'auth_available_roles';
}

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  NasabahProfileModel? _nasabahProfile;
  PetugasModel? _petugasProfile;
  bool _isLoading = false;
  bool _isSwitchingRole = false;
  String? _errorMessage;
  List<String> _availableRoles = [];

  // Deduplicate concurrent refresh calls — only one in-flight at a time.
  Future<bool>? _refreshFuture;

  // Dipanggil setelah logout paksa akibat akun dinonaktifkan (403 ACCOUNT_INACTIVE).
  // Di-set dari _EnvirooAppState.initState agar bisa pakai _navigatorKey.
  void Function()? _onForceLogout;

  void setForceLogoutCallback(void Function() cb) {
    _onForceLogout = cb;
  }

  UserModel? get currentUser => _currentUser;
  NasabahProfileModel? get nasabahProfile => _nasabahProfile;
  PetugasModel? get petugasProfile => _petugasProfile;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;
  List<String> get availableRoles => _availableRoles;

  // Convenience getters
  String get role => _currentUser?.role ?? '';
  String get nama => _petugasProfile?.nama ?? _nasabahProfile?.nama ?? _currentUser?.nama ?? 'Tamu';
  String get userId => _currentUser?.userId ?? '';
  String? get bankId => _nasabahProfile?.bankId.isNotEmpty == true
      ? _nasabahProfile!.bankId
      : _petugasProfile?.bankId ?? _currentUser?.bankId;
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

  /// Simpan available roles ke SharedPreferences
  Future<void> setAvailableRoles(List<String> roles) async {
    _availableRoles = roles;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_K.availableRoles, roles);
    notifyListeners();
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
    await prefs.remove(_K.availableRoles);
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
    _availableRoles = prefs.getStringList(_K.availableRoles) ?? [];

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

    _initApiClient();
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
      _initApiClient();

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

  /// Switch ke role lain menggunakan token aktif (tanpa re-login).
  Future<bool> switchRole(String targetRole) async {
    _isSwitchingRole = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Refresh proaktif sebelum hit endpoint agar token dijamin fresh
    await refreshToken();

    final result = await AuthService.switchRole(targetRole);

    if (result['success'] == true && result['data'] != null) {
      _nasabahProfile = null;
      _petugasProfile = null;
      _currentUser = UserModel.fromJson(result['data']);

      await _saveSession(_currentUser!);
      _initApiClient();

      if (_currentUser?.role == 'nasabah' && _currentUser?.identityId != null) {
        await fetchNasabahProfile();
      }
      if (_currentUser != null &&
          (_currentUser!.role == 'petugas_bsi' ||
              _currentUser!.role == 'petugas_bsu' ||
              _currentUser!.role == 'petugas_bsm')) {
        await fetchPetugasProfile();
      }

      _isSwitchingRole = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Gagal pindah akun';
      _isSwitchingRole = false;
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

  void _initApiClient() {
    ApiClient.init(
      getToken: () => _currentUser?.accessToken ?? '',
      onUnauthorized: refreshToken,
      onDeactivated: () async {
        await logout();
        _onForceLogout?.call();
      },
    );
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
    _availableRoles = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Memperbarui Access Token menggunakan Refresh Token.
  /// Concurrent calls share a single in-flight request so the refresh token
  /// is only consumed once, preventing a race condition that would invalidate
  /// a still-valid session.
  Future<bool> refreshToken() {
    _refreshFuture ??= _doRefreshToken().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<bool> _doRefreshToken() async {
    if (_currentUser == null || _currentUser!.refreshToken.isEmpty) return false;

    final result = await AuthService.refreshToken(_currentUser!.refreshToken);

    if (result['success'] == true && result['set_cookie'] != null) {
      final String setCookie = result['set_cookie'] as String;

      String? newAccessToken;
      String? newRefreshToken;

      // Split per cookie dengan regex agar tidak tertipu koma di dalam nilai
      // Expires (contoh: "Expires=Mon, 01 Jan 2024...").
      final cookiePattern = RegExp(r'(?:^|(?<=\n))([^,]|,(?!\s*\d))+');
      for (final match in cookiePattern.allMatches(setCookie)) {
        final cookie = match.group(0) ?? '';
        if (cookie.contains('access_token=')) {
          newAccessToken = cookie.split('access_token=')[1].split(';')[0].trim();
        } else if (cookie.contains('refresh_token=')) {
          newRefreshToken = cookie.split('refresh_token=')[1].split(';')[0].trim();
        }
      }

      // Fallback: jika regex tidak cocok, coba simple split
      if (newAccessToken == null) {
        for (var cookie in setCookie.split(',')) {
          if (cookie.contains('access_token=')) {
            newAccessToken = cookie.split('access_token=')[1].split(';')[0].trim();
          } else if (newRefreshToken == null && cookie.contains('refresh_token=')) {
            newRefreshToken = cookie.split('refresh_token=')[1].split(';')[0].trim();
          }
        }
      }

      // Refresh token tidak selalu dirotasi — pertahankan yang lama jika backend
      // tidak mengirim yang baru.
      if (newAccessToken != null) {
        _currentUser = UserModel(
          userId: _currentUser!.userId,
          email: _currentUser!.email,
          nama: _currentUser!.nama,
          role: _currentUser!.role,
          bankId: _currentUser!.bankId,
          identityId: _currentUser!.identityId,
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? _currentUser!.refreshToken,
        );
        await _saveSession(_currentUser!);
        notifyListeners();
        return true;
      }
    }

    // Jika gagal refresh dan tidak sedang switch role, logout user
    if (!_isSwitchingRole) await logout();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
