import 'dart:convert';
import '../config/api_config.dart';
import '../models/bank_sampah_model.dart';
import 'api_client.dart';

class BankService {
  static Future<Map<String, dynamic>> getAllBankSampah() async {
    try {
      final response = await ApiClient.get(Uri.parse(ApiConfig.getAllBankUrl));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final banks = (body['data'] as List? ?? [])
            .map((e) => BankSampahModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': banks};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data bank sampah'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
