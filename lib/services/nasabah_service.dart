import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

/// Data nasabah dan petugas sebuah bank.
///
/// `getBsuByBsiId` dulu di sini juga, tapi isinya daftar bank unit - bukan
/// orang - jadi sudah pindah ke [BankService] bersama `getAllBankSampah`.
///
/// Catatan: [getAdminByBankId] mengembalikan daftar PETUGAS, bukan nasabah.
/// Belum dipindah karena pemakainya cuma satu layar di modul pengangkutan.
class NasabahService {
  static Future<Map<String, dynamic>> getNasabahByBankId(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getNasabahBankUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data nasabah'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getAdminByBankId(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getAdminBankUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true, 'data': body['data'] ?? []};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data petugas'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
