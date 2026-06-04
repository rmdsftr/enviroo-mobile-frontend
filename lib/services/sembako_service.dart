import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class SembakoService {
  static Future<Map<String, dynamic>> getSembakoBank(String bankId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getKatalogSembakoUrl}/$bankId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat sembako'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDetailSembakoBsu(String sembakoId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailSembakoBsuUrl}/$sembakoId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat detail sembako'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> previewDistribusiBsu({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.previewDistribusiBsuUrl}/$bsiId/$bsuId'),
        body: jsonEncode({'admin_bsi_id': adminBsiId, 'admin_bsu_id': '', 'items': items}),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal preview distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addDistribusiBsu({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
    required String adminBsuId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.addDistribusiBsuUrl}/$bsiId/$bsuId'),
        body: jsonEncode({'admin_bsi_id': adminBsiId, 'admin_bsu_id': adminBsuId, 'items': items}),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal mengirim distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
