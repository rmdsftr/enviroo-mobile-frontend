import 'package:enviroo/models/nasabah_profile_model.dart';
import 'package:enviroo/models/petugas_model.dart';
import 'package:enviroo/models/user_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/services/auth_service.dart';
import 'package:enviroo/services/profil_service.dart';
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
  bool _isRestoringSession = false;
  String? _errorMessage;
  List<String> _availableRoles = [];

  // Kegagalan mengambil profil sesi. Dipisah dari _errorMessage yang dipakai
  // alur login — kalau digabung, pesan login bisa tertimpa pesan profil.
  String? _profileError;

  // Alasan sesi berakhir dari server (mis. SESSION_REVOKED saat akun dipakai
  // login di perangkat lain) — dipakai untuk pesan di layar login.
  String? _sessionEndedCode;
  String? _sessionEndedMessage;

  // Deduplicate concurrent refresh calls — only one in-flight at a time.
  Future<bool>? _refreshFuture;

  int _profilePhotoVersion = 0;
  int get profilePhotoVersion => _profilePhotoVersion;
  void bumpPhotoVersion() {
    _profilePhotoVersion++;
    notifyListeners();
  }

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
  String? get profileError => _profileError;
  List<String> get availableRoles => _availableRoles;
  String? get sessionEndedCode => _sessionEndedCode;
  String? get sessionEndedMessage => _sessionEndedMessage;

  // Convenience getters
  String get role => _currentUser?.role ?? '';
  String get nama => _petugasProfile?.nama ?? _nasabahProfile?.nama ?? _currentUser?.nama ?? 'Tamu';
  String get userId => _currentUser?.userId ?? '';
  String? get bankId => _nasabahProfile?.bankId.isNotEmpty == true
      ? _nasabahProfile!.bankId
      : _petugasProfile?.bankId ?? _currentUser?.bankId;
  String? get identityId => _currentUser?.identityId;
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
    _initApiClient();

    // Token yang tersimpan di disk bukan bukti sesi masih sah — server bisa
    // sudah mematikannya (login dari perangkat lain / ganti password). Validasi
    // dulu lewat refresh; kalau gagal, _doRefreshToken sudah membersihkan sesi
    // dan SplashScreen akan mengarahkan ke login.
    _isRestoringSession = true;
    await refreshToken();
    _isRestoringSession = false;
    // Kalau server menolak, _doRefreshToken sudah menghapus sesi → ke login.
    // Kalau gagalnya karena jaringan, sesi dipertahankan dan app tetap masuk;
    // request berikutnya yang akan mencoba lagi.
    if (_currentUser == null) return false;

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
    _sessionEndedCode = null;
    _sessionEndedMessage = null;
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

  /// Ambil profil sesi nasabah.
  ///
  /// Mengembalikan `false` kalau gagal, dan mengisi [profileError]. Pemanggil
  /// bootstrap (`tryRestoreSession`, `login`, `switchRole`) sengaja TIDAK
  /// memblokir atas kegagalan ini — jaringan goyang tidak boleh menahan user
  /// masuk app, dan getter berjenjang ([bankId], [nama]) masih punya fallback
  /// dari `_currentUser`. Yang penting: kegagalannya tercatat, bukan hilang.
  ///
  /// Hanya dipanggil dari dalam provider ini. Layar TIDAK perlu memanggilnya —
  /// setiap jalan menuju beranda sudah melewati salah satu pemanggil di atas.
  Future<bool> fetchNasabahProfile() async {
    // Belum ada sesi — bukan kegagalan, memang tidak ada yang bisa diambil.
    if (_currentUser == null || _currentUser!.identityId == null) return false;

    // Memanggil ProfilService langsung (bukan ProfilProvider) karena ini
    // bootstrap sesi — AuthProvider tidak punya akses ke provider lain.
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

  /// Ambil profil sesi petugas. Kontraknya sama persis dengan
  /// [fetchNasabahProfile] — disamakan supaya tidak lahir asimetri perilaku
  /// antara kedua peran.
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

  /// Logout dari aplikasi dan bersihkan data session
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // Token dikirim agar server ikut mengosongkan slot sesi user, bukan cuma
    // dibersihkan di sisi aplikasi.
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
    if (_currentUser == null) return false;

    Map<String, dynamic> result = {'success': false};
    if (_currentUser!.refreshToken.isNotEmpty) {
      result = await AuthService.refreshToken(_currentUser!.refreshToken);
    }

    if (result['success'] == true) {
      final newAccessToken = result['access_token'] as String?;
      final newRefreshToken = result['refresh_token'] as String?;

      // Refresh token tidak selalu dirotasi — pertahankan yang lama jika backend
      // tidak mengirim yang baru.
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

    // Gagal karena jaringan, bukan karena server menolak — sesi belum tentu
    // mati (mis. app dibuka saat offline), jadi jangan dipaksa logout.
    if (result['network_error'] == true) return false;

    // Refresh gagal → sesi sudah tidak sah di server (expired, atau
    // SESSION_REVOKED karena akun dipakai login di perangkat lain).
    // Saat switch role, kegagalan ditangani oleh switchRole() sendiri.
    if (!_isSwitchingRole) {
      _sessionEndedCode = result['code'] as String?;
      _sessionEndedMessage = result['message'] as String?;
      await logout();
      // Saat restore sesi, SplashScreen yang mengarahkan ke login — tidak perlu
      // (dan tidak boleh) push route baru dari sini.
      if (!_isRestoringSession) _onForceLogout?.call();
    }
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Dipanggil setelah alasan sesi berakhir ditampilkan ke user, agar
  /// pesannya tidak muncul lagi di kunjungan berikutnya ke layar login.
  void clearSessionEnded() {
    _sessionEndedCode = null;
    _sessionEndedMessage = null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Alur sekali-jalan: aktivasi, lupa password, ganti password
  //
  // Sengaja meneruskan hasil service apa adanya — TIDAK menyentuh _isLoading
  // maupun _errorMessage. Tiga alasannya:
  //
  // 1. [_isLoading] menggerakkan UI login. Memakainya di sini membuat tombol
  //    login ikut berubah keadaan saat user sedang mengaktivasi akun.
  // 2. VerifikasiOtpScreen punya dua flag terpisah (verifikasi vs kirim ulang);
  //    satu flag di provider tidak bisa melayani keduanya.
  // 3. AktivasiAkunScreen mencocokkan TEKS pesan error untuk memutuskan maju ke
  //    step 2. Pesan mentah harus sampai ke layar utuh — kalau ditelan jadi
  //    _errorMessage, alur dua-langkahnya rusak tanpa gejala.
  //
  // Jangan diubah jadi stateful tanpa membaca ketiga poin itu dulu.
  // ───────────────────────────────────────────────────────────────────────────

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

  /// Token diambil dari sesi yang sedang aktif — layar tidak perlu mengurusnya.
  Future<Map<String, dynamic>> changePassword(
    String passwordLama,
    String passwordBaru,
    String konfirmasiPassword,
  ) =>
      AuthService.changePassword(
          passwordLama, passwordBaru, konfirmasiPassword);
}
