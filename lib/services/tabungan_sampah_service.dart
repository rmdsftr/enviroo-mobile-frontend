import 'dart:convert';
import '../config/api_config.dart';
import '../models/tabungan_sampah_model.dart';
import 'api_client.dart';

class TabunganSampahService {
  static Future<Map<String, dynamic>> getBukuTabunganBsu(String bsuId) async {
    try {
      final res = await ApiClient.get(Uri.parse('${ApiConfig.getBukuTabunganBsuUrl}/$bsuId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': BukuTabunganBsuResponse.fromJson(body)};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data tabungan BSU'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBukuTabungan(String nasabahId) async {
    try {
      final res = await ApiClient.get(Uri.parse('${ApiConfig.getBukuTabunganUrl}/$nasabahId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': BukuTabunganResponse.fromJson(body)};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data tabungan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
