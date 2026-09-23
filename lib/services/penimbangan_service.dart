import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import '../models/penimbangan_model.dart';
import 'package:enviroo/core/network/api_client.dart';

class PenimbanganService {
  static Future<Map<String, dynamic>> checkJadwalHariIni(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkPenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {
        'success': true,
        'status': body['status'],
        'nama_jadwal_spesial': body['nama_jadwal_spesial'] ?? '',  // ← tambah ini
      };
      if (response.statusCode == 409) return {'success': true, 'status': body['status'] ?? 'active_session'};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  /// Ambil daftar sesi penimbangan hari ini (buat bottom sheet "Kelola Sesi Penimbangan").
  static Future<Map<String, dynamic>> getSesiHariIni(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkPenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final List rawList = body['data'] ?? [];
        final data = rawList
            .map((e) => SesiHariIniItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil sesi hari ini'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkActiveSession(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkActivePenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final result = CheckActiveResult.fromJson(body);
        return {
          'success': true,
          'is_active': result.isActive,
          'penimbangan_id': result.detail?.penimbanganId ?? '',
          'detail': result.detail,
          'pending_sessions': result.pendingSessions,
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addPenimbangan(
    String bankId,
    String adminId, {
    bool forceDadakan = false,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.addPenimbanganUrl}/$bankId/$adminId'),
        body: jsonEncode({'force_dadakan': forceDadakan}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Sesi penimbangan berhasil dimulai'};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal memulai penimbangan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> batalkanPenimbangan(
    String penimbanganId,
    String alasan,
  ) async {
    try {
      final uri = Uri.parse(ApiConfig.batalPenimbanganUrl)
          .replace(queryParameters: {'penimbangan_id': penimbanganId});
      final response = await ApiClient.post(
        uri,
        body: jsonEncode({'alasan_pembatalan': alasan}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'],
          'message': body['message'] ?? 'Sesi penimbangan berhasil dibatalkan',
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal membatalkan sesi penimbangan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  /// Batalkan jadwal penimbangan mendatang (belum dimulai) — beda dari
  /// [batalkanPenimbangan] yang membatalkan sesi yang SUDAH aktif.
  static Future<Map<String, dynamic>> batalkanJadwalPenimbangan({
    required String jadwalId,
    required String tanggalSesi,
    required String alasanPembatalan,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.batalPenimbanganUrl),
        body: jsonEncode({
          'jadwal_id': jadwalId,
          'tanggal_sesi': tanggalSesi,
          'alasan_pembatalan': alasanPembatalan,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Jadwal penimbangan berhasil dibatalkan',
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal membatalkan jadwal penimbangan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePenimbangan(
    String penimbanganId,
    String status,
  ) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.updatePenimbanganUrl}/$penimbanganId'),
        body: jsonEncode({'status_penimbangan': status}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Status berhasil diperbarui'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal memperbarui status'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPenimbangan(String bankId, {String? startDate, String? endDate}) async {
    try {
      final base = Uri.parse('${ApiConfig.getPenimbanganUrl}/$bankId');
      final uri = (startDate != null || endDate != null)
          ? base.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : base;
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data penimbangan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
