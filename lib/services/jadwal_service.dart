import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import '../models/jadwal_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class JadwalService {
  static Future<Map<String, dynamic>> getJadwalByBankId(String bankId, {required int month, required int year}) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getJadwalUrl}/$bankId?month=$month&year=$year'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data jadwal'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  // Khusus petugas_bsm — GET /jadwal/penimbangan/:bank_id?month=&year=
  static Future<Map<String, dynamic>> getJadwalPenimbanganBsm(
    String bankId, {
    required int month,
    required int year,
  }) async {
    try {
      final response = await ApiClient.get(Uri.parse(
          '${ApiConfig.getJadwalPenimbanganBsmUrl}/$bankId?month=$month&year=$year'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        final List rawList = body['data'] ?? [];
        final list = rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => JadwalPenimbanganItem.fromJson(e))
            .toList();
        return {'success': true, 'data': list};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil jadwal penimbangan'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
