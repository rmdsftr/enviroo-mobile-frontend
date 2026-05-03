import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/bank_sampah_model.dart';

class BankService {
  static Future<Map<String, dynamic>> getAllBankSampah(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getAllBankUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> rawData = body['data'] ?? [];
        List<BankSampahModel> banks = rawData
            .map((e) => BankSampahModel.fromJson(e as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'data': banks,
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal mengambil data bank sampah',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }
}
