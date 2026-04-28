import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class JadwalService {
  /// Ambil data jadwal berdasarkan bankID
  static Future<Map<String, dynamic>> getJadwalByBankId(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getJadwalUrl}/$bankId'),
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
          'data': body['data'], // Ini akan berisi { penimbangan: [], pengangkutan: [] }
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil data jadwal',
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
