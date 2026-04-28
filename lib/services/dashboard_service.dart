import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboardPetugas(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getDashboardPetugasUrl}/$bankId'),
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
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal memuat dashboard',
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
