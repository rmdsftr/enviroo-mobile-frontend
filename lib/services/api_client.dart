import 'dart:convert';
import 'package:http/http.dart' as http;

/// HTTP client terpusat yang otomatis handle 401 dan 403:
/// - 401 → refresh token → retry sekali.
/// - 403 + code "ACCOUNT_INACTIVE" → force logout via [_onDeactivated].
///
/// Inisialisasi via [ApiClient.init] setelah login / restore session.
/// Services cukup pakai [ApiClient.get/post/patch/delete] tanpa perlu
/// tahu soal token atau refresh.
class ApiClient {
  static String Function()? _getToken;
  static Future<bool> Function()? _onUnauthorized;
  static Future<void> Function()? _onDeactivated;

  static void init({
    required String Function() getToken,
    required Future<bool> Function() onUnauthorized,
    Future<void> Function()? onDeactivated,
  }) {
    _getToken = getToken;
    _onUnauthorized = onUnauthorized;
    _onDeactivated = onDeactivated;
  }

  /// Token aktif saat ini — dipakai oleh multipart request yang tidak bisa
  /// dikirim lewat [_send] karena bukan [http.Response] biasa.
  static String get currentToken => _getToken?.call() ?? '';

  static Map<String, String> _headers([String? overrideToken]) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${overrideToken ?? _getToken?.call() ?? ''}',
      };

  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) makeRequest,
  ) async {
    final response = await makeRequest(_headers());

    if (response.statusCode == 401 && _onUnauthorized != null) {
      final refreshed = await _onUnauthorized!();
      if (refreshed) {
        // Retry sekali dengan token baru
        return makeRequest(_headers());
      }
    }

    if (response.statusCode == 403 && _onDeactivated != null) {
      try {
        final body = jsonDecode(response.body);
        if (body['code'] == 'ACCOUNT_INACTIVE') {
          await _onDeactivated!();
        }
      } catch (_) {}
    }

    return response;
  }

  static Future<http.Response> get(
    Uri uri, {
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => http.get(uri, headers: h).timeout(timeout));

  static Future<http.Response> post(
    Uri uri, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => http.post(uri, headers: h, body: body).timeout(timeout));

  static Future<http.Response> patch(
    Uri uri, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => http.patch(uri, headers: h, body: body).timeout(timeout));

  static Future<http.Response> delete(
    Uri uri, {
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => http.delete(uri, headers: h).timeout(timeout));
}
