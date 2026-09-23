import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_failure.dart';

/// Status konektivitas aplikasi — sumber tunggal untuk `NoConnectionScreen`.
///
/// Singleton karena [ApiFailure.from] dipanggil dari method service yang
/// semuanya `static` dan tidak punya `BuildContext`. Mengikuti idiom
/// `ApiClient` yang juga all-static. Tetap `ChangeNotifier` supaya UI bisa
/// berlangganan lewat Provider seperti biasa.
class NetworkStatus extends ChangeNotifier {
  static final NetworkStatus instance = NetworkStatus._();
  NetworkStatus._();

  bool _offline = false;
  bool get offline => _offline;

  /// Counter monotonik, naik 1 setiap transisi offline → online.
  ///
  /// Layar yang ingin memuat ulang otomatis membandingkan token tersimpan
  /// dengan token sekarang — pola yang sudah dipakai `saldoRefreshToken` di
  /// `DashboardProvider` dan dikonsumsi `BalanceLayouts`. Perbandingan token
  /// penting karena [notifyListeners] juga menyala saat [offline] jadi `true`,
  /// dan itu TIDAK boleh memicu fetch.
  int _recoveryToken = 0;
  int get recoveryToken => _recoveryToken;

  /// Hanya [ApiFailureKind.offline] yang menyalakan status offline. Timeout,
  /// error sertifikat, dan respons rusak berarti servernya tercapai — itu
  /// urusan pesan di layar masing-masing, bukan layar "tidak ada koneksi".
  ///
  /// ⚠️ Laporannya **tidak langsung dipercaya**. [ApiFailure.klasifikasi]
  /// menyimpulkan `offline` dari jenis exception saja, dan itu tidak cukup:
  /// `SocketException`/`ClientException` juga muncul saat server MENJAWAB
  /// tapi memutus koneksi lebih dulu. Contoh nyatanya `previewSetoran` —
  /// request multipart yang ditolak server dengan 400; koneksinya putus saat
  /// body masih dikirim, jadi `ApiClient.reportSuccess()` tidak pernah
  /// tercapai dan 400 yang wajar itu tampil sebagai "tidak ada internet".
  ///
  /// Jadi sebelum layar offline dinyalakan, statusnya dibuktikan dulu lewat
  /// resolusi DNS — ukuran yang sama persis dengan yang dipakai untuk
  /// mendeteksi pemulihan, supaya masuk dan keluar status offline tidak
  /// memakai dua aturan berbeda.
  void reportFailure(ApiFailureKind kind) {
    if (kind != ApiFailureKind.offline) return;

    // Sudah offline: tidak perlu dibuktikan lagi, cukup beri kesempatan
    // layarnya muncul kembali. User bisa saja menutup NoConnectionScreen lewat
    // tombol back, dan listener di main.dart butuh notify ini. Kalau di-guard
    // `if (_offline) return`, layarnya tidak akan pernah balik.
    if (_offline) {
      notifyListeners();
      return;
    }

    _buktikanOffline();
  }

  bool _sedangMembuktikan = false;

  /// Menyalakan status offline hanya kalau DNS ikut gagal. Kalau DNS hidup,
  /// berarti internetnya baik-baik saja dan kegagalan tadi urusan lain —
  /// pesannya sudah ditangani layar masing-masing lewat [ApiFailure.pesan].
  Future<void> _buktikanOffline() async {
    if (_sedangMembuktikan) return;
    _sedangMembuktikan = true;
    try {
      if (await _dnsHidup(const Duration(seconds: 2))) return;
      if (_offline) return; // keburu diset jalur lain
      _offline = true;
      _mulaiProbe();
      notifyListeners();
    } finally {
      _sedangMembuktikan = false;
    }
  }

  /// Dipanggil dari `ApiClient` setiap response diterima — termasuk 4xx/5xx,
  /// karena response apa pun membuktikan servernya tercapai.
  void reportSuccess() {
    if (!_offline) return;
    _offline = false;
    _recoveryToken++;
    _hentikanProbe();
    notifyListeners();
  }

  // ─── Probe pemulihan ───────────────────────────────────────────────────────
  //
  // ⚠️ Tanpa bagian ini, _offline tidak akan pernah padam. Saat user diam di
  // NoConnectionScreen tidak ada request apa pun yang jalan, jadi
  // reportSuccess() tidak punya pemicu dan layarnya menggantung selamanya.
  //
  // Siklus hidupnya diikatkan ke status offline, BUKAN ke NoConnectionScreen.
  // Kalau diikat ke layar, user yang menutup layar itu lewat tombol back akan
  // mematikan probe sementara statusnya masih offline — pemulihan jadi tidak
  // pernah terdeteksi.
  //
  // Probenya sengaja BUKAN HTTP: cuma resolusi DNS lewat dart:io. Tidak butuh
  // token, tidak punya efek samping, tidak perlu endpoint health, dan menguji
  // persis hal yang tadi gagal — "SocketException: Failed host lookup" memang
  // kegagalan resolusi DNS.
  //
  // Lookup berhasil hanya membuktikan internetnya hidup, bukan API-nya sehat.
  // Itu sudah cukup, karena klaim layarnya memang cuma "koneksi terputus".

  static const Duration _jedaProbe = Duration(seconds: 3);
  static final String _host = Uri.parse(ApiConfig.baseUrl).host;

  Timer? _timerProbe;

  void _mulaiProbe() {
    if (_timerProbe != null) return;
    _timerProbe = Timer.periodic(_jedaProbe, (_) => probeSekarang());
  }

  void _hentikanProbe() {
    _timerProbe?.cancel();
    _timerProbe = null;
  }

  /// Sekali coba. Dipakai tombol "Coba Lagi" supaya user tidak perlu menunggu
  /// tick probe berikutnya. Mengembalikan `true` kalau jaringan sudah pulih.
  Future<bool> probeSekarang() async {
    if (!await _dnsHidup(const Duration(seconds: 5))) return false;
    reportSuccess();
    return true;
  }

  /// Satu-satunya pengukur konektivitas di kelas ini — dipakai dua arah:
  /// membuktikan offline sebelum layar dinyalakan, dan mendeteksi pemulihan.
  ///
  /// Timeout-nya diminta pemanggil: saat membuktikan offline, user sedang
  /// menunggu hasil sebuah aksi, jadi jedanya dipendekkan. Saat memantau
  /// pemulihan tidak ada yang menunggu, jadi boleh lebih sabar.
  Future<bool> _dnsHidup(Duration timeout) async {
    try {
      final hasil = await InternetAddress.lookup(_host).timeout(timeout);
      return hasil.isNotEmpty && hasil.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
