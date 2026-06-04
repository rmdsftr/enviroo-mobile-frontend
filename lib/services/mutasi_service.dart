import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class MutasiService {
  static Future<Map<String, dynamic>> getMutasi({
    required String nasabahId,
    required int rewardId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.getMutasiNasabahUrl}/$nasabahId').replace(
        queryParameters: {
          'reward_id': rewardId.toString(),
          'start_date': startDate,
          'end_date': endDate,
        },
      );
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      if (response.statusCode == 404) return {'success': true, 'data': null};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal memuat mutasi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }
}
