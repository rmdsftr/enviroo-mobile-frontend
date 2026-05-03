import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ProfilService {
  static Future<Map<String, dynamic>?> getDetailNasabah(String nasabahId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getDetailNasabahUrl}/$nasabahId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return body['data'];
      } else {
        throw Exception(body['error'] ?? 'Gagal mengambil data profil');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> changePhotoProfile(String userId, File imageFile, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.changePhotoProfileUrl),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['user_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('photo_profile', imageFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'photo_url': body['photo_url'],
          'message': body['message'] ?? 'Foto berhasil diubah',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengubah foto profil',
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
