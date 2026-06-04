import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/detail_bank_model.dart';
import '../models/detail_petugas_model.dart';
import 'api_client.dart';

class ProfilService {
  static Future<Map<String, dynamic>?> getDetailNasabah(String nasabahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailNasabahUrl}/$nasabahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return body['data'];
      throw Exception(body['error'] ?? 'Gagal mengambil data profil');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  static Future<DetailBankModel> getDetailBank(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailBankUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['data'] != null) {
        return DetailBankModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['error'] ?? 'Gagal mengambil data bank');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  static Future<DetailPetugasModel> getDetailPetugas(String petugasId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailPetugasUrl}/$petugasId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['data'] != null) {
        return DetailPetugasModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw Exception(body['error'] ?? 'Gagal mengambil data petugas');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  static Future<Map<String, dynamic>> getLogAkun(String userId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.logAkunUrl}/$userId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil log akun'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfil({
    required String userId,
    String? nama,
    String? noWhatsapp,
    File? photo,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.updateProfilUrl}/$userId'),
      );
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      if (nama != null && nama.isNotEmpty) request.fields['nama'] = nama;
      if (noWhatsapp != null && noWhatsapp.isNotEmpty) request.fields['no_whatsapp'] = noWhatsapp;
      if (photo != null) {
        request.files.add(await http.MultipartFile.fromPath('photo_profile', photo.path));
      }
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Profil berhasil diperbarui'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal memperbarui profil'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePhotoProfile(String userId, File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.changePhotoProfileUrl));
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.fields['user_id'] = userId;
      request.files.add(await http.MultipartFile.fromPath('photo_profile', imageFile.path));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'photo_url': body['photo_url'], 'message': body['message'] ?? 'Foto berhasil diubah'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengubah foto profil'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
