import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';

class SembakoService {
  static Future<Map<String, dynamic>> getSembakoBank(String bankId, {int page = 1}) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getKatalogSembakoUrl}/$bankId?page=$page'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': body['data'] ?? [],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat sembako'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDetailSembako(String sembakoId, String bankId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailSembakoUrl}/$sembakoId?bank_id=$bankId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat detail sembako'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> previewDistribusiBsu({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.previewDistribusiBsuUrl}/$bsiId/$bsuId'),
        body: jsonEncode({'admin_bsi_id': adminBsiId, 'admin_bsu_id': '', 'items': items}),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal preview distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> generateQrDistribusi({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.qrDistribusiUrl),
        body: jsonEncode({'bsi_id': bsiId, 'bsu_id': bsuId, 'admin_bsi_id': adminBsiId, 'items': items}),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'disbako_id': body['disba_id']};
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal membuat sesi distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addDistribusiBsu({
    required String bsiId,
    required String bsuId,
    required String adminBsiId,
    required String adminBsuId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.addDistribusiBsuUrl}/$bsiId/$bsuId'),
        body: jsonEncode({'admin_bsi_id': adminBsiId, 'admin_bsu_id': adminBsuId, 'items': items}),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal mengirim distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDetailDistribusi(String disbakoId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailDistribusiSembakoUrl}/$disbakoId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat detail distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getListDistribusi(String bankId, {String? startDate, String? endDate}) async {
    try {
      final base = Uri.parse('${ApiConfig.listDistribusiSembakoUrl}/$bankId');
      final uri = (startDate != null || endDate != null)
          ? base.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : base;
      final response = await ApiClient.get(uri, timeout: const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat riwayat distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addDistribusiBsuFromQr({
    required String disbakoId,
    required String bsuId,
    required String adminBsuId,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.addDistribusiBsuV2Url),
        body: jsonEncode({
          'disba_id': disbakoId,
          'bsu_id': bsuId,
          'admin_bsu_id': adminBsuId,
        }),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal menerima distribusi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
