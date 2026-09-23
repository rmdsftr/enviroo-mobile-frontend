import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

/// Melayani **dua** prefix endpoint: `/reward` dan `/nilai-reward`.
///
/// Ini pengecualian sadar dari aturan "satu prefix = satu service". Keduanya
/// satu domain dan masing-masing cuma punya satu endpoint, jadi memecahnya
/// hanya menghasilkan dua pasang file yang masing-masing membungkus satu
/// panggilan.
class RewardService {
  static Future<Map<String, dynamic>> getAllReward() async {
    try {
      final response = await ApiClient.get(Uri.parse(ApiConfig.getAllRewardUrl));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data reward'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getNilaiReward(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getNilaiRewardUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil nilai reward'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
