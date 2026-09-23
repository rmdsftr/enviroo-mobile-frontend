import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiClient {
  static String Function()? _getToken;
  static Future<bool> Function()? _onUnauthorized;
  static Future<void> Function()? _onDeactivated;

  static http.Client? _client;
  static http.Client get _httpClient {
    if (_client != null) return _client!;
    // Allowlist bad-cert disediakan oleh HttpOverrides.global
    // (EnvirooHttpOverrides, dipasang di main()). JANGAN set
    // badCertificateCallback di sini: itu menimpa allowlist tersebut dan
    // membuat sertifikat invalid dari host mana pun ikut diterima.
    _client = IOClient(HttpClient());
    return _client!;
  }

  static void init({
    required String Function() getToken,
    required Future<bool> Function() onUnauthorized,
    Future<void> Function()? onDeactivated,
  }) {
    _getToken = getToken;
    _onUnauthorized = onUnauthorized;
    _onDeactivated = onDeactivated;
  }

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

  /// Kirim request multipart lewat jalur yang sama dengan [_send] — 401 →
  /// refresh → ulangi, plus deteksi akun nonaktif.
  ///
  /// [build] dipanggil ulang saat retry karena [http.MultipartRequest] sekali
  /// pakai: stream file-nya sudah habis begitu dikirim. Jangan set header
  /// Authorization di dalam [build], diisi di sini.
  static Future<http.Response> sendMultipart(
    Future<http.MultipartRequest> Function() build, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    Future<http.Response> kirim() async {
      final request = await build();
      request.headers['Authorization'] = 'Bearer ${_getToken?.call() ?? ''}';
      request.headers['Accept'] = 'application/json';
      final streamed = await request.send().timeout(timeout);
      return http.Response.fromStream(streamed);
    }

    var response = await kirim();

    if (response.statusCode == 401 && _onUnauthorized != null) {
      final refreshed = await _onUnauthorized!();
      if (refreshed) response = await kirim();
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
      _send((h) => _httpClient.get(uri, headers: h).timeout(timeout));

  static Future<http.Response> post(
    Uri uri, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => _httpClient.post(uri, headers: h, body: body).timeout(timeout));

  static Future<http.Response> patch(
    Uri uri, {
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => _httpClient.patch(uri, headers: h, body: body).timeout(timeout));

  static Future<http.Response> delete(
    Uri uri, {
    Duration timeout = const Duration(seconds: 15),
  }) =>
      _send((h) => _httpClient.delete(uri, headers: h).timeout(timeout));
}
