import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Wrapper untuk semua endpoint /redeem-bsu/*.
/// Konsisten dengan style service lain di project (http + static methods + Map response).
class RedeemBsuService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /redeem-bsu/list-redeem/:bank_id?status=...
  static Future<Map<String, dynamic>> listRedeem(
    String bankId,
    String token, {
    String? status,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.listRedeemBsuUrl}/$bankId').replace(
        queryParameters: status == null ? null : {'status': status},
      );
      final response = await http.get(uri, headers: _headers(token)).timeout(
            const Duration(seconds: 10),
          );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'] ?? []};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal memuat list redeem',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// GET /redeem-bsu/detail/:redeem_id
  static Future<Map<String, dynamic>> getDetailRedeem(
    String redeemId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.detailRedeemBsuUrl}/$redeemId'),
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

  /// POST /redeem-bsu/request/:bsu_id/:admin_bsu_id
  /// Body sesuai struct backend:
  /// { reward_id, poin_redeem, redeem_sembako_item: [{sembako_id, qty}] }
  static Future<Map<String, dynamic>> requestRedeem({
    required String bsuId,
    required String adminBsuId,
    required String token,
    required int rewardId,
    required double poinRedeem,
    List<Map<String, dynamic>> redeemSembakoItem = const [],
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.requestRedeemBsuUrl}/$bsuId/$adminBsuId'),
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

  /// PATCH /redeem-bsu/cancel/:transaksi_id/:admin_bsu_id
  static Future<Map<String, dynamic>> cancelRedeem({
    required String transaksiId,
    required String adminBsuId,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.cancelRedeemBsuUrl}/$transaksiId/$adminBsuId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message'] ?? 'Pengajuan dibatalkan'};
      }
      return {
        'success': false,
        'message': body['message'] ?? body['error'] ?? 'Gagal membatalkan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung: ${e.toString()}'};
    }
  }

  /// GET /redeem-bsu/verifikasi-manual/:transaksi_id/:admin_bsi_id
  static Future<Map<String, dynamic>> verifikasiManual({
    required String transaksiId,
    required String adminBsiId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.verifikasiManualRedeemUrl}/$transaksiId/$adminBsiId'),
        headers: _headers(token),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['status'] == 'verified') {
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

  /// POST /redeem-bsu/confirm/:transaksi_id/:admin_bsi_id
  /// status_transaksi: approved | rejected | success
  static Future<Map<String, dynamic>> confirmRedeem({
    required String transaksiId,
    required String adminBsiId,
    required String token,
    required String statusTransaksi,
    String? catatan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.confirmRedeemBsuUrl}/$transaksiId/$adminBsiId'),
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
