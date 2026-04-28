import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NasabahService {
  /// Ambil data nasabah berdasarkan bankID
  /// GET /bank/get-nasabah/:bankId
  static Future<Map<String, dynamic>> getNasabahByBankId(
      String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getNasabahBankUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil data nasabah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Ambil daftar BSU yang berada di bawah BSI tertentu
  /// GET /bsi/get-unit/:bank_id
  static Future<Map<String, dynamic>> getBsuByBsiId(
      String bsiId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getUnitBsiUrl}/$bsiId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil data BSU',
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
