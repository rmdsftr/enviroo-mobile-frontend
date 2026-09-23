import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

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
      if (response.sukses) return {'success': true, 'data': body['data']};
      if (response.statusCode == 404) return {'success': true, 'data': null};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal memuat mutasi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
