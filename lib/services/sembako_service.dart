import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SembakoService {
  /// GET /sembako/get-sembako/:bank_id
  /// Untuk BSU: backend otomatis mengembalikan stok & schema dari BSI induk.
  static Future<Map<String, dynamic>> getSembakoBank(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getKatalogSembakoUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat sembako',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }
}
