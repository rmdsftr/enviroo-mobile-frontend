import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

/// Autentikasi & sesi.
///
/// ⚠️ Sebagian besar method di sini sengaja memakai `http` mentah, BUKAN
/// `ApiClient`. Jangan "dirapikan" jadi `ApiClient` tanpa membaca ini:
///
/// 1. [refreshToken] **tidak boleh** lewat `ApiClient` — dia justru yang
///    dipanggil `ApiClient` sebagai callback `onUnauthorized`. Mengalihkannya
///    berarti rekursi tak hingga begitu access token kedaluwarsa.
/// 2. [refreshToken] dan [logout] mengirim header `Cookie: refresh_token=…`
///    manual (lihat catatan di [refreshToken]); `ApiClient` hanya menyuntikkan
///    `Authorization`, jadi header itu akan hilang.
/// 3. Enam method pra-login ([cekUserMobile], [login], [aktivasiAkun], dan tiga
///    method forget-password) dipanggil saat belum ada token sama sekali —
///    auto-refresh 401 tidak relevan di sana.
///
/// Yang memang sudah semestinya lewat `ApiClient`: [changePassword] dan
/// [switchRole]. Profil sesi (`getProfilNasabah`/`getProfilPetugas`) sudah
/// dipindah ke `ProfilService`.
class AuthService {
  /// Step 1: Cek user di mobile — mengembalikan role yang tersedia.
  /// Response sukses: { success, user_id, multiple_roles, roles[] }
  static Future<Map<String, dynamic>> cekUserMobile(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.cekUserMobileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        final data = body['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'user_id': data['user_id'],
          'multiple_roles': data['multiple_roles'] ?? false,
          'roles': List<String>.from(data['roles'] ?? []),
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal memverifikasi akun',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  /// Step 2: Login dengan role yang dipilih — mengembalikan data user + JWT tokens.
  static Future<Map<String, dynamic>> login(String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'platform': 'mobile',
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  /// Aktivasi akun baru (NIK + OTP + Password)
  static Future<Map<String, dynamic>> aktivasiAkun(String nik, String otp, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.aktivasiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': nik,
          'otp': otp,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Aktivasi berhasil',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Gagal melakukan aktivasi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  // ─── Forget Password ────────────────────────────────────────────────────────

  /// Step 1: Kirim email OTP untuk reset password.
  /// Response sukses: { success, message, aktivasi_id, expired_at }
  static Future<Map<String, dynamic>> sendEmailForgetPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgetPasswordSendEmailUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': body['message'] ?? 'Email OTP berhasil dikirim',
          'aktivasi_id': body['data']?['aktivasi_id'],
          'expired_at': body['data']?['expired_at'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengirim email OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  /// Step 2: Verifikasi kode OTP reset password.
  /// Response sukses: { success, message }
  static Future<Map<String, dynamic>> verifikasiOtpForgetPassword(
      String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgetPasswordVerifikasiOtpUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': body['message'] ?? 'Verifikasi OTP berhasil',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Verifikasi OTP gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  /// Step 3: Reset password dengan OTP yang sudah diverifikasi.
  /// Response sukses: { success, message }
  static Future<Map<String, dynamic>> resetPassword(
      String email, String otp, String passwordBaru, String konfirmasiPasswordBaru) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgetPasswordResetPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'password_baru': passwordBaru,
          'konfirmasi_password_baru': konfirmasiPasswordBaru,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': body['message'] ?? 'Password berhasil diubah',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mereset password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }


  /// Change Password
  static Future<Map<String, dynamic>> changePassword(
    String passwordLama,
    String passwordBaru,
    String konfirmasiPasswordBaru,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.changePasswordUrl),
        body: jsonEncode({
          'password_lama': passwordLama,
          'password_baru': passwordBaru,
          'konfirmasi_password_baru': konfirmasiPasswordBaru,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password berhasil diubah',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Gagal mengubah password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }



  /// Logout user
  ///
  /// Token wajib dikirim: backend memakainya untuk mencocokkan `session_id`
  /// sebelum mengosongkan slot sesi user. Tanpa token, sesi lama tetap
  /// dianggap aktif di server sampai token expired sendiri.
  static Future<Map<String, dynamic>> logout(
      String accessToken, String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Cookie': 'refresh_token=$refreshToken',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': body['message'] ?? 'Logout berhasil',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Logout gagal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  /// Switch ke role lain (nasabah ↔ admin) menggunakan token aktif.
  /// Menggunakan ApiClient agar 401 → refresh → retry otomatis.
  static Future<Map<String, dynamic>> switchRole(String targetRole) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.switchRoleUrl),
        body: jsonEncode({'target_role': targetRole}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {'success': true, 'data': body['data']};
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal pindah akun',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }

  /// Refresh access token
  ///
  /// Backend membaca refresh token lewat `c.Cookie()`, sementara http package
  /// Flutter tidak punya cookie jar seperti browser — jadi header `Cookie`
  /// dikirim manual. Token barunya dibaca dari JSON body (bukan `Set-Cookie`,
  /// yang tidak reliable di HTTP client Dart).
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refreshUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'refresh_token=$refreshToken',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.sukses) {
        return {
          'success': true,
          'message': body['message'],
          'access_token': body['access_token'],
          'refresh_token': body['refresh_token'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal memperbarui token',
          // SESSION_REVOKED → sesi digantikan login dari perangkat lain
          'code': body['code'],
        };
      }
    } catch (e) {
      // Dibedakan dari penolakan server: sesi belum tentu mati, jadi pemanggil
      // tidak boleh menganggapnya sebagai alasan untuk logout.
      return {
        'success': false,
        'network_error': true,
        'message': ApiFailure.from(e).pesan,
      };
    }
  }
}
