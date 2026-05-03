import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboardPetugas(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getDashboardPetugasUrl}/$bankId'),
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
          'message': body['error'] ?? 'Gagal memuat dashboard',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// GET /dashboard/saldo-bank/:bank_id
  /// Mengembalikan saldo poin + daftar kas per reward.
  static Future<Map<String, dynamic>> getSaldoBank(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getSaldoBankUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? {}};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat saldo bank',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// GET /dashboard/redeem-overview/:nasabah_id
  static Future<Map<String, dynamic>> getRedeemOverviewNasabah(
      String nasabahId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getRedeemOverviewNasabahUrl}/$nasabahId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat overview',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }
}
