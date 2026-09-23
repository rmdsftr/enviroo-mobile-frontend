import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:enviroo/core/config/api_config.dart';
import '../models/detail_bank_model.dart';
import '../models/detail_petugas_model.dart';
import 'package:enviroo/core/network/api_client.dart';

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
      final response = await ApiClient.sendMultipart(() async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.updateProfilUrl}/$userId'),
        );
        if (nama != null && nama.isNotEmpty) request.fields['nama'] = nama;
        if (noWhatsapp != null && noWhatsapp.isNotEmpty) request.fields['no_whatsapp'] = noWhatsapp;
        if (photo != null) {
          request.files.add(await http.MultipartFile.fromPath('photo_profile', photo.path));
        }
        return request;
      });
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Profil berhasil diperbarui'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal memperbarui profil'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

}
