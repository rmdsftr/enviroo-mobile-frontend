import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class DistribusiSisaService {
  static Future<Map<String, dynamic>> previewDistribusiSisa(String bagiHasilId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.distribusiSisaBase}/preview/$bagiHasilId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body};
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
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.distribusiSisaBase}/submit/$bagiHasilId'),
        body: jsonEncode({'admin_id': adminId}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
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
      if (response.sukses) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail distribusi sisa'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Map<String, dynamic> _connError(Object e) => {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
}
