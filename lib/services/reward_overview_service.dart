import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RewardOverviewService {
  /// Ambil data reward overview untuk nasabah
  static Future<Map<String, dynamic>> getRewardOverview(
    String nasabahId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getRewardOverviewNasabahUrl}/$nasabahId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'],
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil data reward',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }
}
