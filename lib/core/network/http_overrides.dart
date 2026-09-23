import 'dart:io';

/// Override HTTP global aplikasi.
///
/// Menerima sertifikat yang gagal divalidasi **hanya** untuk host milik
/// Enviroo, sehingga host lain tetap melewati validasi TLS normal.
///
/// Dipasang lewat `HttpOverrides.global` di `main()` sebelum request apa pun
/// keluar. Karena `HttpClient()` merutekan pembuatannya lewat
/// `HttpOverrides.current`, semua jalur jaringan ikut memakai allowlist ini —
/// termasuk [ApiClient] dan `Image.network`/`NetworkImage` ke CDN.
class EnvirooHttpOverrides extends HttpOverrides {
  static const _allowedHosts = {'api.enviroo.tech', 'cdn.enviroo.tech'};

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) =>
              _allowedHosts.contains(host);
  }
}
