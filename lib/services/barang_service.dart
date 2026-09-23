import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class BarangService {
  static Future<Map<String, dynamic>> getBarangBank(String bankId, {int page = 1}) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getKatalogBarangUrl}/$bankId?page=$page'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {
          'success': true,
          'data': body['data'] ?? [],
          'pagination': body['pagination'],
        };
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat barang'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getDetailBarang(String produkId, String bankId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailBarangUrl}/$produkId?bank_id=$bankId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat detail barang'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal preview distribusi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) {
        return {'success': true, 'disba_id': body['disba_id']};
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal membuat sesi distribusi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getDetailDistribusi(String disbaId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailDistribusiBarangUrl}/$disbaId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? body};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat detail distribusi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getListDistribusi(String bankId, {String? startDate, String? endDate}) async {
    try {
      final base = Uri.parse('${ApiConfig.listDistribusiBarangUrl}/$bankId');
      final uri = (startDate != null || endDate != null)
          ? base.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : base;
      final response = await ApiClient.get(uri, timeout: const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal memuat riwayat distribusi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> addDistribusiBsuFromQr({
    required String disbaId,
    required String bsuId,
    required String adminBsuId,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.addDistribusiBsuV2Url),
        body: jsonEncode({
          'disba_id': disbaId,
          'bsu_id': bsuId,
          'admin_bsu_id': adminBsuId,
        }),
        timeout: const Duration(seconds: 15),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'data': body['data']};
      }
      return {'success': false, 'message': body['message'] ?? body['error'] ?? 'Gagal menerima distribusi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
