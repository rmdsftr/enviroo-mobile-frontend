import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';

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

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
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

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
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

      if (response.statusCode == 200 || response.statusCode == 201) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Reaktivasi akun lama (NIK + OTP saja, tanpa password)
  static Future<Map<String, dynamic>> reactivateAkun(String nik, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reactivateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': nik,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Aktivasi ulang berhasil',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Gagal melakukan aktivasi ulang',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
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

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
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

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
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

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }


  /// Change Password
  static Future<Map<String, dynamic>> changePassword(String passwordLama, String passwordBaru, String konfirmasiPasswordBaru, String token) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.changePasswordUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'password_lama': passwordLama,
          'password_baru': passwordBaru,
          'konfirmasi_password_baru': konfirmasiPasswordBaru,
        }),
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Ambil data lengkap profil nasabah
  static Future<Map<String, dynamic>> getProfilNasabah(String nasabahID, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.profilNasabahUrl}/$nasabahID'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil profil nasabah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Ambil data lengkap profil petugas
  static Future<Map<String, dynamic>> getProfilPetugas(String adminID, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.activePetugasUrl}/$adminID'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil profil petugas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
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

      if (response.statusCode == 200) {
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
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Refresh access token
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      // Pada mobile, kita mengirim refresh token melalui header atau body.
      // Berdasarkan kode backend Anda, ia mengambil dari Cookie.
      // Namun http package di Flutter tidak otomatis menangani cookie seperti browser.
      // Jadi kita kirim di header Cookie secara manual.
      final response = await http.post(
        Uri.parse(ApiConfig.refreshUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Cookie': 'refresh_token=$refreshToken',
        },
      ).timeout(const Duration(seconds: 10));

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Backend Go Anda menggunakan utils.SetTokenCookies yang mengirim token via header 'Set-Cookie'
        // Kita perlu mengekstrak token baru dari header tersebut jika backend tidak mengirimnya di body.
        // Berdasarkan kode backend Anda, c.JSON(http.StatusOK, gin.H{"message": "Token berhasil diperbarui"})
        // Jadi kita ambil dari header 'set-cookie'
        String? setCookie = response.headers['set-cookie'];

        return {
          'success': true,
          'message': body['message'],
          'set_cookie': setCookie,
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal memperbarui token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }
}
