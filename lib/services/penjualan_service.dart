import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_client.dart';

class PenjualanService {
  static Future<Map<String, dynamic>> getRiwayatEksternal(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getRiwayatPenjualanEksternalUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil riwayat penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailEksternal(String penjualanId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailPenjualanEksternalUrl}/$penjualanId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getMitraEksternal(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getListMitraEksternalUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil list mitra'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> previewPenjualanEksternal({
    required String bankId,
    required int rewardId,
    required List<Map<String, dynamic>> itemsSampah,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.previewPenjualanEksternalUrl}/$bankId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.headers['Accept'] = 'application/json';
      request.fields['reward_id'] = rewardId.toString();
      request.fields['items_sampah'] = jsonEncode(itemsSampah);
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal menghitung preview penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> submitPenjualanEksternal({
    required String bankId,
    required String adminId,
    required int rewardId,
    required String identitasPembeli,
    required List<Map<String, dynamic>> itemsSampah,
    required File buktiFoto,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.addPenjualanEksternalUrl}/$bankId/$adminId');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer ${ApiClient.currentToken}';
      request.headers['Accept'] = 'application/json';
      request.fields['reward_id'] = rewardId.toString();
      request.fields['identitas_pembeli'] = identitasPembeli;
      request.fields['items_sampah'] = jsonEncode(itemsSampah);
      request.files.add(await http.MultipartFile.fromPath('bukti_foto', buktiFoto.path));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': body['message'] ?? 'Penjualan berhasil dicatat', 'penjualan_id': body['penjualan_id'] ?? ''};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal menyimpan penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Map<String, dynamic> _connError(Object e) => {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
}
