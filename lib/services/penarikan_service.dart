import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';

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
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal memuat daftar penarikan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDetail(String penarikanId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailPenarikanUrl}/$penarikanId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Detail tidak ditemukan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  static Future<Map<String, dynamic>> preview({
    required String nasabahId,
    required int rewardId,
    double? nominalPenarikan,
    List<Map<String, dynamic>> itemSembako = const [],
  }) async {
    try {
      final payload = <String, dynamic>{'reward_id': rewardId};
      if (nominalPenarikan != null) payload['nominal_penarikan'] = nominalPenarikan;
      if (itemSembako.isNotEmpty) payload['item_barang'] = itemSembako;
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.previewPenarikanUrl}/$nasabahId'),
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Preview gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  static Future<Map<String, dynamic>> ajukan({
    required String nasabahId,
    required int rewardId,
    double? nominalPenarikan,
    List<Map<String, dynamic>> itemSembako = const [],
    DateTime? deadlineKonfirmasi,
    String? catatan,
  }) async {
    try {
      final payload = <String, dynamic>{'reward_id': rewardId};
      if (nominalPenarikan != null) payload['nominal_penarikan'] = nominalPenarikan;
      if (itemSembako.isNotEmpty) payload['item_barang'] = itemSembako;
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Pengajuan berhasil'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Pengajuan gagal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
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
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal memuat daftar penarikan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  /// Menyelesaikan penarikan (approved -> completed) via PATCH /penarikan/selesai.
  /// Dua jalur:
  /// - QR: isi [qrData] (mentah persis hasil scan), [catatan] opsional. [nasabahId]/
  ///   [penarikanId]/[buktiFoto] diabaikan backend di jalur ini.
  /// - Manual: isi [nasabahId] + [penarikanId] + [buktiFoto] (wajib semua),
  ///   [catatan] wajib non-kosong.
  static Future<Map<String, dynamic>> selesaikanPenarikan({
    String? qrData,
    String? nasabahId,
    String? penarikanId,
    String? buktiFoto,
    String? catatan,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (qrData != null) payload['qr_data'] = qrData;
      if (nasabahId != null) payload['nasabah_id'] = nasabahId;
      if (penarikanId != null) payload['penarikan_id'] = penarikanId;
      if (buktiFoto != null) payload['bukti_foto'] = buktiFoto;
      if (catatan != null && catatan.isNotEmpty) payload['catatan'] = catatan;
      final response = await ApiClient.patch(
        Uri.parse(ApiConfig.selesaiPenarikanUrl),
        body: jsonEncode(payload),
        timeout: const Duration(seconds: 20),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Penarikan berhasil diselesaikan'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal menyelesaikan penarikan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
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
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan ditolak'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal menolak pengajuan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
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
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan disetujui'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal menyetujui pengajuan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
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
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan dibatalkan'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal membatalkan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }
}
