import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/sesi_pengangkutan_model.dart';
import 'api_client.dart';

class PengangkutanService {
  static Future<Map<String, dynamic>> checkJadwal(String bsiId, String bsuId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkPengangkutanUrl}/$bsiId/$bsuId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'status': body['status'] ?? 'dadakan'};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> startSesi(
    String bsiId,
    String bsuId,
    String adminBsiId, {
    bool statusDadakan = false,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.startPengangkutanUrl),
        body: jsonEncode({
          'bsi_id': bsiId,
          'bsu_id': bsuId,
          'admin_bsi_id': adminBsiId,
          'status_dadakan': statusDadakan,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Sesi pengangkutan berhasil dimulai'};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal memulai sesi pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllPengangkutan(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getAllPengangkutanUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUnitBsi(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getUnitBsiUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil daftar BSU'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateStatus(
    String pengangkutanId,
    String adminBsiId,
    String currentStatus,
    String newStatus, {
    String notes = '',
  }) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.updatePengangkutanUrl}/$pengangkutanId/$adminBsiId'),
        body: jsonEncode({'current_status': currentStatus, 'new_status': newStatus, 'notes': notes}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'message': body['message'] ?? 'Status berhasil diperbarui'};
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal memperbarui status'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> requestPengangkutan(
    String bsuId,
    String adminBsuId,
    DateTime tanggal,
    String jamMulai,
    String notes,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.requestPengangkutanUrl}/$bsuId/$adminBsuId'),
        body: jsonEncode({
          'tanggal': '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
          'jam_mulai': jamMulai,
          'notes': notes,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) return {'success': true, 'message': body['message'] ?? 'Permintaan berhasil diajukan'};
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal mengajukan permintaan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> listSampah(String bsiId, String bsuId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.listSampahPengangkutanUrl}/$bsiId/$bsuId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil list sampah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> inputSampah(
    String pengangkutanId,
    String adminBsiId,
    String adminBsuId,
    List<Map<String, dynamic>> items, {
    File? buktiFoto,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.inputSampahPengangkutanUrl}/$pengangkutanId/$adminBsiId/$adminBsuId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.headers['Accept'] = 'application/json';
      request.fields['items'] = jsonEncode(items);
      if (buktiFoto != null) {
        request.files.add(await http.MultipartFile.fromPath('bukti_foto', buktiFoto.path));
      }
      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      // Cek content-type sebelum jsonDecode — respons redirect atau error
      // non-JSON (misal 301/404 HTML dari Gin) akan melempar FormatException
      // jika langsung di-decode.
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Respons server tidak valid (${response.statusCode}). Pastikan data pengangkutan benar.',
        };
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {'success': true, 'total_item': body['total_item'] ?? 0, 'message': body['message'] ?? 'Sampah berhasil diinput'};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal menginput sampah pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> previewPengangkutan(
    String pengangkutanId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.previewPengangkutanUrl}/$pengangkutanId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.headers['Accept'] = 'application/json';
      request.fields['items'] = jsonEncode(
        items.map((e) => {'sampah_id': e['sampah_id'], 'qty': e['qty']}).toList(),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat preview pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> detailSampah(String pengangkutanId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailSampahPengangkutanUrl}/$pengangkutanId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal mengambil detail pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getAllActivePengangkutan(String bsiId, String adminId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getAllActivePengangkutanUrl}/$bsiId/$adminId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil sesi aktif'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkSesiActive(String bsuId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.baseUrl}/pengangkutan/check-sesi-active/$bsuId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek sesi aktif'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<({DetailSesiPengangkutanModel? data, String? error})> detailSesiActive(
    String pengangkutanId,
  ) async {
    try {
      final res = await ApiClient.get(
        Uri.parse('${ApiConfig.pengangkutanBase}/detail-sesi-active/$pengangkutanId'),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return (data: DetailSesiPengangkutanModel.fromJson(body), error: null);
      }
      return (data: null, error: body['error'] as String? ?? 'Gagal memuat detail sesi');
    } catch (e) {
      return (data: null, error: 'Tidak dapat terhubung ke server');
    }
  }
}
