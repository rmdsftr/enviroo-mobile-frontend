import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class KatalogService {
  static Future<Map<String, dynamic>> getKatalogSampah(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getKatalogSampahUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
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

  static Future<Map<String, dynamic>> getKatalogSembako(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getKatalogSembakoUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil katalog sembako'};
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

  static Future<Map<String, dynamic>> getKatalogHistory(String sampahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getKatalogHistoryUrl}/$sampahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil riwayat harga sampah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
