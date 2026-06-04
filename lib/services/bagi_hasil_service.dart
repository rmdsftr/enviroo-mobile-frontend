import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class BagiHasilService {
  static Future<Map<String, dynamic>> previewBagiHasil(String penjualanId, String bankId) async {
    try {
      final response = await ApiClient.post(Uri.parse('${ApiConfig.previewBagiHasilUrl}/$penjualanId/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal menghitung preview bagi hasil'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> submitBagiHasil(
    String penjualanId,
    String bankId,
    String adminId,
  ) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.submitBagiHasilUrl}/$penjualanId/$bankId'),
        body: jsonEncode({'admin_id': adminId}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'message': body['message'] ?? 'Bagi hasil berhasil'};
      return {'success': false, 'message': body['error'] ?? 'Gagal melakukan bagi hasil'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailBagiHasil(String penjualanId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.detailBagiHasilUrl}/$penjualanId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail bagi hasil'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getListBagiHasilNasabah(String nasabahId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.listBagiHasilNasabahUrl}/$nasabahId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil list bagi hasil'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getListBagiHasilBsu(String bsuId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.listBagiHasilBsuUrl}/$bsuId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil list bagi hasil BSU'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailBagiHasilBsu(String penerimaId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.detailBagiHasilBsuUrl}/$penerimaId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail bagi hasil BSU'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailBagiHasilNasabah(String penerimaId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.detailBagiHasilNasabahUrl}/$penerimaId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail bagi hasil nasabah'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getListDistribusiSisaBsu(String bsuId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.listBhBankBsuUrl}/$bsuId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat distribusi sisa'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailDistribusiSisaBsu(String penerimaSisaId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.detailBhBankBsuUrl}/$penerimaSisaId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal memuat detail distribusi sisa'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getListBagiHasilBank(
    String bankId,
    String startDate,
    String endDate,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.listBagiHasilBankUrl}/$bankId')
          .replace(queryParameters: {'start_date': startDate, 'end_date': endDate});
      final response = await ApiClient.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil riwayat bagi hasil'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Future<Map<String, dynamic>> getDetailBagiHasilBank(String bagiHasilId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.detailBagiHasilBankUrl}/$bagiHasilId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil detail bagi hasil'};
    } catch (e) {
      return _connError(e);
    }
  }

  static Map<String, dynamic> _connError(Object e) => {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
}
