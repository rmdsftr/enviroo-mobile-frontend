import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class SetoranService {
  /// Verifikasi setoran nasabah — cek penimbangan aktif, nasabah aktif, admin aktif.
  /// GET /setoran/verifikasi/:penimbangan_id/:nasabah_id/:admin_id
  /// Mengembalikan {success, status ("verified"/"unverified"), message}
  static Future<Map<String, dynamic>> verifikasiSetoran(
    String penimbanganId,
    String nasabahId,
    String adminId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.verifikasiSetoranUrl}/$penimbanganId/$nasabahId/$adminId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> body = jsonDecode(response.body);

      return {
        'success': true,
        'status': body['status'] ?? 'unverified',
        'message': body['message'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'status': 'unverified',
        'message': 'Gagal terhubung ke server: ${e.toString()}',
      };
    }
  }

  /// Input setoran nasabah — kirim data item sampah + foto (jika via=manual).
  /// POST /setoran/input/:penimbangan_id/:nasabah_id/:admin_id
  /// Body: Multipart Form (via, items JSON string, foto file)
  static Future<Map<String, dynamic>> inputSetoran(
    String penimbanganId,
    String nasabahId,
    String adminId,
    List<Map<String, dynamic>> items,
    String token, {
    bool viaManual = false,
    File? fotoFile,
  }) async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.inputSetoranUrl}/$penimbanganId/$nasabahId/$adminId');

      final request = http.MultipartRequest('POST', uri);

      // Header auth
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Field: via
      request.fields['via'] = viaManual ? 'manual' : 'qr';

      // Field: items (JSON string)
      request.fields['items'] = jsonEncode(items);

      // Field: foto (hanya jika manual)
      if (viaManual && fotoFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'foto',
          fotoFile.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> body = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'setoran_id': body['setoran_id'] ?? '',
          'total_item': body['total_item'] ?? 0,
          'total_poin': body['total_poin'] ?? 0,
          'message': body['message'] ?? 'Setoran berhasil dicatat',
        };
      } else {
        return {
          'success': false,
          'message': body['error'] ?? 'Gagal menyimpan setoran',
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
