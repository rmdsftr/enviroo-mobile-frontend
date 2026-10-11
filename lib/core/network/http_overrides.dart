import 'dart:io';

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
