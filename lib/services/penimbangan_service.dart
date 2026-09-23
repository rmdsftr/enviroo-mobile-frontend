import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import '../models/penimbangan_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class PenimbanganService {
  /// Ambil daftar sesi penimbangan hari ini (buat bottom sheet "Kelola Sesi Penimbangan").
  static Future<Map<String, dynamic>> getSesiHariIni(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkPenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        final List rawList = body['data'] ?? [];
        final data = rawList
            .map((e) => SesiHariIniItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil sesi hari ini'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> checkActiveSession(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkActivePenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'data': CheckActiveResult.fromJson(body)};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) {
        return {
          'success': true,
          'data': body['data'],
          'message': body['message'] ?? 'Sesi penimbangan berhasil dibatalkan',
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal membatalkan sesi penimbangan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) {
        return {
          'success': true,
          'message': body['message'] ?? 'Jadwal penimbangan berhasil dibatalkan',
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal membatalkan jadwal penimbangan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Status berhasil diperbarui'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal memperbarui status'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  /// Daftar setoran dalam satu sesi penimbangan.
  ///
  /// Endpoint-nya `/penimbangan/list-setoran`, jadi rumahnya di sini meski yang
  /// dikembalikan data setoran — satu prefix endpoint, satu service.
  static Future<Map<String, dynamic>> getListSetoran(String penimbanganId) async {
    try {
      final res = await ApiClient.get(
          Uri.parse('${ApiConfig.listSetoranPenimbanganUrl}/$penimbanganId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat data setoran'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data penimbangan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
