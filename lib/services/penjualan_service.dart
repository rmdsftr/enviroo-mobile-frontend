import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class PenjualanService {
  static Future<Map<String, dynamic>> getRiwayatEksternal(String bankId, {String? startDate, String? endDate}) async {
    try {
      final base = Uri.parse('${ApiConfig.getRiwayatPenjualanEksternalUrl}/$bankId');
      final uri = (startDate != null || endDate != null)
          ? base.replace(queryParameters: {
              if (startDate != null) 'start_date': startDate,
              if (endDate != null) 'end_date': endDate,
            })
          : base;
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil riwayat penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailEksternal(String penjualanId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getDetailPenjualanEksternalUrl}/$penjualanId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getMitraEksternal(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getListMitraEksternalUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
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
      final response = await ApiClient.sendMultipart(() async {
        final request = http.MultipartRequest('POST', uri);
        request.fields['reward_id'] = rewardId.toString();
        request.fields['items_sampah'] = jsonEncode(itemsSampah);
        return request;
      });
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal menghitung preview penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> submitPenjualanEksternal({
    required String bankId,
    required String adminId,
    required int rewardId,
    String? mitraId,
    String? namaMitra,
    required List<Map<String, dynamic>> itemsSampah,
    required File buktiFoto,
  }) async {
    assert(
      mitraId != null || namaMitra != null,
      'mitraId atau namaMitra wajib diisi salah satu',
    );
    try {
      final uri = Uri.parse('${ApiConfig.addPenjualanEksternalUrl}/$bankId/$adminId');
      final response = await ApiClient.sendMultipart(() async {
        final request = http.MultipartRequest('POST', uri);
        request.fields['reward_id'] = rewardId.toString();
        if (mitraId != null) {
          request.fields['mitra_id'] = mitraId;
        } else {
          request.fields['nama_mitra'] = namaMitra!;
        }
        request.fields['items_sampah'] = jsonEncode(itemsSampah);
        request.files.add(await http.MultipartFile.fromPath('bukti_foto', buktiFoto.path));
        return request;
      });
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        return {'success': true, 'message': body['message'] ?? 'Penjualan berhasil dicatat', 'penjualan_id': body['penjualan_id'] ?? ''};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal menyimpan penjualan'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Map<String, dynamic> _connError(Object e) => {
        'success': false,
        'message': ApiFailure.from(e).pesan,
      };
}
