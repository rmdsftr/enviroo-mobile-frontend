import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RewardService {
  // GET /reward/get-all
  static Future<Map<String, dynamic>> getAllReward(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllRewardUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['error'] ?? 'Gagal mengambil data reward',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  // GET /nilai-reward/get/:bank_id
  static Future<Map<String, dynamic>> getNilaiReward(
      String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getNilaiRewardUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['error'] ?? 'Gagal mengambil nilai reward',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }
}
