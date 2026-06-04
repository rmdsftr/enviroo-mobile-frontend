import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class RewardOverviewService {
  static Future<Map<String, dynamic>> getRewardOverview(String nasabahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getRewardOverviewNasabahUrl}/$nasabahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'], 'data': body['data']};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data reward'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
