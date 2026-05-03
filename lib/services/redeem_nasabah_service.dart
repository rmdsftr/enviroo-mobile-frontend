import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RedeemNasabahService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /dashboard/saldo-nasabah/:nasabah_id
  static Future<Map<String, dynamic>> getSaldoNasabah(
    String nasabahId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.getSaldoNasabahUrl}/$nasabahId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? {}};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat saldo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// GET /redeem-nasabah/list-by-nasabah/:nasabah_id
  static Future<Map<String, dynamic>> listByNasabah(
    String nasabahId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.listRedeemNasabahByNasabahUrl}/$nasabahId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat daftar',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// GET /redeem-nasabah/list-by-bank/:bank_id
  static Future<Map<String, dynamic>> listByBank(
    String bankId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.listRedeemNasabahByBankUrl}/$bankId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat daftar',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// GET /redeem-nasabah/detail/:redeem_id
  static Future<Map<String, dynamic>> getDetail(
    String redeemId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.detailRedeemNasabahUrl}/$redeemId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Detail tidak ditemukan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// POST /redeem-nasabah/request/:nasabah_id
  static Future<Map<String, dynamic>> request({
    required String nasabahId,
    required String token,
    required int rewardId,
    required double poinRedeem,
    List<Map<String, dynamic>> redeemSembakoItem = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.requestRedeemNasabahUrl}/$nasabahId'),
        headers: _headers(token),
        body: jsonEncode({
          'reward_id': rewardId,
          'poin_redeem': poinRedeem,
          'redeem_sembako_item': redeemSembakoItem,
        }),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Pengajuan berhasil',
          'data': body,
        };
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Pengajuan gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// PATCH /redeem-nasabah/cancel/:transaksi_id/:nasabah_id
  static Future<Map<String, dynamic>> cancel({
    required String transaksiId,
    required String nasabahId,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.cancelRedeemNasabahUrl}/$transaksiId/$nasabahId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Dibatalkan'};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal membatalkan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// GET /redeem-nasabah/verifikasi/:transaksi_id/:petugas_id
  static Future<Map<String, dynamic>> verifikasi({
    required String transaksiId,
    required String petugasId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.verifikasiPenarikanUrl}/$transaksiId/$petugasId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'message': body['message']};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Verifikasi gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// POST /redeem-nasabah/confirm/:transaksi_id/:petugas_id
  static Future<Map<String, dynamic>> confirm({
    required String transaksiId,
    required String petugasId,
    required String token,
    required String statusTransaksi,
    String? catatan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.confirmRedeemNasabahUrl}/$transaksiId/$petugasId'),
        headers: _headers(token),
        body: jsonEncode({
          'status_transaksi': statusTransaksi,
          if (catatan != null) 'catatan': catatan,
        }),
      ).timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Berhasil'};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Konfirmasi gagal',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }
}
