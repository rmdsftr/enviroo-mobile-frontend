import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PengangkutanService {
  /// Cek jadwal pengangkutan hari ini untuk pasangan BSI↔BSU.
  /// GET /pengangkutan/check/:bsi_id/:bsu_id
  /// Mengembalikan status: "scheduled" | "dadakan"
  static Future<Map<String, dynamic>> checkJadwal(
    String bsiId,
    String bsuId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.checkPengangkutanUrl}/$bsiId/$bsuId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'status': body['status'] ?? 'dadakan'};
      } else {
        return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Mulai sesi pengangkutan.
  /// POST /pengangkutan/start
  static Future<Map<String, dynamic>> startSesi(
    String bsiId,
    String bsuId,
    String adminBsiId,
    String token, {
    bool statusDadakan = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.startPengangkutanUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bsi_id': bsiId,
          'bsu_id': bsuId,
          'admin_bsi_id': adminBsiId,
          'status_dadakan': statusDadakan,
        }),
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': body['data'],
          'message': body['message'] ?? 'Sesi pengangkutan berhasil dimulai',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body['error'] ?? 'Gagal memulai sesi pengangkutan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Mendapatkan semua data riwayat pengangkutan suatu bank.
  /// GET /pengangkutan/get-all/:bank_id
  static Future<Map<String, dynamic>> getAllPengangkutan(
    String bankId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getAllPengangkutanUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data pengangkutan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Mendapatkan daftar BSU unit di bawah BSI.
  /// GET /bsi/get-unit/:bank_id
  static Future<Map<String, dynamic>> getUnitBsi(
    String bankId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getUnitBsiUrl}/$bankId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {'success': false, 'message': body['error'] ?? 'Gagal mengambil daftar BSU'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Update status pengangkutan oleh Admin BSI.
  /// PATCH /pengangkutan/update/:pengangkutan_id/:admin_bsi_id
  /// [notes] wajib diisi jika newStatus adalah 'rejected' atau 'canceled'.
  static Future<Map<String, dynamic>> updateStatus(
    String pengangkutanId,
    String adminBsiId,
    String currentStatus,
    String newStatus,
    String token, {
    String notes = '',
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.updatePengangkutanUrl}/$pengangkutanId/$adminBsiId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_status': currentStatus,
          'new_status': newStatus,
          'notes': notes,
        }),
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': body['message'] ?? 'Status berhasil diperbarui',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body['error'] ?? 'Gagal memperbarui status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Request pengangkutan oleh Admin BSU (di luar jadwal rutin).
  /// POST /pengangkutan/request/:bsu_id/:admin_bsu_id
  /// Body: { tanggal: ISO8601, jam_mulai: "HH:mm", notes: string }
  static Future<Map<String, dynamic>> requestPengangkutan(
    String bsuId,
    String adminBsuId,
    DateTime tanggal,
    String jamMulai,
    String notes,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.requestPengangkutanUrl}/$bsuId/$adminBsuId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tanggal': '${tanggal.year.toString().padLeft(4, '0')}-${tanggal.month.toString().padLeft(2, '0')}-${tanggal.day.toString().padLeft(2, '0')}',
          'jam_mulai': jamMulai,
          'notes': notes,
        }),
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message'] ?? 'Permintaan berhasil diajukan'};
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body['error'] ?? 'Gagal mengajukan permintaan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Ambil daftar sampah yang tersedia untuk diangkut dari BSU ke BSI,
  /// beserta stok saat ini di BSU tersebut.
  /// GET /pengangkutan/list-sampah/:bsi_id/:bsu_id
  static Future<Map<String, dynamic>> listSampah(
    String bsiId,
    String bsuId,
    String token,
  ) async {
    try {
      final url = '${ApiConfig.listSampahPengangkutanUrl}/$bsiId/$bsuId';
      print('=== PengangkutanService.listSampah ===');
      print('URL: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      } else {
        return {'success': false, 'message': body['error'] ?? 'Gagal mengambil list sampah'};
      }
    } catch (e) {
      print('Error in listSampah: $e');
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Input data setoran sampah pengangkutan oleh Admin BSI.
  /// POST /pengangkutan/input/:pengangkutan_id/:admin_bsi_id/:admin_bsu_id
  /// Multipart form: items (JSON string), bukti_foto (file optional).
  static Future<Map<String, dynamic>> inputSampah(
    String pengangkutanId,
    String adminBsiId,
    String adminBsuId,
    List<Map<String, dynamic>> items,
    String token, {
    File? buktiFoto,
  }) async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.inputSampahPengangkutanUrl}/$pengangkutanId/$adminBsiId/$adminBsuId');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['items'] = jsonEncode(items);

      if (buktiFoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'bukti_foto',
          buktiFoto.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'total_item': body['total_item'] ?? 0,
          'total_poin': body['total_poin'] ?? 0,
          'message': body['message'] ?? 'Sampah berhasil diinput',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body['error'] ?? 'Gagal menginput sampah pengangkutan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }

  /// Ambil detail sampah dari pengangkutan tertentu (untuk struk).
  /// GET /pengangkutan/detail-sampah/:pengangkutan_id
  /// Response.data: { header, items[] }
  static Future<Map<String, dynamic>> detailSampah(
    String pengangkutanId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.detailSampahPengangkutanUrl}/$pengangkutanId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body['error'] ?? 'Gagal mengambil detail pengangkutan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: ${e.toString()}'};
    }
  }
}
