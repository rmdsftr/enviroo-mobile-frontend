import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

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
        'page': page.toString(),
        'limit': limit.toString(),
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
      if (itemSembako.isNotEmpty) payload['item_sembako'] = itemSembako;
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
  }) async {
    try {
      final payload = <String, dynamic>{'reward_id': rewardId};
      if (nominalPenarikan != null) payload['nominal_penarikan'] = nominalPenarikan;
      if (itemSembako.isNotEmpty) payload['item_sembako'] = itemSembako;
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

  static Future<Map<String, dynamic>> konfirmasi({
    required String penarikanId,
    required String buktiFoto,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.konfirmasiPenarikanUrl}/$penarikanId'),
        body: jsonEncode({'bukti_foto': buktiFoto}),
        timeout: const Duration(seconds: 20),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Penarikan berhasil dikonfirmasi'};
      }
      return {'success': false, 'message': body['error'] ?? body['message'] ?? 'Gagal mengkonfirmasi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: $e'};
    }
  }

  static Future<Map<String, dynamic>> batal(String penarikanId) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.batalPenarikanUrl}/$penarikanId'),
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
