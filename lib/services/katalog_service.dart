import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class KatalogService {
  /// Ambil data katalog sampah berdasarkan bankID
  static Future<Map<String, dynamic>> getKatalogSampah(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getKatalogSampahUrl}/$bankId'),
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
          'message': body['error'] ?? 'Gagal mengambil katalog sampah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Ambil data kategori sampah
  static Future<Map<String, dynamic>> getKategori(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getKategoriUrl),
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
          'message': body['error'] ?? 'Gagal mengambil kategori sampah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Ambil data katalog sembako berdasarkan bankID
  static Future<Map<String, dynamic>> getKatalogSembako(String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getKatalogSembakoUrl}/$bankId'),
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
          'message': body['error'] ?? 'Gagal mengambil katalog sembako',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Ambil riwayat harga sampah berdasarkan sampahID
  static Future<Map<String, dynamic>> getKatalogHistory(String sampahId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getKatalogHistoryUrl}/$sampahId'),
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
          'message': body['error'] ?? 'Gagal mengambil riwayat harga sampah',
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
