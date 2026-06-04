import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';

class PenimbanganService {
  static Future<Map<String, dynamic>> checkJadwalHariIni(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkPenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'status': body['status']};
      if (response.statusCode == 409) return {'success': true, 'status': body['status'] ?? 'active_session'};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkActiveSession(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.checkActivePenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'is_active': body['is_active'] ?? false};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengecek jadwal'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> addPenimbangan(
    String bankId,
    String adminId, {
    bool forceDadakan = false,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse('${ApiConfig.addPenimbanganUrl}/$bankId/$adminId'),
        body: jsonEncode({'force_dadakan': forceDadakan}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Sesi penimbangan berhasil dimulai'};
      }
      return {'success': false, 'statusCode': response.statusCode, 'message': body['error'] ?? 'Gagal memulai penimbangan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> updatePenimbangan(
    String penimbanganId,
    String adminId,
    String status,
  ) async {
    try {
      final response = await ApiClient.patch(
        Uri.parse('${ApiConfig.updatePenimbanganUrl}/$penimbanganId/$adminId'),
        body: jsonEncode({'status_penimbangan': status}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data'], 'message': body['message'] ?? 'Status berhasil diperbarui'};
      }
      return {'success': false, 'message': body['error'] ?? 'Gagal memperbarui status'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSesiAktif(String penimbanganId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getSesiAktifUrl}/$penimbanganId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data sesi'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPenimbangan(String bankId) async {
    try {
      final response = await ApiClient.get(Uri.parse('${ApiConfig.getPenimbanganUrl}/$bankId'));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['error'] ?? 'Gagal mengambil data penimbangan'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
