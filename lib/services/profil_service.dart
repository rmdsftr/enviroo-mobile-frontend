import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:enviroo/core/config/api_config.dart';
import '../models/detail_bank_model.dart';
import '../models/detail_petugas_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

/// Semua yang berkaitan dengan data profil & akun user.
///
/// ⚠️ Ada **lima nama yang mirip** di sini. Bedanya siapa yang memanggil, bukan
/// bentuk datanya:
///
/// ```
/// getProfilNasabah  -> /profil/nasabah          AUTHPROVIDER (profil sesi sendiri)
/// getProfilPetugas  -> /users/active-petugas    AUTHPROVIDER (profil sesi sendiri)
/// getDetailNasabah  -> /profil/detail-nasabah   LAYAR (lihat profil orang)
/// getDetailPetugas  -> /profil/detail-petugas   LAYAR (lihat profil orang)
/// getActiveUser     -> /users/active-user       PROFILECORNER (foto avatar)
/// ```
///
/// Service ini sengaja melayani dua prefix sekaligus (`/profil` dan `/users`) —
/// alasannya dicatat di blok konstanta `/users` pada `ApiConfig`.
class ProfilService {
  // ── Profil sesi sendiri ────────────────────────────────────────────────────
  // Dipanggil AuthProvider saat bootstrap sesi (login / restore / switch role)
  // untuk mengisi _nasabahProfile dan _petugasProfile. BUKAN untuk melihat
  // profil orang lain — itu tugas getDetailNasabah / getDetailPetugas di bawah.

  /// Profil nasabah yang sedang login. Endpoint `/profil/nasabah`.
  static Future<Map<String, dynamic>> getProfilNasabah(String nasabahId) async {
    try {
      final response = await ApiClient.get(
          Uri.parse('${ApiConfig.profilNasabahUrl}/$nasabahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil profil nasabah'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  /// Profil petugas yang sedang login. Endpoint `/users/active-petugas` —
  /// prefix-nya `/users`, tapi ditaruh di sini supaya sekelompok dengan
  /// [getDetailPetugas]. Pembenahan prefix `/users` adalah pekerjaan terpisah.
  static Future<Map<String, dynamic>> getProfilPetugas(String adminId) async {
    try {
      final response = await ApiClient.get(
          Uri.parse('${ApiConfig.activePetugasUrl}/$adminId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil profil petugas'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  // ── Lihat profil (dipanggil layar) ─────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDetailNasabah(String nasabahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailNasabahUrl}/$nasabahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return body['data'];
      throw ApiFailure(ApiFailureKind.server, body['error'] ?? 'Gagal mengambil data profil');
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  static Future<DetailBankModel> getDetailBank(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailBankUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses && body['data'] != null) {
        return DetailBankModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiFailure(ApiFailureKind.server, body['error'] ?? 'Gagal mengambil data bank');
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  static Future<DetailPetugasModel> getDetailPetugas(String petugasId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailPetugasUrl}/$petugasId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses && body['data'] != null) {
        return DetailPetugasModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      throw ApiFailure(ApiFailureKind.server, body['error'] ?? 'Gagal mengambil data petugas');
    } catch (e) {
      throw ApiFailure.from(e);
    }
  }

  /// Data user aktif — dipakai `ProfileCorner` untuk `photo_url` di avatar
  /// pojok. Endpoint `/users/active-user`; alasan ia tinggal di sini bersama
  /// tetangga `/users` lainnya ada di komentar blok `/users` pada ApiConfig.
  ///
  /// Dulu tinggal di `user_service.dart` (18 baris untuk 1 method) dengan
  /// `catch (e) { return null; }` yang menelan semuanya — termasuk melewatkan
  /// [ApiFailure.from], sehingga kehilangan jaringan di jalur ini tidak pernah
  /// terlapor ke `NetworkStatus`.
  static Future<Map<String, dynamic>> getActiveUser(String userId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.activeUserUrl}/$userId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data user'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getLogAkun(String userId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.logAkunUrl}/$userId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil log akun'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Profil berhasil diperbarui'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal memperbarui profil'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

}
