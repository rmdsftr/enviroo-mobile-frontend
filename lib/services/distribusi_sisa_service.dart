import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class DistribusiSisaService {
  static Future<Map<String, dynamic>> previewDistribusiSisa(String bagiHasilId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.distribusiSisaBase}/preview/$bagiHasilId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      if (response.statusCode == 400 && body['distribusi_id'] != null) {
        return {
          'success': false,
          'already_distributed': true,
          'distribusi_id': body['distribusi_id'],
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil preview distribusi sisa'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> submitDistribusiSisa(
    String bagiHasilId,
    String adminId,
    List<Map<String, dynamic>> pengirimanBsu,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.distribusiSisaBase}/submit/$bagiHasilId'),
        body: jsonEncode({'admin_id': adminId, 'pengiriman_bsu': pengirimanBsu}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'distribusi_id': body['distribusi_id'], 'message': body['message']};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal submit distribusi sisa'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailDistribusiSisa(String distribusiId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.distribusiSisaBase}/detail/$distribusiId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail distribusi sisa'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Map<String, dynamic> _connError(Object e) => {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
}
