import 'dart:convert';
import 'package:enviroo/core/config/api_config.dart';
import '../models/notifikasi_model.dart';
import 'package:enviroo/core/network/api_client.dart';
import 'package:enviroo/core/network/api_failure.dart';

class NotifikasiService {
  static Future<Map<String, dynamic>> registerFcmToken(String fcmToken) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse(ApiConfig.updateFcmTokenUrl),
        body: jsonEncode({'fcm_token': fcmToken}),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true};
      return {'success': false, 'message': body['error'] ?? 'Gagal mendaftarkan FCM token'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> getNotifikasi(
    String roleTarget, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getNotifikasiUrl).replace(
        queryParameters: {
          'role_target': roleTarget,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      final response = await ApiClient.get(uri, timeout: const Duration(seconds: 10));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) {
        final list = (body['data'] as List? ?? [])
            .map((e) => NotifikasiModel.fromJson(e))
            .toList();
        return {'success': true, 'data': list, 'meta': body['meta']};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil notifikasi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> markAsRead(String notifId) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.markReadUrl}/$notifId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true};
      return {'success': false, 'message': body['error'] ?? 'Gagal menandai notifikasi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }

  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await ApiClient.patch(
        Uri.parse(ApiConfig.markAllReadUrl),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.sukses) return {'success': true};
      return {'success': false, 'message': body['error'] ?? 'Gagal menandai semua notifikasi'};
    } catch (e) {
      return {'success': false, 'message': ApiFailure.from(e).pesan};
    }
  }
}
