import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import '../models/bank_sampah_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class BankService {
  static Future<Map<String, dynamic>> getAllBankSampah() async {
    try {
      final response = await ApiClient.get(Uri.parse(ApiConfig.getAllBankUrl));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        final banks = (body['data'] as List? ?? [])
            .map((e) => BankSampahModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': banks};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data bank sampah'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  /// Daftar BSU di bawah sebuah BSI. Pindahan dari `NasabahService` - isinya
  /// bank unit, sebangun dengan [getAllBankSampah] di atas.
  static Future<Map<String, dynamic>> getBsuByBsiId(String bsiId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getUnitBsiUrl}/$bsiId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data BSU'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
