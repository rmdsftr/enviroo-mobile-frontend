import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../providers/auth_provider.dart';
import '../../providers/notifikasi_provider.dart';
import 'notif_payload.dart';

/// Callback saat sebuah push membawa data deep-link dan tree sudah siap
/// dinavigasi.
///
/// Push yang datang saat app masih terminated tidak lewat sini: tree belum ada,
/// jadi payload-nya ditahan dan diambil lewat [FcmMessaging.takePendingDeepLink].
typedef NotifDeepLink = void Function(NotifPayload payload);

/// Satu-satunya titik di aplikasi yang menyentuh Firebase Cloud Messaging.
///
/// Menangkap push dari FCM lalu menerjemahkannya jadi dua aksi:
/// 1. memicu [NotifikasiProvider] menarik ulang daftar notifikasi dari backend
///    — push hanya sinyal "ada yang baru", datanya tetap datang dari REST; dan
/// 2. meneruskan data deep-link sebagai [NotifPayload] yang sudah didekode ke
///    [NotifDeepLink], supaya `core/` tidak perlu mengimpor screen apa pun.
///
/// Provider di-inject lewat constructor, bukan lewat `BuildContext`, karena
/// callback FCM bisa berjalan di luar widget tree.
class FcmMessaging {
  FcmMessaging({
    required AuthProvider auth,
    required NotifikasiProvider notif,
    required NotifDeepLink onDeepLink,
    FirebaseMessaging? messaging,
  })  : _auth = auth,
        _notif = notif,
        _onDeepLink = onDeepLink,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final AuthProvider _auth;
  final NotifikasiProvider _notif;
  final NotifDeepLink _onDeepLink;
  final FirebaseMessaging _messaging;

  final List<StreamSubscription<RemoteMessage>> _subs = [];
  StreamSubscription<String>? _tokenSub;
  bool _started = false;

  /// Deep-link dari push yang membuka app saat masih terminated.
  ///
  /// Ditahan di sini karena saat [getInitialMessage] resolve, widget tree belum
  /// ada — navigasinya pasti tertimpa SplashScreen. SplashScreen yang
  /// mengambilnya lewat [takePendingDeepLink] setelah sampai di home.
  NotifPayload? _pendingDeepLink;

  /// Ambil deep-link cold-start yang tertahan, sekaligus mengosongkannya supaya
  /// tidak terpakai dua kali.
  NotifPayload? takePendingDeepLink() {
    final payload = _pendingDeepLink;
    _pendingDeepLink = null;
    return payload;
  }

  /// Pasang seluruh listener FCM.
  ///
  /// Aman dipanggil berulang: pemanggilan kedua diabaikan supaya listener tidak
  /// menumpuk (mis. saat hot restart), yang akan membuat satu push memicu
  /// beberapa kali fetch.
  void start() {
    if (_started) return;
    _started = true;

    // Token refresh — kirim token baru ke backend kapanpun Firebase merotasinya.
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) {
      sendToken(explicitToken: newToken);
    });

    // Foreground: notifikasi masuk saat app aktif di layar.
    _subs.add(FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM] onMessage received: ${msg.notification?.title}');
      refreshNotifikasi();
    }));

    // Background → foreground: user tap notifikasi dari system tray.
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[FCM] onMessageOpenedApp: ${msg.notification?.title}');
      refreshNotifikasi();
      _dispatchDeepLink(msg);
    }));

    // Terminated → foreground: app dibuka dari notifikasi (cold start).
    // Deep-link-nya ditahan, bukan dieksekusi: tree belum ada dan SplashScreen
    // sebentar lagi memanggil pushAndRemoveUntil yang akan menimpa route apa
    // pun yang didorong sekarang.
    _messaging.getInitialMessage().then((msg) {
      // Bisa resolve setelah dispose() — jangan sentuh provider yang sudah mati.
      if (!_started || msg == null) return;
      debugPrint('[FCM] getInitialMessage: ${msg.notification?.title}');
      refreshNotifikasi();
      _pendingDeepLink = NotifPayload.from(msg);
    });
  }

  Future<void> dispose() async {
    _started = false;
    _pendingDeepLink = null;
    await _tokenSub?.cancel();
    _tokenSub = null;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  /// Dipanggil saat app kembali ke foreground.
  Future<void> onAppResumed() async {
    if (!_auth.isLoggedIn) return;
    // Await refresh dulu sebelum fetch notifikasi — tanpa ini, request notifikasi
    // keluar dengan token lama (expired) sebelum refresh selesai → 401.
    await _auth.refreshToken();
    sendToken();
    refreshNotifikasi();
  }

  /// Dipanggil sekali setelah login berhasil, dari layar login mana pun.
  /// [tag] hanya membedakan asal pemanggil di log.
  void onLogin({String tag = 'Auth'}) {
    _notif.fetchNotifikasi(role: _auth.role);

    // Request permission notifikasi (wajib Android 13+). Sengaja tidak di-await:
    // menunggu dialog izin selesai akan menunda navigasi ke home.
    _messaging.requestPermission();

    _registerToken(logTag: tag);
  }

  /// Kirim FCM token milik device ini ke backend.
  Future<void> sendToken({String? explicitToken}) =>
      _registerToken(explicitToken: explicitToken);

  Future<void> _registerToken({String? explicitToken, String? logTag}) async {
    if (!_auth.isLoggedIn) return;
    final fcmToken = explicitToken ?? await _messaging.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      if (logTag != null) {
        debugPrint('[$logTag] FCM token null/kosong, skip register.');
      }
      return;
    }
    if (logTag != null) {
      debugPrint('[$logTag] FCM token diperoleh, mendaftarkan ke backend...');
    }
    _notif.registerFcmToken(fcmToken: fcmToken);
  }

  /// Tarik ulang daftar notifikasi dari backend.
  ///
  /// Retry singkat menangani race saat access token belum selesai dipulihkan
  /// dari secure storage — tanpa ini, fetch pertama setelah cold start bisa
  /// keluar tanpa Authorization dan berakhir 401.
  void refreshNotifikasi({int retryCount = 0}) {
    if (!_auth.isLoggedIn) {
      debugPrint('[Notif] refreshNotifikasi: user belum login, skip.');
      return;
    }
    final token = _auth.currentUser?.accessToken ?? '';
    if (token.isEmpty) {
      if (retryCount < 3) {
        debugPrint(
            '[Notif] refreshNotifikasi: token kosong, retry ke-${retryCount + 1}...');
        Future.delayed(const Duration(milliseconds: 500), () {
          refreshNotifikasi(retryCount: retryCount + 1);
        });
      } else {
        debugPrint(
            '[Notif] refreshNotifikasi: token tetap kosong setelah 3x retry, abort.');
      }
      return;
    }
    debugPrint('[Notif] refreshNotifikasi: fetching untuk role=${_auth.role}');
    _notif.fetchNotifikasi(role: _auth.role);
  }

  void _dispatchDeepLink(RemoteMessage msg) {
    final payload = NotifPayload.from(msg);
    if (payload == null) return;
    _onDeepLink(payload);
  }
}
