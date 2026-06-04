import 'dart:convert';
import '../config/api_config.dart';
import '../models/notifikasi_model.dart';
import 'api_client.dart';

class NotifikasiService {
  static Future<Map<String, dynamic>> registerFcmToken(String fcmToken) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse(ApiConfig.updateFcmTokenUrl),
        body: jsonEncode({'fcm_token': fcmToken}),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': body['error'] ?? 'Gagal mendaftarkan FCM token'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getNotifikasi(String userId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse('${ApiConfig.getNotifikasiUrl}/$userId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final list = (body['data'] as List? ?? [])
            .map((e) => NotifikasiModel.fromJson(e))
            .toList();
        return {'success': true, 'data': list};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil notifikasi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> markAsRead(String notifId) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.markReadUrl}/$notifId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': body['error'] ?? 'Gagal menandai notifikasi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> markAllAsRead(String userId) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.markAllReadUrl}/$userId'),
        timeout: const Duration(seconds: 10),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': body['error'] ?? 'Gagal menandai semua notifikasi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
