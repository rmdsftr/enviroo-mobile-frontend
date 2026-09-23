import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

/// Serialize [dt] (jam lokal, diasumsikan WIB seperti sisa aplikasi) ke ISO-8601
/// dengan offset eksplisit, mis. "2026-08-16T15:00:00+07:00".
String _isoWib(DateTime dt) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)}';
  final time = '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  return '${date}T$time+07:00';
}

class PenarikanService {
  static Future<Map<String, dynamic>> getList({
    required String nasabahId,
    int? rewardId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, String>{
        if (rewardId != null) 'reward_id': rewardId.toString(),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final uri = Uri.parse('${ApiConfig.listPenarikanUrl}/$nasabahId')
          .replace(queryParameters: params);
      final response = await ApiClient.get(uri, timeout: const Duration(seconds: 15));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal memuat daftar penarikan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getDetail(String penarikanId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailPenarikanUrl}/$penarikanId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Detail tidak ditemukan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> preview({
    required String nasabahId,
    required int rewardId,
    double? nominalPenarikan,
    List<Map<String, dynamic>> itemBarang = const [],
  }) async {
    try {
      final payload = <String, dynamic>{'reward_id': rewardId};
      if (nominalPenarikan != null) payload['nominal_penarikan'] = nominalPenarikan;
      if (itemBarang.isNotEmpty) payload['item_barang'] = itemBarang;
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.previewPenarikanUrl}/$nasabahId'),
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Preview gagal'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> ajukan({
    required String nasabahId,
    required int rewardId,
    double? nominalPenarikan,
    List<Map<String, dynamic>> itemBarang = const [],
    DateTime? deadlineKonfirmasi,
    String? catatan,
  }) async {
    try {
      final payload = <String, dynamic>{'reward_id': rewardId};
      if (nominalPenarikan != null) payload['nominal_penarikan'] = nominalPenarikan;
      if (itemBarang.isNotEmpty) payload['item_barang'] = itemBarang;
      if (deadlineKonfirmasi != null) {
        payload['deadline_konfirmasi'] = _isoWib(deadlineKonfirmasi);
      }
      if (catatan != null && catatan.isNotEmpty) payload['catatan'] = catatan;
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.ajukanPenarikanUrl}/$nasabahId'),
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 20),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Pengajuan berhasil'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Pengajuan gagal'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getListByBank({
    required String bankId,
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 200,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final uri = Uri.parse('${ApiConfig.listPenarikanByBankUrl}/$bankId')
          .replace(queryParameters: params);
      final response = await ApiClient.get(uri, timeout: const Duration(seconds: 15));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal memuat daftar penarikan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  /// Menyelesaikan penarikan (approved -> completed) via PATCH /penarikan/selesai.
  ///
  /// Dikirim sebagai **multipart/form-data**, bukan JSON: sejak backend berubah,
  /// [buktiFoto] dikirim sebagai berkas mentah, bukan string base64. Nama
  /// field-nya tetap `bukti_foto` - yang berubah hanya encoding-nya.
  ///
  /// Dua jalur:
  /// - QR: isi [qrData] (mentah persis hasil scan), [catatan] opsional.
  ///   [buktiFoto] TIDAK disertakan - backend mengabaikannya lebih awal, jadi
  ///   percuma mengunggahnya. [nasabahId]/[penarikanId] diambil backend dari QR.
  /// - Manual: isi [nasabahId] + [penarikanId] + [buktiFoto] (wajib semua),
  ///   [catatan] wajib non-kosong.
  static Future<Map<String, dynamic>> selesaikanPenarikan({
    String? qrData,
    String? nasabahId,
    String? penarikanId,
    File? buktiFoto,
    String? catatan,
  }) async {
    try {
      final response = await ApiClient.sendMultipart(() async {
        final request = http.MultipartRequest(
          'PATCH',
          Uri.parse(ApiConfig.selesaiPenarikanUrl),
        );
        // qr_data tetap string JSON di field teks, bukan objek.
        if (qrData != null) request.fields['qr_data'] = qrData;
        if (nasabahId != null) request.fields['nasabah_id'] = nasabahId;
        if (penarikanId != null) request.fields['penarikan_id'] = penarikanId;
        if (catatan != null && catatan.isNotEmpty) request.fields['catatan'] = catatan;
        if (buktiFoto != null) {
          request.files.add(
            await http.MultipartFile.fromPath('bukti_foto', buktiFoto.path),
          );
        }
        return request;
      });
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'message': body['message'] ?? 'Penarikan berhasil diselesaikan'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal menyelesaikan penarikan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  /// Petugas menolak pengajuan pending. Endpoint konfirmasi/:id lain,
  /// dibedakan lewat field `status`.
  static Future<Map<String, dynamic>> tolakPengajuan({
    required String penarikanId,
    required String catatan,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.konfirmasiPenarikanUrl}/$penarikanId'),
        body: jsonEncode({'status': 'rejected', 'catatan': catatan}),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan ditolak'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal menolak pengajuan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  /// Petugas menyetujui pengajuan pending. Sama endpoint dengan [konfirmasi],
  /// dibedakan lewat field `status`.
  static Future<Map<String, dynamic>> setujuiPengajuan({
    required String penarikanId,
    required DateTime deadlineJemput,
    String? catatan,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': 'approved',
        'deadline_jemput': _isoWib(deadlineJemput),
      };
      if (catatan != null && catatan.isNotEmpty) payload['catatan'] = catatan;
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.konfirmasiPenarikanUrl}/$penarikanId'),
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan disetujui'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal menyetujui pengajuan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> batal(String penarikanId, {String? catatan}) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.batalPenarikanUrl}/$penarikanId'),
        body: jsonEncode({'catatan': catatan ?? ''}),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan dibatalkan'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal membatalkan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
