import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';

class SetoranService {
  static Future<Map<String, dynamic>> verifikasiSetoran(
    String penimbanganId,
    String nasabahId,
    String adminId,
  ) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.verifikasiSetoranUrl}/$penimbanganId/$nasabahId/$adminId'),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': true,
        'status': body['status'] ?? 'unverified',
        'message': body['message'] ?? '',
        'data': body['data'],
      };
    } catch (e) {
      return {'success': false, 'status': 'unverified', 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> previewSetoran(
    String penimbanganId,
    String nasabahId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.previewSetoranUrl}/$penimbanganId/$nasabahId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.headers['Accept'] = 'application/json';
      request.fields['items'] = jsonEncode(items);
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat preview setoran'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getListSetoranPenimbangan(String penimbanganId) async {
    try {
      final res = await ApiClient.get(Uri.parse('${ApiConfig.listSetoranPenimbanganUrl}/$penimbanganId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat data setoran'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getDetailSetoranNasabah(String setoranId) async {
    try {
      final res = await ApiClient.get(Uri.parse('${ApiConfig.detailSetoranNasabahUrl}/$setoranId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat detail setoran'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getListSetoranNasabah(String nasabahId) async {
    try {
      final res = await ApiClient.get(Uri.parse('${ApiConfig.listSetoranNasabahUrl}/$nasabahId'));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat riwayat setoran'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> inputSetoran(
    String penimbanganId,
    String nasabahId,
    String adminId,
    List<Map<String, dynamic>> items, {
    bool viaManual = false,
    File? fotoFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.inputSetoranUrl}/$penimbanganId/$nasabahId/$adminId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.headers['Accept'] = 'application/json';
      request.fields['via'] = viaManual ? 'manual' : 'qr';
      request.fields['items'] = jsonEncode(items);
      if (viaManual && fotoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', fotoFile.path));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {
          'success': true,
          'setoran_id': body['setoran_id'] ?? '',
          'total_item': body['total_item'] ?? 0,
          'total_poin': body['total_poin'] ?? 0,
          'message': body['message'] ?? 'Setoran berhasil dicatat',
        };
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal menyimpan setoran'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
