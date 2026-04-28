import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PenimbanganService {
  /// Cek jadwal BSU hari ini. Mengembalikan status:
  /// - "active_session"  → ada sesi aktif
  /// - "scheduled"       → ada jadwal hari ini, belum ada sesi aktif
  /// - "unscheduled"     → tidak ada jadwal hari ini
  static Future<Map<String, dynamic>> checkJadwalHariIni(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.checkPenimbanganUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': body['status'], // "scheduled" | "unscheduled"
        };
      } else if (response.statusCode == 409) {
        // active_session → status conflict
        return {
          'success': true,
          'status': body['status'] ?? 'active_session',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengecek jadwal',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Memulai sesi penimbangan.
  /// [forceDadakan] = true jika tidak ada jadwal hari ini (dadakan).
  static Future<Map<String, dynamic>> addPenimbangan(
      String bankId, String adminId, String token,
      {bool forceDadakan = false}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.addPenimbanganUrl}/$bankId/$adminId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'force_dadakan': forceDadakan}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': body['data'],
          'message': body['message'] ?? 'Sesi penimbangan berhasil dimulai',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body['error'] ?? 'Gagal memulai penimbangan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Memperbarui / Menyudahi / Membatalkan sesi penimbangan aktif.
  /// [status] = "selesai" | "dibatalkan"
  static Future<Map<String, dynamic>> updatePenimbangan(
      String penimbanganId, String adminId, String status, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.updatePenimbanganUrl}/$penimbanganId/$adminId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status_penimbangan': status}),
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'message': body['message'] ?? 'Status berhasil diperbarui',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal memperbarui status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Mendapatkan daftar riwayat penimbangan suatu BSU.
  static Future<Map<String, dynamic>> getPenimbangan(
      String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getPenimbanganUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil data penimbangan',
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
