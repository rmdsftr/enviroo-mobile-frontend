import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class RewardService {
  static Future<Map<String, dynamic>> getAllReward() async {
    try {
      final response = await ApiClient.get(Uri.parse(ApiConfig.getAllRewardUrl));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data reward'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNilaiReward(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getNilaiRewardUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil nilai reward'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
