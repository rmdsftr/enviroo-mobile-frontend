import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'network_status.dart';

enum ApiFailureKind { offline, timeout, certificate, server, unknown }

class ApiFailure implements Exception {
  final ApiFailureKind kind;
  final String pesan;

  const ApiFailure(this.kind, this.pesan);

  static ApiFailureKind klasifikasi(Object e) {
    if (e is ApiFailure) return e.kind;
    if (e is HandshakeException || e is CertificateException) {
      return ApiFailureKind.certificate;
    }
    if (e is SocketException) return ApiFailureKind.offline;
    if (e is http.ClientException) return ApiFailureKind.offline;
    if (e is TimeoutException) return ApiFailureKind.timeout;
    if (e is FormatException) return ApiFailureKind.server;
    return ApiFailureKind.unknown;
  }

  static String pesanUntuk(ApiFailureKind kind) {
    switch (kind) {
      case ApiFailureKind.offline:
        return 'Koneksi ke server terputus. Periksa jaringan kamu lalu coba lagi.';
      case ApiFailureKind.timeout:
        return 'Server tidak merespons. Coba lagi sebentar lagi.';
      case ApiFailureKind.certificate:
        return 'Koneksi ke server tidak aman.';
      case ApiFailureKind.server:
        return 'Respons server tidak bisa dibaca.';
      case ApiFailureKind.unknown:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  factory ApiFailure.from(Object e) {
    final kind = klasifikasi(e);
    NetworkStatus.instance.reportFailure(kind);
    if (e is ApiFailure) return e;
    return ApiFailure(kind, pesanUntuk(kind));
  }

  @override
  String toString() => pesan;
}
