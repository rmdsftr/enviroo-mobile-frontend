import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';

class KatalogService {
  static Future<Map<String, dynamic>> getKatalogSampah(String bankId, {int? page}) async {
    try {
      final uri = page != null
          ? Uri.parse('${ApiConfig.getKatalogSampahUrl}/$bankId?page=$page')
          : Uri.parse('${ApiConfig.getKatalogSampahUrl}/$bankId');
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'pagination': body['pagination']};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil katalog sampah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getKategori() async {
    try {
      final response = await ApiClient.get(Uri.parse(ApiConfig.getKategoriUrl));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil kategori sampah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDetailSampah(String sampahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailSampahUrl}/$sampahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail sampah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

}
