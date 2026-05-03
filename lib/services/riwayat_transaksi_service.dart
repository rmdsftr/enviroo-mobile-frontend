import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RiwayatTransaksiService {
  static Future<Map<String, dynamic>> getRiwayatTransaksi(
    String nasabahId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getRiwayatTransaksiNasabahUrl}/$nasabahId'),
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
          'message': body['error'] ?? 'Gagal mengambil riwayat transaksi',
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
