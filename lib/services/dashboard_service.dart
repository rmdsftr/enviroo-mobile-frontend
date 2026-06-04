import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboardPetugas(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDashboardPetugasUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat dashboard'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSaldoBank(String bankId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getSaldoBankUrl}/$bankId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? {}};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat saldo bank'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSaldoNasabah(String nasabahId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getSaldoNasabahUrl}/$nasabahId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? {}};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat saldo nasabah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
