import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class JadwalService {
  static Future<Map<String, dynamic>> getJadwalByBankId(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getJadwalUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getJadwalNasabah(String nasabahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getJadwalNasabahUrl}/$nasabahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'], 'data': body['data']};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
