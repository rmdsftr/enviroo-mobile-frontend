import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class NasabahService {
  static Future<Map<String, dynamic>> getNasabahByBankId(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getNasabahBankUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data nasabah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAdminByBankId(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getAdminBankUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data petugas'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBsuByBsiId(String bsiId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getUnitBsiUrl}/$bsiId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data BSU'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
