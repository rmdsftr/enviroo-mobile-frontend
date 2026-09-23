import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'network_status.dart';

/// Jenis kegagalan jaringan, dipakai untuk memutuskan apa yang ditampilkan.
///
/// [offline] satu-satunya yang memicu `NoConnectionScreen` — sisanya cukup
/// pesan biasa di layar masing-masing.
enum ApiFailureKind { offline, timeout, certificate, server, unknown }

/// Mengubah exception mentah jadi kegagalan berjenis + pesan berbahasa manusia.
///
/// Sebelum ada kelas ini, setiap service men-string-kan exception apa adanya:
/// ```dart
/// return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
/// ```
/// yang sampai ke user sebagai `SocketException: Failed host lookup: ...`.
///
/// ⚠️ Kelas ini **berdiri sendiri, bukan bagian dari [ApiClient]**. Itu
/// disengaja: `AuthService` masih memakai `http` mentah untuk 12 panggilan
/// (6 pra-login, `logout`, `refreshToken` — semuanya wajib mentah, lihat
/// komentar kepala `auth_service.dart`), dan kehilangan jaringan **di layar
/// login** justru skenario offline paling utama. Classifier yang berdiri
/// sendiri melayani kedua jalur tanpa perkecualian.
class ApiFailure implements Exception {
  final ApiFailureKind kind;
  final String pesan;

  const ApiFailure(this.kind, this.pesan);

  /// Klasifikasi murni — tanpa efek samping. Pakai ini kalau cuma butuh
  /// jenisnya tanpa ikut melaporkan ke [NetworkStatus].
  static ApiFailureKind klasifikasi(Object e) {
    if (e is ApiFailure) return e.kind;
    // HandshakeException & CertificateException turunan IOException juga,
    // jadi harus dicek sebelum SocketException/IOException.
    if (e is HandshakeException || e is CertificateException) {
      return ApiFailureKind.certificate;
    }
    if (e is SocketException) return ApiFailureKind.offline;
    // ClientException muncul saat koneksi putus di tengah jalan — tetap
    // kegagalan transport, bukan kesalahan server.
    if (e is http.ClientException) return ApiFailureKind.offline;
    if (e is TimeoutException) return ApiFailureKind.timeout;
    // Body bukan JSON yang sah — servernya tercapai, responsnya yang rusak.
    if (e is FormatException) return ApiFailureKind.server;
    return ApiFailureKind.unknown;
  }

  static String pesanUntuk(ApiFailureKind kind) {
    switch (kind) {
      // Sengaja tidak berbunyi "tidak ada koneksi internet": jenis ini juga
      // menampung koneksi yang PUTUS DI TENGAH JALAN padahal internetnya
      // hidup — server menolak lebih dulu lalu menutup soket. Kalimat ini
      // benar untuk dua-duanya. Yang berhak menyatakan "tidak ada internet"
      // cuma NoConnectionScreen, dan itu baru muncul setelah DNS ikut gagal.
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

  /// Klasifikasi **dan** lapor ke [NetworkStatus].
  ///
  /// Ini yang dipanggil dari setiap blok `catch` di services. Pelaporannya
  /// ditaruh di sini — bukan di pemanggil — karena blok `catch` itulah satu-
  /// satunya titik di mana kegagalan request benar-benar teramati, dan
  /// menyebar panggilan lapor ke ~85 tempat justru bikin gampang terlewat.
  factory ApiFailure.from(Object e) {
    final kind = klasifikasi(e);
    NetworkStatus.instance.reportFailure(kind);
    if (e is ApiFailure) return e;
    return ApiFailure(kind, pesanUntuk(kind));
  }

  /// Dikembalikan apa adanya supaya `'$e'` dan `e.toString()` di kode lama
  /// menghasilkan kalimat bersih, bukan `Instance of 'ApiFailure'`.
  ///
  /// Ini juga yang membuat `ProfilProvider._bersihkan()` tetap bekerja tanpa
  /// diubah saat `ProfilService` melempar [ApiFailure] alih-alih `Exception`.
  @override
  String toString() => pesan;
}
