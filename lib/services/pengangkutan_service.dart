import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:enviroo/core/config/api_config.dart';
import '../models/sesi_pengangkutan_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class PengangkutanService {
  static Future<Map<String, dynamic>> checkJadwalHariIni(String bsiId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkPengangkutanUrl}/$bsiId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {
          'success': true,
          'total_jadwal_hari_ini': body['total_jadwal_hari_ini'] ?? 0,
          'jadwal_hari_ini': body['jadwal_hari_ini'] ?? [],
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> startSesi(
    String bsiId,
    String bsuId,
    String adminBsiId, {
    bool isMandiri = false,
    String jadwalId = '',
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiConfig.startPengangkutanUrl),
        body: jsonEncode({
          'bsi_id': bsiId,
          'bsu_id': bsuId,
          'admin_bsi_id': adminBsiId,
          'is_mandiri': isMandiri,
          'jadwal_id': jadwalId,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Sesi pengangkutan berhasil dimulai'};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal memulai sesi pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getAllPengangkutan(String bankId, {String? startDate, String? endDate}) async {
    try {
      final base = Uri.parse('${ApiConfig.getAllPengangkutanUrl}/$bankId');
      final uri = (startDate != null || endDate != null)
          ? base.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : base;
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getUnitBsi(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getUnitBsiUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil daftar BSU'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) return {'success': true, 'message': body['message'] ?? 'Status berhasil diperbarui'};
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal memperbarui status'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (response.sukses) return {'success': true, 'message': body['message'] ?? 'Permintaan berhasil diajukan'};
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal mengajukan permintaan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> listSampah(String bsiId, String bsuId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.listSampahPengangkutanUrl}/$bsiId/$bsuId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil list sampah'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> inputSampah(
    String qrData,
    String adminBsiId,
    List<Map<String, dynamic>> items, {
    File? buktiFoto,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.inputSampahPengangkutanUrl);
      final response = await ApiClient.sendMultipart(() async {
        final request = http.MultipartRequest('POST', uri);
        request.fields['qr_data'] = qrData;
        request.fields['admin_bsi_id'] = adminBsiId;
        request.fields['items'] = jsonEncode(items);
        if (buktiFoto != null) {
          request.files.add(await http.MultipartFile.fromPath('bukti_foto', buktiFoto.path));
        }
        return request;
      });

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
      if (response.sukses) {
        return {'success': true, 'total_item': body['total_item'] ?? 0, 'message': body['message'] ?? 'Sampah berhasil diinput'};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal menginput sampah pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> previewPengangkutan(
    String pengangkutanId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.previewPengangkutanUrl}/$pengangkutanId');
      final response = await ApiClient.sendMultipart(() async {
        final request = http.MultipartRequest('POST', uri);
        request.fields['items'] = jsonEncode(
          items.map((e) => {'sampah_id': e['sampah_id'], 'qty': e['qty']}).toList(),
        );
        return request;
      });
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat preview pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> detailSampah(String pengangkutanId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.detailSampahPengangkutanUrl}/$pengangkutanId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal mengambil detail pengangkutan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getAllActivePengangkutan(String bsiId, String adminId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getAllActivePengangkutanUrl}/$bsiId/$adminId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil sesi aktif'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> checkSesiActive(String bsuId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.baseUrl}/pengangkutan/check-sesi-active/$bsuId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek sesi aktif'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
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
      if (res.sukses) {
        return (data: DetailSesiPengangkutanModel.fromJson(body), error: null);
      }
      return (data: null, error: body['error'] as String? ?? 'Gagal memuat detail sesi');
    } catch (e) {
      return (data: null, error: ApiFailure.from(e).pesan);
    }
  }
}
