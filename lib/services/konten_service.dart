import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class KontenService {
  static Future<Map<String, dynamic>> getAllKonten(
    String bankId, {
    bool? published,
    int page = 1,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.getKontenUrl}/$bankId').replace(
        queryParameters: {
          if (published != null) 'published': published.toString(),
          'page': page.toString(),
        },
      );
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'data': body['data'], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil konten informasi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getKontenDetail(String kontenId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getKontenDetailUrl}/$kontenId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail konten'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
