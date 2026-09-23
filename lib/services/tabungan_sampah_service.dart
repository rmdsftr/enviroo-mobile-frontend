import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import '../models/tabungan_sampah_model.dart';
import 'package:enviroo/core/network/api_client.dart';

class TabunganSampahService {
  static Future<Map<String, dynamic>> getBukuTabunganBsu(String bsuId, {String? startDate, String? endDate}) async {
    try {
      final base = Uri.parse('${ApiConfig.getBukuTabunganBsuUrl}/$bsuId');
      final uri = (startDate != null || endDate != null)
          ? base.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : base;
      final res = await ApiClient.get(uri);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': BukuTabunganBsuResponse.fromJson(body)};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data tabungan BSU'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getBukuTabungan(
    String nasabahId, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.getBukuTabunganUrl}/$nasabahId').replace(
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
        },
      );
      final res = await ApiClient.get(uri);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': BukuTabunganResponse.fromJson(body)};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data tabungan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
