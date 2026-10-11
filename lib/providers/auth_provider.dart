import 'package:enviroo/models/nasabah_profile_model.dart';
import 'package:enviroo/models/petugas_model.dart';
import 'package:enviroo/models/user_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:enviroo/services/profil_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const resetEmail = 'reset_pw_email';
  static const resetExpiredAt = 'reset_pw_expired_at';
}

class PendingResetSession {
  final String email;
  final DateTime expiredAt;

  const PendingResetSession({required this.email, required this.expiredAt});
}

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  NasabahProfileModel? _nasabahProfile;
  PetugasModel? _petugasProfile;
  bool _isLoading = false;
  bool _isSwitchingRole = false;
  bool _isRestoringSession = false;
  String? _errorMessage;
  List<String> _availableRoles = [];

  String? _profileError;

  String? _sessionEndedCode;
  String? _sessionEndedMessage;

  Future<bool>? _refreshFuture;

  int _profilePhotoVersion = 0;
  int get profilePhotoVersion => _profilePhotoVersion;
  void bumpPhotoVersion() {
    _profilePhotoVersion++;
    notifyListeners();
  }

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
  String? get profileError => _profileError;
  List<String> get availableRoles => _availableRoles;
  String? get sessionEndedCode => _sessionEndedCode;
  String? get sessionEndedMessage => _sessionEndedMessage;

  String get role => _currentUser?.role ?? '';
  String get nama => _petugasProfile?.nama ?? _nasabahProfile?.nama ?? _currentUser?.nama ?? 'Tamu';
  String get userId => _currentUser?.userId ?? '';
  String? get bankId => _nasabahProfile?.bankId.isNotEmpty == true
      ? _nasabahProfile!.bankId
      : _petugasProfile?.bankId ?? _currentUser?.bankId;
  String? get identityId => _currentUser?.identityId;
  String get nomorRekening => _nasabahProfile?.nomorRekening ?? '-';

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

  Future<void> setAvailableRoles(List<String> roles) async {
    _availableRoles = roles;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_K.availableRoles, roles);
    notifyListeners();
  }

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
    _initApiClient();

    _isRestoringSession = true;
    await refreshToken();
    _isRestoringSession = false;
    if (_currentUser == null) return false;

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

  Future<bool> login(String email, String password, String role) async {
    _isLoading = true;
    _errorMessage = null;
    _sessionEndedCode = null;
    _sessionEndedMessage = null;
    notifyListeners();

    final result = await AuthService.login(email, password, role);

    if (result['success'] == true && result['data'] != null) {
      _currentUser = UserModel.fromJson(result['data']);
      _isLoading = false;

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

  Future<bool> switchRole(String targetRole) async {
    _isSwitchingRole = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await refreshToken();

    final result = await AuthService.switchRole(targetRole);

    if (result['success'] == true && result['data'] != null) {
      _nasabahProfile = null;
      _petugasProfile = null;
      _profileError = null;
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

  Future<bool> fetchNasabahProfile() async {
    if (_currentUser == null || _currentUser!.identityId == null) return false;

    final result =
        await ProfilService.getProfilNasabah(_currentUser!.identityId!);

    if (result['success'] == true && result['data'] != null) {
      _nasabahProfile = NasabahProfileModel.fromJson(result['data']);
      _profileError = null;
      notifyListeners();
      return true;
    }

    _profileError =
        result['message']?.toString() ?? 'Gagal mengambil profil nasabah';
    notifyListeners();
    return false;
  }

  Future<bool> fetchPetugasProfile() async {
    if (_currentUser == null || _currentUser!.identityId == null) return false;

    final result =
        await ProfilService.getProfilPetugas(_currentUser!.identityId!);

    if (result['success'] == true && result['data'] != null) {
      _petugasProfile = PetugasModel.fromJson(result['data']);
      _profileError = null;
      notifyListeners();
      return true;
    }

    _profileError =
        result['message']?.toString() ?? 'Gagal mengambil profil petugas';
    notifyListeners();
    return false;
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

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final accessToken = _currentUser?.accessToken ?? '';
    if (accessToken.isNotEmpty) {
      await AuthService.logout(accessToken, _currentUser?.refreshToken ?? '');
    }
    await _clearSession();

    _currentUser = null;
    _nasabahProfile = null;
    _petugasProfile = null;
    _availableRoles = [];
    _errorMessage = null;
    _profileError = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> refreshToken() {
    _refreshFuture ??= _doRefreshToken().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<bool> _doRefreshToken() async {
    if (_currentUser == null) return false;

    Map<String, dynamic> result = {'success': false};
    if (_currentUser!.refreshToken.isNotEmpty) {
      result = await AuthService.refreshToken(_currentUser!.refreshToken);
    }

    if (result['success'] == true) {
      final newAccessToken = result['access_token'] as String?;
      final newRefreshToken = result['refresh_token'] as String?;

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        _currentUser = UserModel(
          userId: _currentUser!.userId,
          email: _currentUser!.email,
          nama: _currentUser!.nama,
          role: _currentUser!.role,
          bankId: _currentUser!.bankId,
          identityId: _currentUser!.identityId,
          accessToken: newAccessToken,
          refreshToken: (newRefreshToken != null && newRefreshToken.isNotEmpty)
              ? newRefreshToken
              : _currentUser!.refreshToken,
        );
        await _saveSession(_currentUser!);
        notifyListeners();
        return true;
      }
    }

    if (result['network_error'] == true) return false;

    if (!_isSwitchingRole) {
      _sessionEndedCode = result['code'] as String?;
      _sessionEndedMessage = result['message'] as String?;
      await logout();
      if (!_isRestoringSession) _onForceLogout?.call();
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSessionEnded() {
    _sessionEndedCode = null;
    _sessionEndedMessage = null;
  }

  Future<Map<String, dynamic>> aktivasiAkun(
          String nik, String otp, String password) =>
      AuthService.aktivasiAkun(nik, otp, password);

  Future<Map<String, dynamic>> sendEmailForgetPassword(String email) =>
      AuthService.sendEmailForgetPassword(email);

  Future<Map<String, dynamic>> verifikasiOtpForgetPassword(
          String email, String otp) =>
      AuthService.verifikasiOtpForgetPassword(email, otp);

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String passwordBaru,
    String konfirmasiPasswordBaru,
  ) =>
      AuthService.resetPassword(
          email, otp, passwordBaru, konfirmasiPasswordBaru);

  Future<void> savePendingReset(String email, String? expiredAt) async {
    final prefs = await SharedPreferences.getInstance();
    final kadaluarsa = expiredAt ??
        DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
    await prefs.setString(_K.resetEmail, email);
    await prefs.setString(_K.resetExpiredAt, kadaluarsa);
  }

  Future<PendingResetSession?> loadPendingReset() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_K.resetEmail);
    final raw = prefs.getString(_K.resetExpiredAt);
    if (email == null || email.isEmpty || raw == null) return null;

    final expiredAt = DateTime.tryParse(raw);
    if (expiredAt == null || !expiredAt.isAfter(DateTime.now())) {
      await clearPendingReset();
      return null;
    }
    return PendingResetSession(email: email, expiredAt: expiredAt);
  }

  Future<void> clearPendingReset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_K.resetEmail);
    await prefs.remove(_K.resetExpiredAt);
  }

  Future<Map<String, dynamic>> changePassword(
    String passwordLama,
    String passwordBaru,
    String konfirmasiPassword,
  ) =>
      AuthService.changePassword(
          passwordLama, passwordBaru, konfirmasiPassword);
}
