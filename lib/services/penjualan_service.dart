import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service untuk fitur Penjualan Eksternal Bank Sampah (BSI/BSM).
/// Menangani komunikasi HTTP ke backend Golang `enviroo-be`.
class PenjualanService {
  // ─── GET /penjualan/riwayat-eksternal/:bank_id ─────────────────────────────
  static Future<Map<String, dynamic>> getRiwayatEksternal(
      String bankId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getRiwayatPenjualanEksternalUrl}/$bankId'),
        headers: _headers(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['error'] ?? 'Gagal mengambil riwayat penjualan',
      };
    } catch (e) {
      return _connError(e);
    }
  }

  // ─── GET /penjualan/detail-eksternal/:penjualan_id ─────────────────────────
  static Future<Map<String, dynamic>> getDetailEksternal(
      String penjualanId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getDetailPenjualanEksternalUrl}/$penjualanId'),
        headers: _headers(token),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'message': body['error'] ?? 'Gagal mengambil detail penjualan',
      };
    } catch (e) {
      return _connError(e);
    }
  }

  // ─── POST /penjualan/add-eksternal/:bank_id ────────────────────────────────
  /// Submit penjualan eksternal — multipart, dengan items_sampah & items_sembako
  /// sudah ter-jsonEncode menjadi string.
  static Future<Map<String, dynamic>> submitPenjualanEksternal({
    required String bankId,
    required String adminId,
    required String token,
    required int rewardId,
    required String identitasPembeli,
    required List<Map<String, dynamic>> itemsSampah,
    List<Map<String, dynamic>>? itemsSembako,
    required File buktiFoto,
  }) async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.addPenjualanEksternalUrl}/$bankId/$adminId');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['reward_id'] = rewardId.toString();
      request.fields['identitas_pembeli'] = identitasPembeli;
      request.fields['items_sampah'] = jsonEncode(itemsSampah);
      if (itemsSembako != null && itemsSembako.isNotEmpty) {
        request.fields['items_sembako'] = jsonEncode(itemsSembako);
      }

      request.files.add(
        await http.MultipartFile.fromPath('bukti_foto', buktiFoto.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Penjualan berhasil dicatat',
        };
      }
      return {
        'success': false,
        'message': body['error'] ?? 'Gagal menyimpan penjualan',
      };
    } catch (e) {
      return _connError(e);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> _connError(Object e) => {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
}
